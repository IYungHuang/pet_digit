import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../common/services/image_optimization_service.dart';
import '../../../pet/domain/pet_profile.dart';

/// Reusable widget for displaying pet avatar from local file, network URL, or assets.
class PetAvatarWidget extends StatelessWidget {
  const PetAvatarWidget({
    super.key,
    required this.avatarUrl,
    required this.species,
    this.size = 48,
    this.borderRadius = 14,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  final String avatarUrl;
  final PetSpecies species;
  final double size;
  final double borderRadius;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    Widget imageContent;
    final cacheDim = ImageOptimizationService.calculateCacheDimension(context, size);

    final trimmed = avatarUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      imageContent = Image.network(
        trimmed,
        width: size,
        height: size,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xff4361ee),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else if (trimmed.startsWith('assets/') || trimmed.startsWith('asset:')) {
      final assetPath = trimmed.replaceFirst('asset:', '');
      imageContent = Image.asset(
        assetPath,
        width: size,
        height: size,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else if (trimmed.isNotEmpty && !kIsWeb && File(trimmed).existsSync()) {
      imageContent = Image.file(
        File(trimmed),
        width: size,
        height: size,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else {
      imageContent = _buildFallback();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xffeff2fe),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: borderColor ?? const Color(0xff4361ee),
                width: borderWidth,
              )
            : Border.all(color: const Color(0xffe9ecef), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageContent,
    );
  }

  Widget _buildFallback() {
    final emoji = switch (species) {
      PetSpecies.dog => '🐕',
      PetSpecies.cat => '🐱',
      PetSpecies.parrot => '🦜',
    };
    return Center(
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.48),
      ),
    );
  }
}
