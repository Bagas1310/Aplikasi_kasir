import 'dart:io';
import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imagePath;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;

  const ProductImageWidget({
    super.key,
    required this.imagePath,
    this.size = 56,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.inventory_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final file = (imagePath != null && imagePath!.isNotEmpty) ? File(imagePath!) : null;
    final exists = file != null && file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFF1F5F9),
        child: exists
            ? Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        fallbackIcon,
        color: const Color(0xFF94A3B8),
        size: size * 0.45,
      ),
    );
  }
}
