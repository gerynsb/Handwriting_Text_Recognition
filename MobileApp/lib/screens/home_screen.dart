import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/upload_item.dart';
import '../services/htr_service.dart';
import '../services/storage_service.dart';
import 'about_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({
    Key? key,
    required this.storageService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final HTRService _htrService = HTRService();
  final TextEditingController _resultController = TextEditingController();

  File? _selectedImage;
  List<UploadItem> _recentScans = [];
  bool _isLoadingRecent = true;
  bool _isProcessing = false;
  String? _recognitionResult;
  String? _errorMessage;
  String _recognitionMode = 'line';
  bool _useBeamSearch = true;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(),
      appBar: AppBar(
        title: const Text('HTR - Handwriting Recognition'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 20),
              _selectedImage == null
                  ? _buildCaptureSection()
                  : _buildImagePreviewSection(),
              if (_selectedImage != null) ...[
                const SizedBox(height: 16),
                _buildModeSelectionSection(),
                const SizedBox(height: 12),
                _buildBeamSearchOption(),
              ],
              const SizedBox(height: 20),
              if (_recognitionResult != null && !_isProcessing)
                _buildResultSection()
              else if (_errorMessage != null && !_isProcessing)
                _buildErrorSection(),
              if (_isProcessing) _buildProcessingSection(),
              const SizedBox(height: 20),
              _buildRecentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HTR Mobile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Minimal OCR Workspace',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('All History'),
              onTap: _openHistory,
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Konfigurasi Sistem'),
              onTap: _openSettings,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang'),
              onTap: _openAbout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to HTR',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Take a photo or select image to recognize handwriting',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.document_scanner_outlined,
                  size: 52,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 14),
                Text(
                  'No image selected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Start by taking a photo or picking from gallery',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takeFromCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showFullImagePreview,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey.shade100,
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _recognizeText,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Recognize'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _cropImage,
                  icon: const Icon(Icons.crop_outlined),
                  label: const Text('Crop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showFullImagePreview,
                  icon: const Icon(Icons.zoom_out_map),
                  label: const Text('Preview Full'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _clearSelection,
                  icon: const Icon(Icons.close),
                  label: const Text('Clear'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recognition Mode',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Single Line'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: 'line',
                  groupValue: _recognitionMode,
                  onChanged: _selectedImage == null
                      ? null
                      : (val) {
                          setState(() => _recognitionMode = val!);
                          _clearResults();
                        },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Paragraph'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: 'paragraph',
                  groupValue: _recognitionMode,
                  onChanged: _selectedImage == null
                      ? null
                      : (val) {
                          setState(() => _recognitionMode = val!);
                          _clearResults();
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBeamSearchOption() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Beam Search',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'More accurate but slower',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: _useBeamSearch,
            onChanged: _selectedImage == null
                ? null
                : (val) {
                    setState(() => _useBeamSearch = val);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Scans',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: _openHistory,
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingRecent)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recentScans.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    color: Theme.of(context).primaryColor,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada hasil scan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Setelah Anda menyimpan hasil OCR, daftar terbaru akan muncul di sini.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._recentScans.map(_buildRecentItem),
        ],
      ),
    );
  }

  Widget _buildRecentItem(UploadItem item) {
    final imageFile = File(item.imagePath);
    final hasImage = imageFile.existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasImage
                ? Image.file(
                    imageFile,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 54,
                    height: 54,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(item.uploadDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  item.recognizedText?.trim().isNotEmpty == true
                      ? item.recognizedText!.trim().replaceAll('\n', ' ')
                      : 'Belum ada hasil teks',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recognition Result',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.green.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: TextField(
                controller: _resultController,
                maxLines: null,
                minLines: 3,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Anda bisa revisi hasil OCR sebelum disimpan...',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Copy'),
                ),
                ElevatedButton.icon(
                  onPressed: _saveToHistory,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _recognitionResult = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Processing your image...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _recognitionMode == 'line'
                  ? 'This usually takes 1-3 seconds'
                  : 'This may take 5-10 seconds',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _recognitionResult = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _takeFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _recognitionResult = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _recognizeText() async {
    if (_selectedImage == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _recognitionResult = null;
      _errorMessage = null;
    });

    try {
      final XFile imageFile = XFile(_selectedImage!.path);
      String result;

      if (_recognitionMode == 'line') {
        result = await _htrService.recognizeLine(
          imageFile,
          useBeamSearch: _useBeamSearch,
        );
      } else {
        final lines = await _htrService.recognizeParagraph(
          imageFile,
          useBeamSearch: _useBeamSearch,
        );
        result = lines.join('\n');
      }

      final normalizedResult = result.isEmpty ? 'No text detected' : result;

      setState(() {
        _recognitionResult = normalizedResult;
        _resultController.text = normalizedResult;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedImage = null;
      _recognitionResult = null;
      _errorMessage = null;
      _resultController.clear();
    });
  }

  void _clearResults() {
    setState(() {
      _recognitionResult = null;
      _errorMessage = null;
      _resultController.clear();
    });
  }

  void _copyToClipboard() {
    final text = _resultController.text.trim();
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveToHistory() async {
    final editedResult = _resultController.text.trim();
    if (_selectedImage == null || editedResult.isEmpty) {
      return;
    }

    try {
      final item = UploadItem(
        id: const Uuid().v4(),
        imagePath: _selectedImage!.path,
        recognizedText: editedResult,
        uploadDate: DateTime.now(),
      );

      await widget.storageService.addUploadToHistory(item);
      await _loadRecentScans();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to history'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showFullImagePreview() {
    if (_selectedImage == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 6, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preview Gambar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Container(
                    color: Colors.black,
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cropImage() async {
    if (_selectedImage == null) {
      return;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _selectedImage!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            statusBarColor: Colors.black,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Theme.of(context).primaryColor,
            dimmedLayerColor: Colors.black54,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile == null) {
        return;
      }

      setState(() {
        _selectedImage = File(croppedFile.path);
        _recognitionResult = null;
        _errorMessage = null;
        _resultController.clear();
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar berhasil di-crop. Silakan recognize ulang.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal crop gambar: $e'),
        ),
      );
    }
  }

  Future<void> _loadRecentScans() async {
    final history = await widget.storageService.getUploadHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _recentScans = history.take(5).toList();
      _isLoadingRecent = false;
    });
  }

  void _openHistory() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(storageService: widget.storageService),
      ),
    ).then((_) => _loadRecentScans());
  }

  void _openSettings() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openAbout() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $h:$min';
  }
}
