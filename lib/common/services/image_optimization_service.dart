import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// On mobile devices (iOS/Android), displays an adaptive bottom sheet
  /// prompting the user to choose between Camera (拍照) and Gallery (從相簿選取).
  /// On desktop (macOS/Windows/Linux) and web, directly opens the gallery/file picker
  /// without popping up the mobile camera option.
  Future<XFile?> showImageSourcePickerAndPick(
    BuildContext context, {
    ImageOptimizationPreset preset = ImageOptimizationPreset.galleryPhoto,
    String title = '上傳寵物生活照',
    bool? isMobileOverride,
  }) async {
    final isMobile = isMobileOverride ?? (!kIsWeb && (Platform.isIOS || Platform.isAndroid));
    if (!isMobile) {
      // Desktop / Web: directly pick from gallery/file selector
      return pickOptimizedImage(source: ImageSource.gallery, preset: preset);
    }

    final source = await showImageSourceActionSheet(context, title: title);
    if (source == null) return null;
    return pickOptimizedImage(source: source, preset: preset);
  }

  /// Displays a modern bottom sheet modal for choosing between Camera and Gallery.
  static Future<ImageSource?> showImageSourceActionSheet(
    BuildContext context, {
    String title = '選擇照片來源',
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffdee2e6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2030),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xffeff2fe),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xff4361ee),
                    size: 22,
                  ),
                ),
                title: const Text(
                  '拍照 (立即拍攝)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  '開啟相機鏡頭，拍攝家中毛孩生活照',
                  style: TextStyle(fontSize: 12, color: Color(0xff6c757d)),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0fdf4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xff16a34a),
                    size: 22,
                  ),
                ),
                title: const Text(
                  '從相簿選取',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  '從手機相簿選取已拍攝的生活美照',
                  style: TextStyle(fontSize: 12, color: Color(0xff6c757d)),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('取消', style: TextStyle(color: Color(0xff6c757d))),
              ),
            ],
          ),
        ),
      ),
    );
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
