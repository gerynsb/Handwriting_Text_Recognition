# Flask HTR API - Code Examples

Contoh integrasi API dari berbagai platform dan bahasa pemrograman.

---

## 📱 Flutter / Dart

### Basic Usage

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class HTRService {
  final String baseUrl = 'https://api-url.ngrok.io'; // Update with your URL
  
  // Check API health
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }
  
  // Get model info
  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/model/info'),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get model info');
      }
    } catch (e) {
      throw Exception('Model info error: $e');
    }
  }
  
  // Recognize single line
  Future<String> recognizeLine(XFile image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/recognize/line'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );
      request.fields['use_beam_search'] = 'true';
      
      final response = await request.send()
          .timeout(Duration(seconds: 30));
      
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      
      if (response.statusCode == 200 && jsonResponse['success']) {
        return jsonResponse['text'];
      } else {
        throw Exception(
          jsonResponse['error'] ?? 'Recognition failed'
        );
      }
    } catch (e) {
      throw Exception('Line recognition error: $e');
    }
  }
  
  // Recognize paragraph (multiple lines)
  Future<List<String>> recognizeParagraph(XFile image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/recognize/paragraph'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );
      request.fields['segmentation_method'] = 'projection';
      request.fields['use_beam_search'] = 'true';
      
      final response = await request.send()
          .timeout(Duration(seconds: 60));
      
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      
      if (response.statusCode == 200 && jsonResponse['success']) {
        return List<String>.from(jsonResponse['lines']);
      } else {
        throw Exception(
          jsonResponse['error'] ?? 'Recognition failed'
        );
      }
    } catch (e) {
      throw Exception('Paragraph recognition error: $e');
    }
  }
  
  // Get preprocessing preview
  Future<String> getPreprocessingPreview(XFile image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/preprocess'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );
      
      final response = await request.send()
          .timeout(Duration(seconds: 10));
      
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      
      if (response.statusCode == 200) {
        return jsonResponse['image_base64'];
      } else {
        throw Exception('Preprocessing failed');
      }
    } catch (e) {
      throw Exception('Preprocessing error: $e');
    }
  }
}
```

### Flutter UI Widget

```dart
import 'package:flutter/material.dart';

class HTRScreen extends StatefulWidget {
  @override
  State<HTRScreen> createState() => _HTRScreenState();
}

class _HTRScreenState extends State<HTRScreen> {
  final htrService = HTRService();
  final picker = ImagePicker();
  
  String recognizedText = '';
  List<String> paragraphLines = [];
  bool isLoading = false;
  String selectedMode = 'line'; // 'line' or 'paragraph'
  
  Future<void> pickAndRecognize() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    setState(() => isLoading = true);
    
    try {
      if (selectedMode == 'line') {
        final text = await htrService.recognizeLine(image);
        setState(() {
          recognizedText = text;
          paragraphLines = [];
        });
        
        showSuccessSnackBar('Text recognized successfully!');
      } else {
        final lines = await htrService.recognizeParagraph(image);
        setState(() {
          paragraphLines = lines;
          recognizedText = lines.join('\n');
        });
        
        showSuccessSnackBar('Paragraph recognized (${lines.length} lines)!');
      }
    } catch (e) {
      showErrorSnackBar('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Handwriting Text Recognition'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Selection
              Text('Recognition Mode', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Single Line'),
                      value: 'line',
                      groupValue: selectedMode,
                      onChanged: (val) {
                        setState(() => selectedMode = val!);
                        recognizedText = '';
                        paragraphLines = [];
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Paragraph'),
                      value: 'paragraph',
                      groupValue: selectedMode,
                      onChanged: (val) {
                        setState(() => selectedMode = val!);
                        recognizedText = '';
                        paragraphLines = [];
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Button
              Center(
                child: Column(
                  children: [
                    if (isLoading)
                      Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing...'),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: pickAndRecognize,
                        icon: Icon(Icons.image),
                        label: Text('Pick Image'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Results
              if (selectedMode == 'line' && recognizedText.isNotEmpty) ...[
                Text('Recognized Text', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(recognizedText),
                ),
              ] else if (selectedMode == 'paragraph' && paragraphLines.isNotEmpty) ...[
                Text('Recognized Lines', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: paragraphLines.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Line ${index + 1}:', 
                              style: TextStyle(fontWeight: FontWeight.bold)),
                            SelectableText(paragraphLines[index]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🌐 JavaScript / Node.js

### Node.js Backend

```javascript
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

class HTRClient {
  constructor(baseUrl) {
    this.baseUrl = baseUrl;
    this.client = axios.create({
      baseURL: baseUrl,
      timeout: 30000,
      headers: {
        'User-Agent': 'HTR-Client/1.0'
      }
    });
  }
  
  async healthCheck() {
    try {
      const response = await this.client.get('/api/health');
      return response.data;
    } catch (error) {
      throw new Error(`Health check failed: ${error.message}`);
    }
  }
  
  async getModelInfo() {
    try {
      const response = await this.client.get('/api/model/info');
      return response.data;
    } catch (error) {
      throw new Error(`Failed to get model info: ${error.message}`);
    }
  }
  
  async recognizeLine(imagePath, useBeamSearch = true) {
    try {
      const form = new FormData();
      form.append('file', fs.createReadStream(imagePath));
      form.append('use_beam_search', useBeamSearch.toString());
      
      const response = await this.client.post('/api/recognize/line', form, {
        headers: form.getHeaders(),
      });
      
      if (response.data.success) {
        return response.data.text;
      } else {
        throw new Error(response.data.error || 'Recognition failed');
      }
    } catch (error) {
      throw new Error(`Line recognition failed: ${error.message}`);
    }
  }
  
  async recognizeParagraph(imagePath, segmentationMethod = 'projection', useBeamSearch = true) {
    try {
      const form = new FormData();
      form.append('file', fs.createReadStream(imagePath));
      form.append('segmentation_method', segmentationMethod);
      form.append('use_beam_search', useBeamSearch.toString());
      
      const response = await this.client.post('/api/recognize/paragraph', form, {
        headers: form.getHeaders(),
      });
      
      if (response.data.success) {
        return response.data.lines;
      } else {
        throw new Error(response.data.error || 'Recognition failed');
      }
    } catch (error) {
      throw new Error(`Paragraph recognition failed: ${error.message}`);
    }
  }
  
  async preprocessImage(imagePath) {
    try {
      const form = new FormData();
      form.append('file', fs.createReadStream(imagePath));
      
      const response = await this.client.post('/api/preprocess', form, {
        headers: form.getHeaders(),
      });
      
      return response.data;
    } catch (error) {
      throw new Error(`Preprocessing failed: ${error.message}`);
    }
  }
}

module.exports = HTRClient;
```

### Express.js Integration

```javascript
const express = require('express');
const HTRClient = require('./htr-client');

const app = express();
const htrClient = new HTRClient('https://your-api-url.ngrok.io');

app.post('/recognize', async (req, res) => {
  try {
    // Assume image is sent as base64
    const { imageBase64, mode } = req.body;
    
    // Save base64 to file
    const buffer = Buffer.from(imageBase64, 'base64');
    const imagePath = '/tmp/image.png';
    require('fs').writeFileSync(imagePath, buffer);
    
    let result;
    if (mode === 'line') {
      result = await htrClient.recognizeLine(imagePath);
    } else {
      result = await htrClient.recognizeParagraph(imagePath);
    }
    
    res.json({
      success: true,
      result: result
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

app.listen(3000, () => console.log('Server running on port 3000'));
```

### Browser Fetch

```javascript
const apiUrl = 'https://your-api-url.ngrok.io';

async function recognizeLineFromFile(fileInput) {
  try {
    const file = fileInput.files[0];
    if (!file) {
      throw new Error('No file selected');
    }
    
    const formData = new FormData();
    formData.append('file', file);
    formData.append('use_beam_search', 'true');
    
    const response = await fetch(`${apiUrl}/api/recognize/line`, {
      method: 'POST',
      body: formData,
    });
    
    const data = await response.json();
    
    if (data.success) {
      console.log('Recognized text:', data.text);
      return data.text;
    } else {
      throw new Error(data.error);
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

async function recognizeParagraphFromFile(fileInput) {
  try {
    const file = fileInput.files[0];
    if (!file) {
      throw new Error('No file selected');
    }
    
    const formData = new FormData();
    formData.append('file', file);
    formData.append('segmentation_method', 'projection');
    formData.append('use_beam_search', 'true');
    
    const response = await fetch(`${apiUrl}/api/recognize/paragraph`, {
      method: 'POST',
      body: formData,
    });
    
    const data = await response.json();
    
    if (data.success) {
      console.log('Recognized lines:', data.lines);
      return data.lines;
    } else {
      throw new Error(data.error);
    }
  } catch (error) {
    console.error('Error:', error);
  }
}
```

---

## 🐍 Python

### Simple Python Client

```python
import requests
from pathlib import Path
from typing import List, Union

class HTRClient:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
    
    def health_check(self) -> dict:
        """Check API health"""
        try:
            response = self.session.get(
                f'{self.base_url}/api/health',
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            raise Exception(f'Health check failed: {e}')
    
    def get_model_info(self) -> dict:
        """Get model information"""
        try:
            response = self.session.get(
                f'{self.base_url}/api/model/info',
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            raise Exception(f'Failed to get model info: {e}')
    
    def recognize_line(
        self,
        image_path: Union[str, Path],
        use_beam_search: bool = True
    ) -> str:
        """Recognize single line"""
        try:
            with open(image_path, 'rb') as f:
                files = {'file': f}
                data = {'use_beam_search': str(use_beam_search).lower()}
                
                response = self.session.post(
                    f'{self.base_url}/api/recognize/line',
                    files=files,
                    data=data,
                    timeout=30
                )
                
                response.raise_for_status()
                result = response.json()
                
                if result.get('success'):
                    return result['text']
                else:
                    raise Exception(result.get('error', 'Recognition failed'))
        except Exception as e:
            raise Exception(f'Line recognition failed: {e}')
    
    def recognize_paragraph(
        self,
        image_path: Union[str, Path],
        segmentation_method: str = 'projection',
        use_beam_search: bool = True
    ) -> List[str]:
        """Recognize paragraph (multiple lines)"""
        try:
            with open(image_path, 'rb') as f:
                files = {'file': f}
                data = {
                    'segmentation_method': segmentation_method,
                    'use_beam_search': str(use_beam_search).lower()
                }
                
                response = self.session.post(
                    f'{self.base_url}/api/recognize/paragraph',
                    files=files,
                    data=data,
                    timeout=60
                )
                
                response.raise_for_status()
                result = response.json()
                
                if result.get('success'):
                    return result['lines']
                else:
                    raise Exception(result.get('error', 'Recognition failed'))
        except Exception as e:
            raise Exception(f'Paragraph recognition failed: {e}')
    
    def preprocess_image(self, image_path: Union[str, Path]) -> dict:
        """Get preprocessing preview"""
        try:
            with open(image_path, 'rb') as f:
                files = {'file': f}
                
                response = self.session.post(
                    f'{self.base_url}/api/preprocess',
                    files=files,
                    timeout=10
                )
                
                response.raise_for_status()
                return response.json()
        except Exception as e:
            raise Exception(f'Preprocessing failed: {e}')


# Usage example
if __name__ == '__main__':
    client = HTRClient('https://your-api-url.ngrok.io')
    
    # Check health
    print(client.health_check())
    
    # Get model info
    print(client.get_model_info())
    
    # Recognize line
    text = client.recognize_line('path/to/image.png')
    print(f'Recognized: {text}')
    
    # Recognize paragraph
    lines = client.recognize_paragraph('path/to/paragraph.png')
    print(f'Lines: {lines}')
```

### Streamlit Web App

```python
import streamlit as st
from pathlib import Path
from htr_client import HTRClient

st.set_page_config(page_title='HTR Web App', layout='wide')

# Sidebar config
st.sidebar.title('Configuration')
api_url = st.sidebar.text_input(
    'API URL',
    value='https://your-api-url.ngrok.io'
)
mode = st.sidebar.radio('Mode', ['Line Recognition', 'Paragraph Recognition'])

# Initialize client
client = HTRClient(api_url)

# Main page
st.title('Handwriting Text Recognition')

# Health check
try:
    health = client.health_check()
    st.success(f'API Status: {health["status"]}')
except Exception as e:
    st.error(f'API Error: {e}')

# File upload
uploaded_file = st.file_uploader('Upload image', type=['png', 'jpg', 'jpeg'])

if uploaded_file:
    # Display image
    col1, col2 = st.columns(2)
    
    with col1:
        st.image(uploaded_file, caption='Uploaded Image')
    
    # Save temporarily
    temp_path = Path('/tmp/uploaded_image.png')
    temp_path.write_bytes(uploaded_file.getbuffer())
    
    # Recognize
    if st.button('Recognize'):
        with st.spinner('Processing...'):
            try:
                if mode == 'Line Recognition':
                    text = client.recognize_line(str(temp_path))
                    with col2:
                        st.success('✅ Recognition Complete')
                        st.text_area('Result', value=text, height=100)
                else:
                    lines = client.recognize_paragraph(str(temp_path))
                    with col2:
                        st.success('✅ Recognition Complete')
                        for i, line in enumerate(lines):
                            st.write(f'**Line {i+1}:** {line}')
            except Exception as e:
                st.error(f'Error: {e}')
```

---

## 📞 cURL Examples

### Health Check
```bash
curl http://localhost:5000/api/health
```

### Model Info
```bash
curl http://localhost:5000/api/model/info
```

### Recognize Line (File)
```bash
curl -X POST \
  -F "file=@image.png" \
  -F "use_beam_search=true" \
  http://localhost:5000/api/recognize/line
```

### Recognize Line (Base64)
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "image_base64": "iVBORw0KGgoAAAANSUhEUg...",
    "use_beam_search": true
  }' \
  http://localhost:5000/api/recognize/line
```

### Recognize Paragraph
```bash
curl -X POST \
  -F "file=@document.png" \
  -F "segmentation_method=projection" \
  -F "use_beam_search=true" \
  http://localhost:5000/api/recognize/paragraph
```

### Get Preprocessing Preview
```bash
curl -X POST \
  -F "file=@image.png" \
  http://localhost:5000/api/preprocess \
  -o preprocessed.png
```

---

## 📊 Postman Collection

Save as `HTR_API.postman_collection.json`:

```json
{
  "info": {
    "name": "HTR API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "url": "{{base_url}}/api/health"
      }
    },
    {
      "name": "Model Info",
      "request": {
        "method": "GET",
        "url": "{{base_url}}/api/model/info"
      }
    },
    {
      "name": "Recognize Line",
      "request": {
        "method": "POST",
        "url": "{{base_url}}/api/recognize/line",
        "body": {
          "mode": "formdata",
          "formdata": [
            {
              "key": "file",
              "type": "file"
            },
            {
              "key": "use_beam_search",
              "value": "true"
            }
          ]
        }
      }
    },
    {
      "name": "Recognize Paragraph",
      "request": {
        "method": "POST",
        "url": "{{base_url}}/api/recognize/paragraph",
        "body": {
          "mode": "formdata",
          "formdata": [
            {
              "key": "file",
              "type": "file"
            },
            {
              "key": "segmentation_method",
              "value": "projection"
            },
            {
              "key": "use_beam_search",
              "value": "true"
            }
          ]
        }
      }
    },
    {
      "name": "Preprocess Image",
      "request": {
        "method": "POST",
        "url": "{{base_url}}/api/preprocess",
        "body": {
          "mode": "formdata",
          "formdata": [
            {
              "key": "file",
              "type": "file"
            }
          ]
        }
      }
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:5000"
    }
  ]
}
```

---

**Version**: 1.0.0  
**Date**: March 16, 2026  
**Status**: ✅ Ready to use

