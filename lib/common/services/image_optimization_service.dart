import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../chat/domain/media_policy.dart';

/// Predefined optimization profiles for different UI and storage scenarios.
enum ImageOptimizationPreset {
  /// Small avatar image for profile and icons (e.g. 512x512, ~100KB)
  avatar(
    maxWidth: 512,
    maxHeight: 512,
    quality: 85,
    maxSizeBytes: 5 * 1024 * 1024,
  ),

  /// High quality gallery / photo album for pet moments (e.g. 1440x1440, ~250KB)
  galleryPhoto(
    maxWidth: 1440,
    maxHeight: 1440,
    quality: 82,
    maxSizeBytes: 10 * 1024 * 1024,
  ),

  /// Chat room multimedia sharing image (e.g. 1920x1920, ~400KB)
  chatMedia(
    maxWidth: 1920,
    maxHeight: 1920,
    quality: 85,
    maxSizeBytes: 20 * 1024 * 1024,
  );

  const ImageOptimizationPreset({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.maxSizeBytes,
  });

  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int maxSizeBytes;
}

class ImageOptimizationException implements Exception {
  const ImageOptimizationException(this.message);

  final String message;

  @override
  String toString() => 'ImageOptimizationException: $message';
}

/// Centralized service handling client-side image optimization, resolution constraints,
/// and memory-safe cache sizing to minimize bandwidth, storage, and GPU RAM usage.
class ImageOptimizationService {
  ImageOptimizationService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Picks and automatically optimizes an image using the selected preset.
  /// Applies hardware/OS level downscaling and compression before the file is handed to Flutter.
  Future<XFile?> pickOptimizedImage({
    ImageSource source = ImageSource.gallery,
    ImageOptimizationPreset preset = ImageOptimizationPreset.avatar,
  }) async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: preset.maxWidth.toDouble(),
        maxHeight: preset.maxHeight.toDouble(),
        imageQuality: preset.quality,
      );
    } on UnimplementedError {
      throw const ImageOptimizationException('當前裝置不支援此操作，請從檔案中選取圖片');
    } on UnsupportedError {
      throw const ImageOptimizationException('當前裝置不支援此操作，請從檔案中選取圖片');
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('not supported') ||
          str.contains('unsupported') ||
          str.contains('unimplemented') ||
          str.contains('camera')) {
        throw const ImageOptimizationException('當前裝置不支援此操作，請從檔案中選取圖片');
      }
      rethrow;
    }

    if (file == null) return null;

    // Validate mime type / extension
    final validation = MediaPolicy.validate(
      path: file.path,
      mimeType: file.mimeType,
      maxSizeBytes: preset.maxSizeBytes,
    );
    if (!validation.isValid) {
      throw ImageOptimizationException(
        validation.errorMessage ?? '不支援的圖片格式，僅支援 JPG, PNG, GIF, WebP',
      );
    }

    // Double check size if available
    try {
      final size = await file.length();
      if (size > preset.maxSizeBytes) {
        final limitMb = (preset.maxSizeBytes / (1024 * 1024)).round();
        throw ImageOptimizationException('選取的圖片過大，檔案上限為 ${limitMb}MB');
      }
    } catch (e) {
      if (e is ImageOptimizationException) rethrow;
      // length check may fail on some virtual platforms, ignore if unreadable
    }

    return file;
  }

  /// Calculates safe GPU decode cache dimensions according to device pixel ratio.
  /// Prevents full uncompressed bitmap allocation in heap memory.
  static int calculateCacheDimension(
    BuildContext context,
    double logicalDimension, {
    int minDimension = 64,
    int maxDimension = 1024,
  }) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final pixelSize = (logicalDimension * dpr).round();
    return pixelSize.clamp(minDimension, maxDimension);
  }
}
