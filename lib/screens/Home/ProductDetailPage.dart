import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../components/Home/floating_bottom_button.dart';
import './ProductEditPage.dart';

class ProductDetailPage extends StatefulWidget {
  final String userId;
  final String productId;

  const ProductDetailPage({
    Key? key,
    required this.userId,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  static const Color _orange = Color(0xFFFF8D29);
  bool _saving = false; // for optional overlay

  @override
  Widget build(BuildContext context) {
    final DatabaseReference productRef = FirebaseDatabase.instance
        .ref('Shops/user/${widget.userId}/products/${widget.productId}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: productRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data?.snapshot.value;
            if (data == null || data is! Map) {
              return const Center(child: Text("Product not found"));
            }
            final product = Map<String, dynamic>.from(data);

            final String name = (product['name'] ?? '').toString();
            final String desc = (product['description'] ?? 'No description available.').toString();
            final bool available = (product['available'] ?? true) == true;

            // price can be int/double/string; normalize to string
            final dynamic priceRaw = product['price'];
            String priceStr;
            if (priceRaw is num) {
              priceStr = priceRaw.toStringAsFixed(priceRaw is int ? 0 : 0);
            } else {
              priceStr = (double.tryParse('$priceRaw') ?? 0).toStringAsFixed(0);
            }

            return Stack(
              children: [
                // Main scrollable content
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    // Back row (custom, not AppBar)
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left, color: _orange, size: 30),
                          const SizedBox(width: 6),
                          const Text(
                            "Back",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2024),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rounded preview image (single image)
                    _roundedPreviewImage(product['imageUrl'] as String?),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      name.isEmpty ? "Amazing Fan" : name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price
                    Text(
                      "₹ $priceStr",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text(
                      desc.isEmpty
                          ? "No description available."
                          : desc,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6C6C6C),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      "Stock",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stock chips (left: OUT OF STOCK, right: AVAILABLE)
                    Row(
                      children: [
                        _stockChip(
                          label: "OUT OF STOCK",
                          filled: false,
                          selected: !available,
                          onTap: null, // read-only here; hook up if you want to edit
                        ),
                        const SizedBox(width: 12),
                        _stockChip(
                          label: "AVAILABLE",
                          filled: true,
                          selected: available,
                          onTap: null, // read-only
                        ),
                      ],
                    ),
                  ],
                ),

                // Sticky bottom "Edit" button (template style)
                // Sticky bottom "Edit" button (template style)
                FloatingBottomButton(
                  label: 'Edit',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductEditPage(
                          productId: widget.productId, // ✅ pass the real id
                        ),
                      ),
                    );
                  },
                  // If your FloatingBottomButton requires extraBottom, uncomment:
                  // extraBottom: (MediaQuery.of(context).viewInsets.bottom > 0) ? 12 : 12,
                ),


                if (_saving) _buildSavingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- helpers ----------

  Widget _roundedPreviewImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            )
          : Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 80, color: Colors.black38),
            ),
    );
  }

  Widget _stockChip({
    required String label,
    required bool filled,
    required bool selected,
    VoidCallback? onTap,
  }) {
    final bg = filled
        ? (selected ? _orange : const Color(0xFFFFE1C6))
        : Colors.transparent;
    final border = filled
        ? Colors.transparent
        : (selected ? _orange : const Color(0xFFE0E0E0));
    final fg = filled
        ? (selected ? Colors.white : _orange)
        : (selected ? _orange : const Color(0xFF6C6C6C));

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    return onTap == null
        ? child
        : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: child);
  }

  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black38,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 12),
            Text(
              "Saving...",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
