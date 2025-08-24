import 'package:flutter/material.dart';
import 'package:store/components/Loader.dart';

class ProductGridCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double price;
  final VoidCallback? onTap;

  /// Look & layout
  final double borderRadius;
  final double elevation;
  final Color backgroundColor;

  /// Total card height (CSS: height: 189px)
  final double cardHeight;

  /// Image area height (inside the card)
  final double imageHeight;

  const ProductGridCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.onTap,
    this.borderRadius = 16,
    this.elevation = 1.5,
    this.backgroundColor = const Color(0xFFF8F9FE), // var(--Neutral-Light-Light)
    this.cardHeight = 189,                           // fixed total height
    this.imageHeight = 110,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final card = Card(
      color: backgroundColor,              // background: #F8F9FE
      shape: RoundedRectangleBorder(borderRadius: radius), // border-radius: 16
      clipBehavior: Clip.antiAlias,        // clip children to rounded corners
      child: Column(                       // display: flex; flex-direction: column
        crossAxisAlignment: CrossAxisAlignment.start, // align-items: flex-start
        children: [
          // Image
          imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: imageHeight,
                      child: const Center(child: Loader()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: imageHeight,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                  ),
                )
              : Container(
                  height: imageHeight,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 60, color: Colors.grey),
                ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF1F2024),
                    ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹ ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2024),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Enforce total height (CSS: height: 189px)
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: cardHeight, // <- adjust this to change total card height
        child: card,
      ),
    );
  }
}
