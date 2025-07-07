import 'dart:io';
import 'package:dio/dio.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  Future<String?> uploadImage(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'upload_preset': CloudinaryConfig.uploadPreset,
      });

      Response response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'];
      }

      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  String? getOptimizedImageUrl(
    String? originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    if (originalUrl == null) return null;

    // Extract public_id from the URL
    final uri = Uri.parse(originalUrl);
    final pathSegments = uri.pathSegments;

    if (pathSegments.length < 3) return originalUrl;

    final publicId = pathSegments.sublist(2).join('/').split('.').first;

    String transformation = 'q_$quality';
    if (width != null) transformation += ',w_$width';
    if (height != null) transformation += ',h_$height';

    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/$transformation/$publicId';
  }
}
