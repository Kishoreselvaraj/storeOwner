import 'package:flutter/material.dart';
import '../../utils/SizeHelper.dart'; // ← adjust path if needed

class ProductsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int totalResults;
  final VoidCallback? onBack;

  const ProductsAppBar({
    super.key,
    required this.totalResults,
    this.title = 'Booking',
    this.onBack,
  });

  // AppBar needs a constant preferred height (no BuildContext here).
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    double w(double v) => SizeHelper.byWidth(context, v);
    double h(double v) => SizeHelper.byHeight(context, v);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: Padding(
        padding: EdgeInsets.only(left: w(4)),
        child: IconButton(
          icon: Icon(Icons.chevron_left, color: const Color(0xFFFF8D29), size: w(28)),
          onPressed: onBack ?? () => Navigator.maybePop(context),
        ),
      ),
      title: Padding(
        padding: EdgeInsets.only(left: w(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF1F2024),
              ),
            ),
            if (totalResults > 0) SizedBox(height: h(2)),
            if (totalResults > 0)
              const Text(
                'Available',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF71727A),
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
      actions: [
        Center(
          child: Padding(
            padding: EdgeInsets.only(right: w(16)),
            child: Text(
              '${totalResults} results',
              style: const TextStyle(
                color: Color(0xFF71727A),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
