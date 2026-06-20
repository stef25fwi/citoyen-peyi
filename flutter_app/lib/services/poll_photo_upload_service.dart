import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import 'auth_session_store.dart';
import 'firebase_auth_service.dart';

class PollPhotoUploadException implements Exception {
  const PollPhotoUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Upload des photos de consultation.
///
/// L'upload passe par le backend (Admin SDK) et NON par le SDK Storage client.
/// Raison : sur Safari/iPad l'app utilise le repli REST pour l'auth Firebase,
/// donc FirebaseAuth.currentUser est null et un upload Storage cote client part
/// non authentifie (les regles le refusent avec une erreur opaque). En passant
/// par le backend (jeton REST dans l'en-tete Authorization), l'upload fonctionne
/// sur tous les navigateurs. Une photo par requete.
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

    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      throw const PollPhotoUploadException(
          'Backend non configure (API_BASE_URL vide).');
    }

    // currentIdToken gere le repli REST (Safari/iPad) : indispensable ici.
    final token = await FirebaseAuthService.instance.currentIdToken();
    if (token == null || token.isEmpty) {
      throw const PollPhotoUploadException(
          'Session expiree, reconnectez-vous puis reessayez.');
    }

    final session = AuthSessionStore.instance.currentSession;
    final communeId = session?.commune?.code ?? session?.commune?.name ?? '';
    final uri = Uri.parse('$base/api/polls/photos');
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

      late http.Response response;
      try {
        response = await http
            .post(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'data': base64Encode(bytes),
                'contentType': contentType,
                'draftId': draftId,
                if (communeId.isNotEmpty) 'communeId': communeId,
              }),
            )
            .timeout(const Duration(seconds: 60));
      } catch (error) {
        throw PollPhotoUploadException(
          'Televersement de la photo ${index + 1} impossible: ${error.toString()}',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = 'Televersement de la photo ${index + 1} refuse.';
        try {
          final payload = jsonDecode(response.body);
          if (payload is Map<String, dynamic> && payload['message'] is String) {
            message = payload['message'] as String;
          }
        } catch (_) {}
        throw PollPhotoUploadException(message);
      }

      try {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final url = payload['url'] as String?;
        if (url == null || url.isEmpty) {
          throw const FormatException('url manquante');
        }
        urls.add(url);
      } catch (error) {
        throw PollPhotoUploadException(
          'Reponse backend illisible pour la photo ${index + 1}.',
        );
      }
    }

    return urls;
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
}
