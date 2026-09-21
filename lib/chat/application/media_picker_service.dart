import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../domain/media_policy.dart';

enum MediaPickerSource { gallery, camera }

class PickedMediaFile {
  const PickedMediaFile({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.kind,
    this.sizeBytes,
    this.durationMs,
  });

  final String path;
  final String name;
  final String mimeType;
  final MediaKind kind;
  final int? sizeBytes;
  final int? durationMs;
}

class MediaValidationException implements Exception {
  const MediaValidationException(this.message);

  final String message;

  @override
  String toString() => 'MediaValidationException: $message';
}

abstract interface class MediaPickerService {
  Future<PickedMediaFile?> pickImage({
    MediaPickerSource source = MediaPickerSource.gallery,
  });

  Future<PickedMediaFile?> pickVideo({
    MediaPickerSource source = MediaPickerSource.gallery,
  });
}

class NativeMediaPickerService implements MediaPickerService {
  NativeMediaPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedMediaFile?> pickImage({
    MediaPickerSource source = MediaPickerSource.gallery,
  }) async {
    final imageSource = source == MediaPickerSource.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: imageSource,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } on UnimplementedError {
      throw const MediaValidationException('當前裝置不支援相機拍攝，請選取電腦中的圖片檔案');
    } on UnsupportedError {
      throw const MediaValidationException('當前裝置不支援相機拍攝，請選取電腦中的圖片檔案');
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('not supported') ||
          str.contains('unsupported') ||
          str.contains('unimplemented') ||
          str.contains('camera')) {
        throw const MediaValidationException('當前裝置不支援相機拍攝，請選取電腦中的圖片檔案');
      }
      rethrow;
    }
    if (file == null) return null;

    int? size;
    try {
      size = await file.length();
    } catch (_) {}

    final validation = MediaPolicy.validate(
      path: file.path,
      mimeType: file.mimeType,
      sizeBytes: size,
    );
    if (!validation.isValid) {
      throw MediaValidationException(
        validation.errorMessage ?? '不支援的圖片格式，僅支援 JPG, PNG, GIF, WebP',
      );
    }

    return PickedMediaFile(
      path: file.path,
      name: file.name.isNotEmpty ? file.name : file.path.split('/').last,
      mimeType: validation.mimeType ?? 'image/jpeg',
      kind: validation.kind ?? MediaKind.image,
      sizeBytes: size,
    );
  }

  @override
  Future<PickedMediaFile?> pickVideo({
    MediaPickerSource source = MediaPickerSource.gallery,
  }) async {
    final imageSource = source == MediaPickerSource.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    XFile? file;
    try {
      file = await _picker.pickVideo(
        source: imageSource,
        maxDuration: const Duration(seconds: 60),
      );
    } on UnimplementedError {
      throw const MediaValidationException('當前裝置不支援相機拍攝，請選取電腦中的影片檔案');
    } on UnsupportedError {
      throw const MediaValidationException('當前裝置不支援相機拍攝，請選取電腦中的影片檔案');
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('not supported') ||
          str.contains('unsupported') ||
          str.contains('unimplemented') ||
          str.contains('camera')) {
        throw const MediaValidationException('當前裝置不支援相機拍攝，請選取電腦中的影片檔案');
      }
      rethrow;
    }
    if (file == null) return null;

    int? size;
    try {
      size = await file.length();
    } catch (_) {}

    final validation = MediaPolicy.validate(
      path: file.path,
      mimeType: file.mimeType,
      sizeBytes: size,
    );
    if (!validation.isValid) {
      throw MediaValidationException(
        validation.errorMessage ?? '不支援的影片格式，僅支援 MP4, MOV',
      );
    }

    return PickedMediaFile(
      path: file.path,
      name: file.name.isNotEmpty ? file.name : file.path.split('/').last,
      mimeType: validation.mimeType ?? 'video/mp4',
      kind: validation.kind ?? MediaKind.video,
      sizeBytes: size,
    );
  }
}

class FakeMediaPickerService implements MediaPickerService {
  PickedMediaFile? nextPickedImage;
  PickedMediaFile? nextPickedVideo;
  Object? nextError;

  int pickImageCount = 0;
  int pickVideoCount = 0;

  @override
  Future<PickedMediaFile?> pickImage({
    MediaPickerSource source = MediaPickerSource.gallery,
  }) async {
    pickImageCount++;
    if (nextError != null) {
      final error = nextError!;
      nextError = null;
      throw error;
    }
    return nextPickedImage;
  }

  @override
  Future<PickedMediaFile?> pickVideo({
    MediaPickerSource source = MediaPickerSource.gallery,
  }) async {
    pickVideoCount++;
    if (nextError != null) {
      final error = nextError!;
      nextError = null;
      throw error;
    }
    return nextPickedVideo;
  }
}
