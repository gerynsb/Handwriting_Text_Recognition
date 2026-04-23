"""
Flask App Configuration
=======================

Setup paths, constants, dan settings untuk Flask API
"""

import torch
from pathlib import Path


class Config:
    """Application configuration"""
    
    # ========== PATHS ==========
    BASE_DIR = Path(__file__).parent
    
    # Model path (SESUAIKAN DENGAN PATH ANDA)
    MODEL_PATH = Path(
        r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_23_2026_Eksperiment_RNN\exp_architecture_rnn_20260223_042857\best_model.pt"
    )
    
    # Language Model path (Optional)
    LM_PATH = Path(
        r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_25_2026_Advanced_Deslanting++_Final\language_model\char_5gram.json"
    )
    
    # Upload folder
    UPLOAD_FOLDER = BASE_DIR / 'uploads'
    UPLOAD_FOLDER.mkdir(exist_ok=True)
    
    # Logs folder
    LOG_FOLDER = BASE_DIR / 'logs'
    LOG_FOLDER.mkdir(exist_ok=True)
    
    # ========== FLASK CONFIG ==========
    SECRET_KEY = 'your-secret-key-here'
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'jp2'}
    
    # ========== SERVER CONFIG ==========
    HOST = '0.0.0.0'  # Listen on all interfaces
    PORT = 5000
    DEBUG = False
    THREADED = True
    
    # ========== MODEL CONFIG ==========
    DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
    INFERENCE_TIMEOUT = 60  # seconds
    
    # ========== PREPROCESSING CONFIG ==========
    LINE_HEIGHT = 64
    LINE_WIDTH = 512
    
    # ========== DECODE CONFIG ==========
    BEAM_WIDTH = 10
    LM_WEIGHT = 0.1
    LENGTH_BONUS = 0.5
    
    # ========== LOGGING ==========
    LOG_LEVEL = 'INFO'
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False


class ProductionConfig(Config):
    """Production configuration (untuk Ngrok hosting)"""
    DEBUG = False
    TESTING = False
    THREADED = True


class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DEBUG = True


# Select config based on environment
import os
config_name = os.getenv('FLASK_ENV', 'development')

if config_name == 'production':
    app_config = ProductionConfig
elif config_name == 'testing':
    app_config = TestingConfig
else:
    app_config = DevelopmentConfig
