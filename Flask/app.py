"""
Flask API untuk HTR (Handwritten Text Recognition)
=====================================================
Backend untuk aplikasi mobile Flutter

Features:
- Line-level text recognition
- Paragraph-level recognition dengan segmentasi
- Image preprocessing
- Model inference dengan Beam Search + LM

Usage:
    python app.py
    
API akan tersedia di http://localhost:5000
Untuk expose ke public: ngrok http 5000
"""

import os
import json
import base64
import logging
from io import BytesIO
from pathlib import Path
from datetime import datetime

import numpy as np
import cv2
from PIL import Image
import torch

from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename

from model_loader import ModelLoader, InferenceEngine
from config import Config

# ============================================
# SETUP LOGGING
# ============================================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================
# FLASK APP INITIALIZATION
# ============================================
app = Flask(__name__)
app.config.from_object(Config)

# Enable CORS for Flutter app
CORS(app, resources={r"/api/*": {"origins": "*"}})

# ============================================
# GLOBAL VARIABLES
# ============================================
model_loader = None
inference_engine = None
startup_initialized = False

# ============================================
# UTILITY FUNCTIONS
# ============================================

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in Config.ALLOWED_EXTENSIONS


def image_to_base64(image_array):
    """Convert numpy image array to base64 string"""
    try:
        # Ensure image is uint8
        if image_array.dtype != np.uint8:
            # Normalize to 0-255
            if image_array.max() <= 1:
                image_array = (image_array * 255).astype(np.uint8)
            else:
                image_array = image_array.astype(np.uint8)
        
        # Convert to PIL and then to base64
        pil_img = Image.fromarray(image_array, mode='L')
        buffer = BytesIO()
        pil_img.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        return img_str
    except Exception as e:
        logger.error(f"Error converting image to base64: {e}")
        return None


def load_image_from_request(request_data):
    """Load image from request (file upload or base64)"""
    try:
        # Check for file upload
        if 'file' in request.files:
            file = request.files['file']
            if file.filename == '':
                return None, "No file selected"
            if not allowed_file(file.filename):
                return None, f"File type not allowed. Allowed: {Config.ALLOWED_EXTENSIONS}"
            
            img = Image.open(file.stream).convert('L')
            return np.array(img), None
        
        # Check for base64 in JSON
        elif 'image_base64' in request_data:
            img_data = request_data['image_base64']
            img_bytes = base64.b64decode(img_data)
            img = Image.open(BytesIO(img_bytes)).convert('L')
            return np.array(img), None
        
        else:
            return None, "No image provided. Send 'file' or 'image_base64'"
    
    except Exception as e:
        logger.error(f"Error loading image: {e}")
        return None, str(e)

# ============================================
# API ROUTES
# ============================================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        model_status = "ready" if inference_engine is not None else "not loaded"
        return jsonify({
            'status': 'ok',
            'timestamp': datetime.now().isoformat(),
            'model': model_status,
            'version': '1.0.0'
        }), 200
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500


@app.route('/api/model/info', methods=['GET'])
def model_info():
    """Get model information"""
    try:
        if inference_engine is None:
            return jsonify({'error': 'Model not loaded'}), 503
        
        info = {
            'model_name': 'CRNN BiLSTM 2x256',
            'num_classes': 80,
            'input_size': (64, 512),
            'decoder_type': 'Beam Search',
            'beam_width': 10,
            'has_language_model': inference_engine.has_lm,
            'device': str(inference_engine.device)
        }
        return jsonify(info), 200
    except Exception as e:
        logger.error(f"Model info error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/recognize/line', methods=['POST'])
def recognize_line():
    """
    Recognize text from a line image
    
    Request:
        - file: image file (multipart/form-data)
        - OR image_base64: base64 encoded image (application/json)
        - use_beam_search: bool (optional, default: true)
    
    Response:
        - text: recognized text
        - confidence: confidence score (if available)
        - processing_time: time taken
    """
    try:
        if inference_engine is None:
            return jsonify({'error': 'Model not loaded'}), 503
        
        # Get parameters
        request_data = request.get_json() if request.is_json else request.form
        use_beam_search = request_data.get('use_beam_search', True)
        
        # Load image
        img, error = load_image_from_request(request_data)
        if error:
            return jsonify({'error': error}), 400
        
        if img is None:
            return jsonify({'error': 'Failed to load image'}), 400
        
        # Recognize
        logger.info("Starting line recognition...")
        result = inference_engine.recognize_line(
            img,
            use_beam_search=use_beam_search
        )
        
        response = {
            'success': True,
            'text': result['text'],
            'confidence': result.get('confidence', None),
            'processing_time_ms': result.get('time_ms', None),
            'method': 'beam_search' if use_beam_search else 'greedy'
        }
        
        logger.info(f"Recognition result: {result['text']}")
        return jsonify(response), 200
    
    except Exception as e:
        logger.error(f"Line recognition error: {e}")
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/recognize/paragraph', methods=['POST'])
def recognize_paragraph():
    """
    Recognize text from paragraph/form image
    
    Request:
        - file: image file (multipart/form-data)
        - OR image_base64: base64 encoded image (application/json)
        - segmentation_method: 'projection' or 'contours' (optional)
        - use_beam_search: bool (optional, default: true)
        - crop_mode: 'auto' or 'manual' or null (optional)
    
    Response:
        - text: recognized full text (lines separated by \\n)
        - lines: array of recognized text per line
        - line_count: number of lines detected
        - processing_time: time taken
    """
    try:
        if inference_engine is None:
            return jsonify({'error': 'Model not loaded'}), 503
        
        # Get parameters
        request_data = request.get_json() if request.is_json else request.form
        segmentation_method = request_data.get('segmentation_method', 'projection')
        use_beam_search = request_data.get('use_beam_search', True)
        crop_mode = request_data.get('crop_mode', None)
        
        # Load image
        img, error = load_image_from_request(request_data)
        if error:
            return jsonify({'error': error}), 400
        
        if img is None:
            return jsonify({'error': 'Failed to load image'}), 400
        
        # Recognize
        logger.info("Starting paragraph recognition...")
        result = inference_engine.recognize_paragraph(
            img,
            segmentation_method=segmentation_method,
            use_beam_search=use_beam_search,
            crop_mode=crop_mode
        )
        
        response = {
            'success': True,
            'text': result['text'],
            'lines': result['lines'],
            'line_count': result['line_count'],
            'processing_time_ms': result.get('time_ms', None),
            'segmentation_method': segmentation_method,
            'method': 'beam_search' if use_beam_search else 'greedy'
        }
        
        logger.info(f"Recognition complete: {result['line_count']} lines detected")
        return jsonify(response), 200
    
    except Exception as e:
        logger.error(f"Paragraph recognition error: {e}")
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/preprocess', methods=['POST'])
def preprocess_image():
    """
    Preprocess image and return statistics
    
    Useful for debugging preprocessing pipeline
    
    Response:
        - original_size: (height, width)
        - processed_size: (height, width) after preprocessing
        - image_preview: base64 encoded preview
    """
    try:
        # Load image
        request_data = request.get_json() if request.is_json else request.form
        img, error = load_image_from_request(request_data)
        if error:
            return jsonify({'error': error}), 400
        
        if img is None:
            return jsonify({'error': 'Failed to load image'}), 400
        
        original_size = img.shape
        
        # Preprocess
        processed = inference_engine.preprocess_line_image(img)
        processed_array = processed.squeeze().numpy()
        processed_size = processed_array.shape
        
        # Get preview
        preview_b64 = image_to_base64((processed_array * 255).astype(np.uint8))
        
        response = {
            'success': True,
            'original_size': {'height': original_size[0], 'width': original_size[1]},
            'processed_size': {'height': processed_size[0], 'width': processed_size[1]},
            'image_preview': preview_b64
        }
        
        return jsonify(response), 200
    
    except Exception as e:
        logger.error(f"Preprocess error: {e}")
        return jsonify({'error': str(e), 'success': False}), 500


# ============================================
# ERROR HANDLERS
# ============================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({'error': 'Internal server error'}), 500


# ============================================
# STARTUP
# ============================================

def initialize_model():
    """Initialize model on app startup"""
    global model_loader, inference_engine
    
    try:
        logger.info("Initializing model loader...")
        model_loader = ModelLoader(Config.MODEL_PATH, Config.LM_PATH)
        
        logger.info("Loading model...")
        model, encoder, lm = model_loader.load()
        
        logger.info("Creating inference engine...")
        inference_engine = InferenceEngine(model, encoder, lm, Config.DEVICE)
        
        logger.info("✅ Model loaded successfully!")
        logger.info(f"   Device: {Config.DEVICE}")
        logger.info(f"   Classes: {encoder.num_classes}")
        logger.info(f"   LM: {'Available' if lm else 'Not available'}")
        
    except Exception as e:
        logger.error(f"❌ Failed to initialize model: {e}")
        logger.error("App will continue but /api/recognize endpoints will return error")
        raise


@app.before_request
def startup():
    """Run once before serving requests (Flask 3 compatible)."""
    global startup_initialized
    if not startup_initialized and inference_engine is None:
        initialize_model()
    startup_initialized = True


# ============================================
# MAIN
# ============================================

if __name__ == '__main__':
    logger.info("Starting Flask HTR API...")
    logger.info(f"Model path: {Config.MODEL_PATH}")
    logger.info(f"LM path: {Config.LM_PATH}")
    
    # Initialize model
    initialize_model()
    
    # Start app
    is_debug = os.getenv('FLASK_DEBUG', False)
    app.run(
        host='0.0.0.0',
        port=Config.PORT,
        debug=is_debug,
        threaded=True
    )
