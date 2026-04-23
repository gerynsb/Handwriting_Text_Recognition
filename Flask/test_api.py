"""
Test Script untuk Flask HTR API
================================

Bisa di-run untuk test endpoints sebelum integrate dengan Flutter

Usage:
    python test_api.py
"""

import requests
import json
from pathlib import Path
import base64
from PIL import Image
import numpy as np
import cv2


class HTTPRTester:
    """Tester untuk Flask HTR API"""
    
    def __init__(self, base_url='http://localhost:5000'):
        self.base_url = base_url
        self.session = requests.Session()
    
    def test_health(self):
        """Test health endpoint"""
        print("\n" + "="*60)
        print("[TEST 1] Health Check")
        print("="*60)
        
        try:
            response = self.session.get(f'{self.base_url}/api/health')
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
            return response.status_code == 200
        except Exception as e:
            print(f"ERROR: {e}")
            return False
    
    def test_model_info(self):
        """Test model info endpoint"""
        print("\n" + "="*60)
        print("[TEST 2] Model Info")
        print("="*60)
        
        try:
            response = self.session.get(f'{self.base_url}/api/model/info')
            print(f"Status Code: {response.status_code}")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
            return response.status_code == 200
        except Exception as e:
            print(f"ERROR: {e}")
            return False
    
    def test_recognize_line_with_file(self, image_path):
        """Test line recognition dengan file upload"""
        print("\n" + "="*60)
        print(f"[TEST 3] Line Recognition (File Upload)")
        print(f"Image: {image_path}")
        print("="*60)
        
        try:
            if not Path(image_path).exists():
                print(f"ERROR: File not found: {image_path}")
                return False
            
            with open(image_path, 'rb') as f:
                files = {'file': f}
                data = {'use_beam_search': True}
                response = self.session.post(
                    f'{self.base_url}/api/recognize/line',
                    files=files,
                    data=data
                )
            
            print(f"Status Code: {response.status_code}")
            result = response.json()
            print(f"Response: {json.dumps(result, indent=2)}")
            
            if result.get('success'):
                print(f"\n✅ Recognized Text: {result['text']}")
                print(f"   Processing Time: {result['processing_time_ms']:.2f} ms")
            
            return response.status_code == 200
        except Exception as e:
            print(f"ERROR: {e}")
            return False
    
    def test_recognize_line_with_base64(self, image_path):
        """Test line recognition dengan base64"""
        print("\n" + "="*60)
        print(f"[TEST 4] Line Recognition (Base64)")
        print(f"Image: {image_path}")
        print("="*60)
        
        try:
            if not Path(image_path).exists():
                print(f"ERROR: File not found: {image_path}")
                return False
            
            # Load image and convert to base64
            with Image.open(image_path).convert('L') as img:
                buffer = io.BytesIO()
                img.save(buffer, format='PNG')
                img_base64 = base64.b64encode(buffer.getvalue()).decode()
            
            payload = {
                'image_base64': img_base64,
                'use_beam_search': True
            }
            
            response = self.session.post(
                f'{self.base_url}/api/recognize/line',
                json=payload
            )
            
            print(f"Status Code: {response.status_code}")
            result = response.json()
            print(f"Response: {json.dumps(result, indent=2)}")
            
            if result.get('success'):
                print(f"\n✅ Recognized Text: {result['text']}")
            
            return response.status_code == 200
        except Exception as e:
            print(f"ERROR: {e}")
            return False
    
    def test_recognize_paragraph(self, image_path):
        """Test paragraph recognition"""
        print("\n" + "="*60)
        print(f"[TEST 5] Paragraph Recognition")
        print(f"Image: {image_path}")
        print("="*60)
        
        try:
            if not Path(image_path).exists():
                print(f"ERROR: File not found: {image_path}")
                return False
            
            with open(image_path, 'rb') as f:
                files = {'file': f}
                data = {
                    'segmentation_method': 'projection',
                    'use_beam_search': True,
                    'crop_mode': None
                }
                response = self.session.post(
                    f'{self.base_url}/api/recognize/paragraph',
                    files=files,
                    data=data
                )
            
            print(f"Status Code: {response.status_code}")
            result = response.json()
            print(f"Response: {json.dumps(result, indent=2)}")
            
            if result.get('success'):
                print(f"\n✅ Full Text:\n{result['text']}")
                print(f"   Lines Detected: {result['line_count']}")
                print(f"   Processing Time: {result['processing_time_ms']:.2f} ms")
            
            return response.status_code == 200
        except Exception as e:
            print(f"ERROR: {e}")
            return False
    
    def test_preprocess(self, image_path):
        """Test preprocessing debug"""
        print("\n" + "="*60)
        print(f"[TEST 6] Image Preprocessing")
        print(f"Image: {image_path}")
        print("="*60)
        
        try:
            if not Path(image_path).exists():
                print(f"ERROR: File not found: {image_path}")
                return False
            
            with open(image_path, 'rb') as f:
                files = {'file': f}
                response = self.session.post(
                    f'{self.base_url}/api/preprocess',
                    files=files
                )
            
            print(f"Status Code: {response.status_code}")
            result = response.json()
            
            # Don't print full base64
            if 'image_preview' in result:
                preview = result.pop('image_preview')
                result['image_preview'] = f"[{len(preview)} chars, base64]"
            
            print(f"Response: {json.dumps(result, indent=2)}")
            
            if result.get('success'):
                print(f"\n✅ Original Size: {result['original_size']}")
                print(f"   Processed Size: {result['processed_size']}")
            
            return response.status_code == 200
        except Exception as e:
            print(f"ERROR: {e}")
            return False
    
    def run_all_tests(self, line_image_path=None, paragraph_image_path=None):
        """Run all tests"""
        print("\n")
        print("╔" + "="*58 + "╗")
        print("║" + " "*10 + "Flask HTR API Test Suite" + " "*24 + "║")
        print("╚" + "="*58 + "╝")
        
        results = {}
        
        # Basic tests
        results['health'] = self.test_health()
        results['model_info'] = self.test_model_info()
        
        # Line recognition tests
        if line_image_path:
            results['line_file'] = self.test_recognize_line_with_file(line_image_path)
            results['line_base64'] = self.test_recognize_line_with_base64(line_image_path)
            results['preprocess'] = self.test_preprocess(line_image_path)
        else:
            print("\n⚠️ No line image provided, skipping line recognition tests")
        
        # Paragraph recognition test
        if paragraph_image_path:
            results['paragraph'] = self.test_recognize_paragraph(paragraph_image_path)
        else:
            print("\n⚠️ No paragraph image provided, skipping paragraph test")
        
        # Summary
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)
        passed = sum(1 for v in results.values() if v)
        total = len(results)
        print(f"Passed: {passed}/{total}")
        
        for test_name, passed_flag in results.items():
            status = "✅ PASS" if passed_flag else "❌ FAIL"
            print(f"  {status} - {test_name}")


if __name__ == '__main__':
    import io
    
    # Configure API URL
    API_URL = 'http://localhost:5000'
    
    # Configure image paths (update these)
    LINE_IMAGE = r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_26_2026_Testing_data\Teklia_Line_Dataset\Gambar 1.jpg"
    PARAGRAPH_IMAGE = r"D:\Dokumen Kuliah\TA\Kode Kaggle\Experiment\2_26_2026_Testing_data\Kaggle_IAM_Form\Gambar6.png"
    
    # Run tests
    tester = HTTPRTester(base_url=API_URL)
    tester.run_all_tests(
        line_image_path=LINE_IMAGE,
        paragraph_image_path=PARAGRAPH_IMAGE
    )
    
    print("\n✅ Test complete!")
