import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/htr_service.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isTestingApi = false;
  String? _apiStatusMessage;
  Color? _apiStatusColor;

  @override
  void initState() {
    super.initState();
    _loadSavedApiUrl();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedApiUrl() async {
    final url = await HTRService.getApiBaseUrl();
    if (!mounted) {
      return;
    }
    setState(() {
      _apiUrlController.text = url;
    });
  }

  Future<void> _saveApiUrl() async {
    final inputUrl = _apiUrlController.text.trim();
    if (!HTRService.isValidApiBaseUrl(inputUrl)) {
      setState(() {
        _apiStatusMessage =
            'URL tidak valid. Contoh: https://abc123.ngrok-free.app';
        _apiStatusColor = Colors.red;
      });
      return;
    }

    await HTRService.setApiBaseUrl(inputUrl);
    if (!mounted) {
      return;
    }
    setState(() {
      _apiStatusMessage =
          'URL API tersimpan. Sekarang app akan memakai URL ini.';
      _apiStatusColor = Colors.green;
    });
  }

  Future<void> _testApiConnection() async {
    final inputUrl = _apiUrlController.text.trim();
    if (!HTRService.isValidApiBaseUrl(inputUrl)) {
      setState(() {
        _apiStatusMessage =
            'URL tidak valid. Pastikan diawali http:// atau https://';
        _apiStatusColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isTestingApi = true;
      _apiStatusMessage = null;
    });

    try {
      final ok = await HTRService(baseUrl: inputUrl).healthCheck();
      if (!mounted) {
        return;
      }
      setState(() {
        _apiStatusMessage = ok
            ? 'Koneksi berhasil. API dan model siap digunakan.'
            : 'Tidak bisa terhubung ke API. Cek URL Ngrok dan server backend.';
        _apiStatusColor = ok ? Colors.green : Colors.red;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _apiStatusMessage =
            'Gagal test koneksi. Pastikan server hidup dan URL Ngrok aktif.';
        _apiStatusColor = Colors.red;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTestingApi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Theme Section
            _buildThemeSection(),
            const Divider(),

            // About Section
            _buildAboutSection(),
            const Divider(),

            // Features Section
            _buildFeaturesSection(),
            const Divider(),

            // API Configuration Section
            _buildAPIConfigSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark Mode',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              themeProvider.isDarkMode
                                  ? 'Dark mode is enabled'
                                  : 'Light mode is enabled',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.setTheme(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (themeProvider.isDarkMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dark mode helps reduce eye strain in low light conditions',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue.shade700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.info_outline,
            title: 'App Name',
            subtitle: 'HTR - Handwriting Text Recognition',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: Icons.verified,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: Icons.person,
            title: 'Developer',
            subtitle: 'Dean - Gerynsb',
          ),
          // const SizedBox(height: 8),
          // _buildInfoCard(
          //   icon: Icons.calendar_today,
          //   title: 'Release Date',
          //   subtitle: 'March 2026',
          // ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.image_search,
            title: 'Image Upload',
            description: 'Upload images from device or take with camera',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.auto_fix_high,
            title: 'Handwriting Recognition',
            description: 'AI-powered text recognition using CRNN model',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.history,
            title: 'Upload History',
            description: 'Keep track of all your uploads and results',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.brightness_7,
            title: 'Dark Mode',
            description: 'Comfortable viewing in low light conditions',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.speed,
            title: 'Fast Processing',
            description: 'Quick recognition with beam search decoder',
          ),
        ],
      ),
    );
  }

  Widget _buildAPIConfigSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Configuration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.api,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flask/FastAPI Server',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masukkan URL backend (contoh URL Ngrok)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.amber.shade700,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Base URL API',
                    hintText: 'https://abc123.ngrok-free.app',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isTestingApi ? null : _testApiConnection,
                        icon: _isTestingApi
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.health_and_safety),
                        label: const Text('Test Koneksi'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTestingApi ? null : _saveApiUrl,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan URL'),
                      ),
                    ),
                  ],
                ),
                if (_apiStatusMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _apiStatusMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _apiStatusColor ?? Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(
              'API Endpoints',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEndpointInfo(
                      '/api/health',
                      'GET',
                      'Check API health status',
                    ),
                    const SizedBox(height: 12),
                    _buildEndpointInfo(
                      '/api/model/info',
                      'GET',
                      'Get model information',
                    ),
                    const SizedBox(height: 12),
                    _buildEndpointInfo(
                      '/api/recognize/line',
                      'POST',
                      'Recognize single line of text',
                    ),
                    const SizedBox(height: 12),
                    _buildEndpointInfo(
                      '/api/recognize/paragraph',
                      'POST',
                      'Recognize multiple lines (paragraph)',
                    ),
                    const SizedBox(height: 12),
                    _buildEndpointInfo(
                      '/api/preprocess',
                      'POST',
                      'Get preprocessing preview',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(
              'Model Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModelInfoRow('Architecture', 'CRNN + BiLSTM 2×256'),
                    const SizedBox(height: 12),
                    _buildModelInfoRow('Framework', 'PyTorch 2.0.1'),
                    const SizedBox(height: 12),
                    _buildModelInfoRow(
                        'Input Size', '64 × 512 (height × width)'),
                    const SizedBox(height: 12),
                    _buildModelInfoRow('Classes', '80 (79 chars + blank)'),
                    const SizedBox(height: 12),
                    _buildModelInfoRow('Best Test CER', '6.70%'),
                    const SizedBox(height: 12),
                    _buildModelInfoRow('Decoding', 'Beam Search (width=10)'),
                    const SizedBox(height: 12),
                    _buildModelInfoRow('Speed (GPU)', '100-200ms per line'),
                    const SizedBox(height: 12),
                    _buildModelInfoRow('Speed (CPU)', '300-500ms per line'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Version 1.0.0 • March 2026',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointInfo(
      String endpoint, String method, String description) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMethodColor(method),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  method,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  endpoint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildModelInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Flexible(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
