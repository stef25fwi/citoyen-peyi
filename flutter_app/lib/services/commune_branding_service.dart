import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import 'firebase_auth_service.dart';
import 'firestore_data_service.dart';

class CommuneBrandingException implements Exception {
  const CommuneBrandingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CommuneBrandingModel {
  const CommuneBrandingModel({
    required this.communeId,
    required this.communeName,
    required this.normalizedCommuneName,
    required this.logoUrl,
    this.logoContentType,
    this.logoStoragePath,
    this.updatedAt,
  });

  final String communeId;
  final String communeName;
  final String normalizedCommuneName;
  final String logoUrl;
  final String? logoContentType;
  final String? logoStoragePath;
  final String? updatedAt;

  bool get hasLogo => logoUrl.trim().isNotEmpty;

  static CommuneBrandingModel? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final communeName = (data['communeName'] as String? ?? '').trim();
    final logoUrl = (data['logoUrl'] as String? ?? '').trim();
    if (communeName.isEmpty) return null;

    return CommuneBrandingModel(
      communeId: (data['communeId'] as String? ?? '').trim(),
      communeName: communeName,
      normalizedCommuneName: (data['normalizedCommuneName'] as String? ?? '').trim(),
      logoUrl: logoUrl,
      logoContentType: data['logoContentType'] as String?,
      logoStoragePath: data['logoStoragePath'] as String?,
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static String _readDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate().toIso8601String();
    return raw?.toString() ?? '';
  }
}

class CommuneBrandingService {
  CommuneBrandingService._();

  static final CommuneBrandingService instance = CommuneBrandingService._();

  static const _collection = 'commune_branding';
  static const _maxLogoBytes = 4 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickLogo() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
  }

  Future<CommuneBrandingModel?> loadForCommune({
    String? communeId,
    String? communeName,
  }) async {
    final db = FirestoreDataService.instance;
    if (db == null) return null;

    final docId = documentIdFor(communeId: communeId, communeName: communeName);
    if (docId.isNotEmpty) {
      final direct = await db.collection(_collection).doc(docId).get();
      final model = CommuneBrandingModel.fromMap(direct.data());
      if (model != null) return model;
    }

    final normalizedName = normalizeCommuneName(communeName ?? '');
    if (normalizedName.isEmpty) return null;

    final snapshot = await db
        .collection(_collection)
        .where('normalizedCommuneName', isEqualTo: normalizedName)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return CommuneBrandingModel.fromMap(snapshot.docs.first.data());
  }

  Future<CommuneBrandingModel> uploadLogo({
    required XFile file,
    required String communeId,
    required String communeName,
  }) async {
    final trimmedName = communeName.trim();
    if (trimmedName.isEmpty) {
      throw const CommuneBrandingException('Nom de collectivité requis.');
    }

    final docId = documentIdFor(communeId: communeId, communeName: communeName);
    if (docId.isEmpty) {
      throw const CommuneBrandingException('Identifiant de collectivité invalide.');
    }

    final webpBytes = await _convertToWebp(file);
    if (webpBytes.lengthInBytes > _maxLogoBytes) {
      throw const CommuneBrandingException(
        'Le logo converti depasse 4 Mo. Reduisez sa taille puis reessayez.',
      );
    }

    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      throw const CommuneBrandingException('Backend non configure (API_BASE_URL vide).');
    }

    final token = await FirebaseAuthService.instance.currentIdToken();
    if (token == null || token.isEmpty) {
      throw const CommuneBrandingException(
        'Session expiree, reconnectez-vous puis reessayez.',
      );
    }

    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$base/api/commune-branding/logo'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'data': base64Encode(webpBytes),
              'contentType': 'image/webp',
              'communeId': docId,
              'communeName': trimmedName,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (error) {
      throw CommuneBrandingException(
        'Televersement du logo impossible: ${error.toString()}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Televersement du logo refuse.';
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic> && payload['message'] is String) {
          message = payload['message'] as String;
        }
      } catch (_) {}
      throw CommuneBrandingException(message);
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final branding = CommuneBrandingModel.fromMap(
        payload['branding'] as Map<String, dynamic>?,
      );
      if (branding == null) {
        throw const FormatException('branding manquant');
      }
      return branding;
    } catch (_) {
      throw const CommuneBrandingException('Reponse backend illisible pour le logo.');
    }
  }

  Future<Uint8List> _convertToWebp(XFile file) async {
    final originalBytes = await file.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw const CommuneBrandingException(
        'Image illisible. Choisissez un fichier JPG, PNG ou WebP valide.',
      );
    }

    final resized = decoded.width > 1200
        ? img.copyResize(decoded, width: 1200)
        : decoded;
    final encoded = img.encodeWebP(resized);
    return Uint8List.fromList(encoded);
  }

  static String normalizeCommuneName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .substring(0, value.trim().isEmpty ? 0 : (value.trim().length > 120 ? 120 : value.trim().length));
  }

  static String documentIdFor({String? communeId, String? communeName}) {
    final id = (communeId ?? '').trim();
    if (id.isNotEmpty) {
      return id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    }
    return normalizeCommuneName(communeName ?? '');
  }
}