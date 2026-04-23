class UploadItem {
  final String id;
  final String imagePath;
  final String? recognizedText;
  final DateTime uploadDate;
  final bool isProcessing;
  final String? errorMessage;

  UploadItem({
    required this.id,
    required this.imagePath,
    this.recognizedText,
    required this.uploadDate,
    this.isProcessing = false,
    this.errorMessage,
  });

  // Convert to JSON untuk penyimpanan local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'recognizedText': recognizedText,
      'uploadDate': uploadDate.toIso8601String(),
      'isProcessing': isProcessing,
      'errorMessage': errorMessage,
    };
  }

  // Create dari JSON
  factory UploadItem.fromJson(Map<String, dynamic> json) {
    return UploadItem(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      recognizedText: json['recognizedText'] as String?,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      isProcessing: json['isProcessing'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  // Copy dengan field yang berbeda
  UploadItem copyWith({
    String? id,
    String? imagePath,
    String? recognizedText,
    DateTime? uploadDate,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return UploadItem(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      recognizedText: recognizedText ?? this.recognizedText,
      uploadDate: uploadDate ?? this.uploadDate,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
