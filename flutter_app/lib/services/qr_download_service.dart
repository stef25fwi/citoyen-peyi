import 'dart:typed_data';

import 'qr_download_service_stub.dart'
    if (dart.library.html) 'qr_download_service_web.dart' as qr_download;

class QrDownloadService {
  QrDownloadService._();

  static final QrDownloadService instance = QrDownloadService._();

  Future<void> downloadPng({
    required Uint8List bytes,
    required String fileName,
  }) {
    return qr_download.downloadQrPng(bytes, fileName);
  }
}