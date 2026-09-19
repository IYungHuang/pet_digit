enum MediaKind { image, video }

class MediaPolicy {
  const MediaPolicy._();

  static const imageMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  };

  static const videoMimeTypes = <String>{
    'video/mp4',
    'video/quicktime',
  };

  static bool isSupportedMimeType(String mimeType) {
    final normalized = mimeType.trim().toLowerCase();
    return imageMimeTypes.contains(normalized) ||
        videoMimeTypes.contains(normalized);
  }

  static MediaKind? kindForMimeType(String mimeType) {
    final normalized = mimeType.trim().toLowerCase();
    if (imageMimeTypes.contains(normalized)) return MediaKind.image;
    if (videoMimeTypes.contains(normalized)) return MediaKind.video;
    return null;
  }

  static MediaKind? kindForExtension(String pathOrExtension) {
    final normalized = pathOrExtension.trim().toLowerCase();
    final extension = normalized.startsWith('.')
        ? normalized.substring(1)
        : normalized.split('.').last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return MediaKind.image;
      case 'mp4':
      case 'mov':
        return MediaKind.video;
      default:
        return null;
    }
  }

  static String? mimeTypeForPath(String pathOrExtension) {
    final normalized = pathOrExtension.trim().toLowerCase();
    final extension = normalized.startsWith('.')
        ? normalized.substring(1)
        : normalized.split('.').last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return null;
    }
  }

  static MediaValidationResult validate({
    required String path,
    String? mimeType,
    int? maxSizeBytes,
  }) {
    final effectiveMime = (mimeType != null && mimeType.trim().isNotEmpty)
        ? mimeType.trim().toLowerCase()
        : mimeTypeForPath(path);

    if (effectiveMime == null || !isSupportedMimeType(effectiveMime)) {
      return const MediaValidationResult.invalid(
        errorMessage: '不支援的檔案格式，僅支援 JPG, PNG, GIF, WebP 圖片與 MP4, MOV 影片',
      );
    }

    final kind = kindForMimeType(effectiveMime);
    if (kind == null) {
      return const MediaValidationResult.invalid(
        errorMessage: '不支援的媒體類型',
      );
    }

    return MediaValidationResult.valid(
      kind: kind,
      mimeType: effectiveMime,
    );
  }
}

class MediaValidationResult {
  const MediaValidationResult.valid({
    required this.kind,
    required this.mimeType,
  })  : isValid = true,
        errorMessage = null;

  const MediaValidationResult.invalid({
    required this.errorMessage,
  })  : isValid = false,
        kind = null,
        mimeType = null;

  final bool isValid;
  final MediaKind? kind;
  final String? mimeType;
  final String? errorMessage;
}

