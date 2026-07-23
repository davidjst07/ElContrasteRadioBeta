import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Wrapper compartido para imágenes de red — unifica el placeholder
/// (spinner) y el ícono de error que antes se repetían en cada card.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData errorIcon;
  final double errorIconSize;
  final Color? placeholderBackground;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorIcon = Icons.image_not_supported,
    this.errorIconSize = 50,
    this.placeholderBackground,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: placeholderBackground,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) =>
          Icon(errorIcon, size: errorIconSize),
    );
  }
}
