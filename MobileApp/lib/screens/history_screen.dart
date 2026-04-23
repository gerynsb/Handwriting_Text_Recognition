import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/upload_item.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final StorageService storageService;

  const HistoryScreen({
    Key? key,
    required this.storageService,
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<UploadItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = widget.storageService.getUploadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadHistory();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearHistoryDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<UploadItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by uploading and recognizing images',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: history.length,
            itemBuilder: (context, index) {
              return _buildHistoryItem(context, history[index], index);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, UploadItem item, int index) {
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
    final imageExists = File(item.imagePath).existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildThumbnail(item, imageExists),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload #${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              dateFormatter.format(item.uploadDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (item.recognizedText != null) ...[
              Text(
                'Result: ${item.recognizedText!.length} characters',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
              ),
            ] else if (item.errorMessage != null) ...[
              Text(
                'Error: ${item.errorMessage!}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (item.isProcessing) ...[
              Text(
                'Processing...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
              onTap: () {
                _showDetailDialog(context, item, imageExists);
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.content_copy),
                  SizedBox(width: 8),
                  Text('Copy Text'),
                ],
              ),
              onTap: () {
                _copyToClipboard(item);
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
              onTap: () {
                _deleteItem(item);
              },
            ),
          ],
        ),
        onTap: () => _showDetailDialog(context, item, imageExists),
      ),
    );
  }

  Widget _buildThumbnail(UploadItem item, bool exists) {
    if (!exists) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(item.imagePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
  }

  void _showDetailDialog(
      BuildContext context, UploadItem item, bool imageExists) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upload Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Image Preview
                if (imageExists)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(item.imagePath),
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Date
                _buildDetailRow(
                  'Date',
                  DateFormat('dd MMM yyyy, HH:mm').format(item.uploadDate),
                ),
                const SizedBox(height: 8),

                // File path
                _buildDetailRow(
                  'File Path',
                  item.imagePath,
                  canCopy: true,
                ),
                const SizedBox(height: 16),

                // Recognition Result
                Text(
                  'Recognition Result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                if (item.recognizedText != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: SelectableText(
                      item.recognizedText!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else if (item.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Error: ${item.errorMessage}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade700,
                          ),
                    ),
                  )
                else if (item.isProcessing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Still processing...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    if (item.recognizedText != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _copyToClipboard(item);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Copy'),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _deleteItem(item);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool canCopy = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Future<List<UploadItem>> get history async =>
      await widget.storageService.getUploadHistory();

  void _copyToClipboard(UploadItem item) {
    if (item.recognizedText != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteItem(UploadItem item) async {
    await widget.storageService.deleteUploadItem(item.id);
    setState(() {
      _loadHistory();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item deleted'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearHistory() async {
    await widget.storageService.clearAllHistory();
    setState(() {
      _loadHistory();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('History cleared'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
