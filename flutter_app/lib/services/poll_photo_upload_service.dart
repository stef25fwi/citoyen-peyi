import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_session_store.dart';
import 'firebase_auth_service.dart';

class PollPhotoUploadException implements Exception {
  const PollPhotoUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PollPhotoUploadService {
  PollPhotoUploadService._();

  static final PollPhotoUploadService instance = PollPhotoUploadService._();
  static const int maxPhotos = 6;
  static const int maxPhotoBytes = 10 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();

  Future<List<XFile>> pickPhotos(
      {List<XFile> current = const <XFile>[]}) async {
    final remainingSlots = maxPhotos - current.length;
    if (remainingSlots <= 0) {
      throw const PollPhotoUploadException('Maximum 6 photos par sondage.');
    }

    final picked = await _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 1920,
    );
    if (picked.isEmpty) return current;

    return <XFile>[
      ...current,
      ...picked.take(remainingSlots),
    ];
  }

  Future<List<String>> uploadPhotos({
    required List<XFile> photos,
    required String draftId,
  }) async {
    if (photos.isEmpty) return const <String>[];

    await FirebaseAuthService.instance.initialize();

    final session = AuthSessionStore.instance.currentSession;
    final communeId = _safePathSegment(
      session?.commune?.code ?? session?.commune?.name ?? 'commune',
    );
    final safeDraftId = _safePathSegment(draftId);
    final urls = <String>[];

    for (var index = 0; index < photos.length; index++) {
      final photo = photos[index];
      final bytes = await photo.readAsBytes();

      if (bytes.lengthInBytes > maxPhotoBytes) {
        throw PollPhotoUploadException(
          'La photo ${index + 1} depasse 10 Mo. Compressez-la ou choisissez une autre image.',
        );
      }

      final contentType = _contentTypeFor(photo);
      if (contentType == null) {
        throw PollPhotoUploadException(
          'La photo ${index + 1} doit etre au format JPG, PNG ou WebP.',
        );
      }

      final extension = _extensionFor(contentType);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${index + 1}.$extension';

      final ref = FirebaseStorage.instance
          .ref()
          .child('poll_assets/$communeId/$safeDraftId/$fileName');

      await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(
          contentType: contentType,
          customMetadata: const {'module': 'polls'},
        ),
      );

      urls.add(await ref.getDownloadURL());
    }

    if (kDebugMode) {
      debugPrint('[PollPhotoUploadService] ${urls.length} photo(s) uploaded');
    }

    return urls;
  }

  String _safePathSegment(String value) {
    final safe = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return safe.isEmpty ? 'commune' : safe;
  }

  String? _contentTypeFor(XFile file) {
    final declared = file.mimeType?.toLowerCase().trim();

    if (declared == 'image/jpeg' || declared == 'image/jpg') {
      return 'image/jpeg';
    }
    if (declared == 'image/png') return 'image/png';
    if (declared == 'image/webp') return 'image/webp';

    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';

    return null;
  }

  String _extensionFor(String contentType) {
    switch (contentType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/jpeg':
      default:
        return 'jpg';
    }
  }
}
