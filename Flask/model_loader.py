"""
Model Loader dan Inference Engine untuk HTR
=============================================

Handles:
- Model loading from checkpoint
- Language model loading
- Image preprocessing
- Inference (Beam Search + LM)
"""

import math
import time
import logging
import json
from pathlib import Path
from typing import Tuple, Optional, Dict, Any

import numpy as np
import cv2
import torch
import torch.nn as nn
import torch.nn.functional as F
from PIL import Image

logger = logging.getLogger(__name__)


# ============================================
# MODEL ARCHITECTURE
# ============================================

class CNNBackbone(nn.Module):
    """CNN Feature Extractor"""
    
    def __init__(self, input_channels=1, output_channels=512):
        super().__init__()
        self.output_channels = output_channels
        self.cnn = nn.Sequential(
            nn.Conv2d(input_channels, 64, 3, padding=1), nn.BatchNorm2d(64), nn.ReLU(inplace=True),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(64, 128, 3, padding=1), nn.BatchNorm2d(128), nn.ReLU(inplace=True),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(128, 256, 3, padding=1), nn.BatchNorm2d(256), nn.ReLU(inplace=True),
            nn.Conv2d(256, 256, 3, padding=1), nn.BatchNorm2d(256), nn.ReLU(inplace=True),
            nn.MaxPool2d((2, 1), (2, 1)),
            nn.Conv2d(256, 512, 3, padding=1), nn.BatchNorm2d(512), nn.ReLU(inplace=True),
            nn.Conv2d(512, 512, 3, padding=1), nn.BatchNorm2d(512), nn.ReLU(inplace=True),
            nn.MaxPool2d((2, 1), (2, 1)),
            nn.Conv2d(512, output_channels, 3, padding=1), nn.BatchNorm2d(output_channels), nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d((1, None)),
        )
    
    def forward(self, x):
        conv = self.cnn(x)
        conv = conv.squeeze(2)
        conv = conv.permute(0, 2, 1)
        return conv


class CRNN(nn.Module):
    """CRNN with BiLSTM"""
    
    def __init__(self, num_classes, cnn_output_channels=512, rnn_hidden_size=256,
                 rnn_num_layers=2, rnn_dropout=0.3, rnn_type="LSTM", bidirectional=True):
        super().__init__()
        self.num_classes = num_classes
        self.cnn = CNNBackbone(1, cnn_output_channels)
        
        RNNClass = nn.LSTM if rnn_type == "LSTM" else nn.GRU
        self.rnn = RNNClass(
            cnn_output_channels, rnn_hidden_size, rnn_num_layers,
            batch_first=True,
            dropout=rnn_dropout if rnn_num_layers > 1 else 0,
            bidirectional=bidirectional
        )
        
        rnn_output_size = rnn_hidden_size * (2 if bidirectional else 1)
        self.fc = nn.Linear(rnn_output_size, num_classes)
    
    def forward(self, x):
        conv = self.cnn(x)
        rnn_out, _ = self.rnn(conv)
        output = self.fc(rnn_out)
        output = output.permute(1, 0, 2)
        return F.log_softmax(output, dim=2)


# ============================================
# CHARACTER ENCODER
# ============================================

class CharacterEncoder:
    """Character-level encoder/decoder"""
    
    IAM_CHARSET = [
        ' ', '!', '\"', '#', '&', "'", '(', ')', '*', '+', ',', '-', '.', '/',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        ':', ';', '?',
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
        'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
        'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    ]
    
    def __init__(self, chars=None):
        if chars is None:
            self.chars = self.IAM_CHARSET
        else:
            self.chars = sorted(list(chars))
        self.char_to_idx = {c: i + 1 for i, c in enumerate(self.chars)}
        self.idx_to_char = {i + 1: c for i, c in enumerate(self.chars)}
        self.blank_idx = 0
        self.num_classes = len(self.chars) + 1
    
    def encode(self, text):
        return [self.char_to_idx.get(c, self.blank_idx) for c in text]
    
    def decode(self, indices):
        return ''.join([self.idx_to_char.get(i, '') for i in indices if i != self.blank_idx])


# ============================================
# LANGUAGE MODEL
# ============================================

class SimpleNgramLM:
    """Simple n-gram character-level LM"""
    
    def __init__(self, n: int = 5):
        self.n = n
        self.ngrams = {}
        self.total_count = 0
        self.log_probs = {}
    
    def score(self, text: str) -> float:
        """Score text using n-gram LM"""
        text = ' ' * (self.n - 1) + text + ' '
        score = 0.0
        for i in range(len(text) - self.n + 1):
            ngram = text[i:i + self.n]
            score += self.log_probs.get(ngram, -20.0)
        return score
    
    @classmethod
    def load(cls, path):
        """Load LM from JSON file"""
        with open(path, 'r') as f:
            data = json.load(f)
        lm = cls(n=data['n'])
        lm.ngrams = data['ngrams']
        lm.total_count = sum(lm.ngrams.values())
        lm.log_probs = {k: math.log(v / lm.total_count) for k, v in lm.ngrams.items()}
        return lm


# ============================================
# BEAM SEARCH DECODER
# ============================================

class BeamSearchDecoder:
    """Beam Search CTC Decoder with LM rescoring"""
    
    def __init__(self, encoder, lm=None, beam_width=10, lm_weight=0.1, length_bonus=0.5):
        self.encoder = encoder
        self.lm = lm
        self.beam_width = beam_width
        self.lm_weight = lm_weight
        self.length_bonus = length_bonus
        self.blank_id = encoder.blank_idx
    
    def decode(self, log_probs):
        """Decode using beam search"""
        T, num_classes = log_probs.shape
        beams = [('', 0.0, -1)]
        
        for t in range(T):
            new_beams = {}
            for prefix, score, last_char in beams:
                for c in range(num_classes):
                    new_score = score + log_probs[t, c]
                    if c == self.blank_id:
                        key = (prefix, -1)
                    elif c == last_char:
                        key = (prefix, c)
                    else:
                        new_char = self.encoder.idx_to_char.get(c, '')
                        new_prefix = prefix + new_char
                        key = (new_prefix, c)
                    
                    if c == self.blank_id or c == last_char:
                        if key not in new_beams or new_beams[key][0] < new_score:
                            new_beams[key] = (new_score, prefix, -1 if c == self.blank_id else c)
                    else:
                        new_char = self.encoder.idx_to_char.get(c, '')
                        new_prefix = prefix + new_char
                        if key not in new_beams or new_beams[key][0] < new_score:
                            new_beams[key] = (new_score, new_prefix, c)
            
            sorted_beams = sorted(new_beams.values(), key=lambda x: x[0], reverse=True)
            beams = [(text, score, last) for score, text, last in sorted_beams[:self.beam_width]]
        
        if self.lm is not None and len(beams) > 0:
            rescored_beams = []
            for prefix, ctc_score, _ in beams:
                if len(prefix) > 0:
                    lm_score = self.lm.score(prefix) / max(len(prefix), 1)
                    length_bonus = self.length_bonus * len(prefix)
                    final_score = ctc_score + self.lm_weight * lm_score + length_bonus
                else:
                    final_score = ctc_score
                rescored_beams.append((final_score, prefix))
            rescored_beams.sort(key=lambda x: x[0], reverse=True)
            return rescored_beams[0][1] if rescored_beams else ''
        
        return beams[0][0] if beams else ''


# ============================================
# MODEL LOADER
# ============================================

class ModelLoader:
    """Load pretrained model and LM"""
    
    def __init__(self, model_path: str, lm_path: Optional[str] = None):
        self.model_path = Path(model_path)
        self.lm_path = Path(lm_path) if lm_path else None
    
    def load(self) -> Tuple[nn.Module, CharacterEncoder, Optional[SimpleNgramLM]]:
        """Load model, encoder, and LM"""
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        
        # Create encoder
        logger.info("Creating character encoder...")
        encoder = CharacterEncoder()
        
        # Load model
        logger.info(f"Loading model from {self.model_path}...")
        model = CRNN(
            num_classes=encoder.num_classes,
            rnn_type="LSTM",
            rnn_hidden_size=256,
            rnn_num_layers=2
        ).to(device)
        
        checkpoint = torch.load(self.model_path, map_location=device)
        model.load_state_dict(checkpoint['model_state_dict'])
        model.eval()
        logger.info("✅ Model loaded")
        
        # Load LM
        lm = None
        if self.lm_path and self.lm_path.exists():
            logger.info(f"Loading LM from {self.lm_path}...")
            try:
                lm = SimpleNgramLM.load(self.lm_path)
                logger.info("✅ LM loaded")
            except Exception as e:
                logger.warning(f"Failed to load LM: {e}")
        else:
            logger.warning("LM not found, using greedy decoding only")
        
        return model, encoder, lm


# ============================================
# INFERENCE ENGINE
# ============================================

class InferenceEngine:
    """Handle inference and preprocessing"""
    
    def __init__(self, model: nn.Module, encoder: CharacterEncoder,
                 lm: Optional[SimpleNgramLM], device: str = 'cpu'):
        self.model = model
        self.encoder = encoder
        self.lm = lm
        self.device = device
        self.has_lm = lm is not None
        
        # Create decoders
        self.beam_decoder = BeamSearchDecoder(encoder, lm=lm, beam_width=10, lm_weight=0.1)
    
    def preprocess_line_image(self, img, target_height=64, target_width=512):
        """Preprocess line image"""
        # Convert to numpy if PIL
        if isinstance(img, Image.Image):
            img = np.array(img)
        
        # Convert to grayscale if needed
        if len(img.shape) == 3:
            img = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        
        # Resize maintaining aspect ratio
        h, w = img.shape[:2]
        new_w = int(w * target_height / h)
        new_w = min(new_w, target_width)
        
        img = cv2.resize(img, (new_w, target_height), interpolation=cv2.INTER_LINEAR)
        
        # Pad to target width
        if new_w < target_width:
            padded = np.ones((target_height, target_width), dtype=np.uint8) * 255
            padded[:, :new_w] = img
            img = padded
        
        # Normalize and convert to tensor
        img = img.astype(np.float32) / 255.0
        img_tensor = torch.FloatTensor(img).unsqueeze(0).unsqueeze(0)  # (1, 1, H, W)
        
        return img_tensor
    
    def greedy_decode(self, log_probs):
        """Greedy CTC decoding"""
        pred_indices = log_probs.argmax(axis=1)
        decoded = []
        prev = -1
        for idx in pred_indices:
            if idx != self.encoder.blank_idx and idx != prev:
                decoded.append(idx)
            prev = idx
        return self.encoder.decode(decoded)
    
    def recognize_line(self, img, use_beam_search=True) -> Dict[str, Any]:
        """Recognize text from line image"""
        start_time = time.time()
        
        try:
            # Preprocess
            img_tensor = self.preprocess_line_image(img).to(self.device)
            
            # Inference
            self.model.eval()
            with torch.no_grad():
                log_probs = self.model(img_tensor)  # (T, 1, C)
                log_probs = log_probs.squeeze(1).cpu().numpy()  # (T, C)
            
            # Decode
            if use_beam_search and self.has_lm:
                text = self.beam_decoder.decode(log_probs)
            else:
                text = self.greedy_decode(log_probs)
            
            processing_time = (time.time() - start_time) * 1000  # Convert to ms
            
            return {
                'text': text,
                'confidence': None,
                'time_ms': processing_time,
                'success': True
            }
        
        except Exception as e:
            logger.error(f"Recognition error: {e}")
            return {
                'text': '',
                'confidence': None,
                'time_ms': None,
                'success': False,
                'error': str(e)
            }
    
    def segment_lines_projection(self, img, min_line_height=20, min_gap=5):
        """Segment lines using horizontal projection"""
        if len(img.shape) == 3:
            img = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        
        _, binary = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        
        # Horizontal projection
        projection = np.sum(binary, axis=1)
        
        # Find line boundaries
        lines = []
        in_line = False
        start = 0
        threshold = np.max(projection) * 0.02
        
        for i, val in enumerate(projection):
            if val > threshold and not in_line:
                in_line = True
                start = i
            elif val <= threshold and in_line:
                in_line = False
                if i - start >= min_line_height:
                    lines.append((start, i))
        
        if in_line and len(projection) - start >= min_line_height:
            lines.append((start, len(projection)))
        
        # Merge close lines
        merged = []
        for line in lines:
            if merged and line[0] - merged[-1][1] < min_gap:
                merged[-1] = (merged[-1][0], line[1])
            else:
                merged.append(line)
        
        return merged
    
    def recognize_paragraph(self, img, segmentation_method='projection',
                           use_beam_search=True, crop_mode=None) -> Dict[str, Any]:
        """Recognize text from paragraph image"""
        start_time = time.time()
        
        try:
            # Convert to numpy
            if isinstance(img, Image.Image):
                img = np.array(img)
            if len(img.shape) == 3:
                img = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
            
            # Segment lines
            lines = self.segment_lines_projection(img)
            
            # Recognize each line
            results = []
            for line in lines:
                y1, y2 = line
                line_img = img[y1:y2, :]
                
                if line_img.shape[0] < 10 or line_img.shape[1] < 20:
                    continue
                
                result = self.recognize_line(line_img, use_beam_search)
                if result['text']:
                    results.append(result['text'])
            
            # Combine
            full_text = '\n'.join(results)
            processing_time = (time.time() - start_time) * 1000
            
            return {
                'text': full_text,
                'lines': results,
                'line_count': len(results),
                'time_ms': processing_time,
                'success': True
            }
        
        except Exception as e:
            logger.error(f"Paragraph recognition error: {e}")
            return {
                'text': '',
                'lines': [],
                'line_count': 0,
                'time_ms': None,
                'success': False,
                'error': str(e)
            }
