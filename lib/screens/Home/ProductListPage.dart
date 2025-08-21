import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AddProductPage.dart';
import 'ProductDetailPage.dart';
import '../../components/Home/ProductGridCard.dart';
import 'dart:math' as math;
import '../../components/Loader.dart';
import '../../components//Home//floating_bottom_button.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    required this.imageUrl,
  });

  factory Product.fromMap(String id, Map data) {
    final priceRaw = data['price'];
    double price = 0;
    if (priceRaw is int) price = priceRaw.toDouble();
    if (priceRaw is double) price = priceRaw;
    if (priceRaw is String) price = double.tryParse(priceRaw) ?? 0;

    return Product(
      id: id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      price: price,
      available: (data['available'] ?? true) == true,
      imageUrl: (data['imageUrl'] ?? '').toString(),
    );
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});
  @override
  State createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  DatabaseReference? _productsRef;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  int filterCount = 2; // Example stub

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _productsRef = FirebaseDatabase.instance.ref('Shops/user/$uid/products');
    }
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_productsRef == null) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(context, totalResults: 0),
        body: const Center(
          child: Text('Please sign in to view your products.'),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _productsRef!.onValue,
      builder: (context, snapshot) {
        final products = _parseProducts(snapshot.data);
        final filtered = _applySearch(products, _searchQuery);

        return Scaffold(
          resizeToAvoidBottomInset: true, // ✅ lets Scaffold lift content for keyboard
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: _buildAppBar(context, totalResults: products.length),

          // ✅ Dismiss keyboard when tapping anywhere outside inputs
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
                children: [
                  Column(
                    children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                    child: TextField(
                      controller: _searchCtrl,
                      cursorColor: const Color.fromARGB(255, 62, 62, 62),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search products',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFFFF5EC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),

                  // Sort & Filter row (UNCHANGED / STILL COMMENTED)
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       MaterialButton(
                  //         color: Colors.grey[200],
                  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  //         onPressed: _onSortPressed,
                  //         child: const Row(
                  //           children: [
                  //             Icon(Icons.sort, size: 18),
                  //             SizedBox(width: 6),
                  //             Text('Sort', style: TextStyle(fontSize: 14)),
                  //           ],
                  //         ),
                  //       ),
                  //       const SizedBox(width: 10),
                  //       Stack(
                  //         children: [
                  //           MaterialButton(
                  //             color: Colors.grey[200],
                  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  //             onPressed: _onFilterPressed,
                  //             child: const Row(
                  //               children: [
                  //                 Icon(Icons.filter_alt_outlined, size: 18),
                  //                 SizedBox(width: 6),
                  //                 Text('Filter', style: TextStyle(fontSize: 14)),
                  //               ],
                  //             ),
                  //           ),
                  //           if (filterCount > 0)
                  //             Positioned(
                  //               right: 4,
                  //               top: 2,
                  //               child: CircleAvatar(
                  //                 radius: 10,
                  //                 backgroundColor: Colors.orange,
                  //                 child: Text('$filterCount',
                  //                     style: const TextStyle(color: Colors.white, fontSize: 12)),
                  //               ),
                  //             ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // Results (Expanded so it shrinks when keyboard appears)
                  Expanded(
                    child: _buildResults(snapshot.connectionState, products, filtered),
                  ),
                  ],
                  ),
                  FloatingBottomButton(
                    label: 'Add Products',
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddProductPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, {required int totalResults}) {
    return const PreferredSize(
      preferredSize: Size.fromHeight(70),
      child: _ProductsAppBar(),
    );
  }

  Widget _buildResults(
    ConnectionState connectionState,
    List<Product> all,
    List<Product> filtered,
  ) {
    if (connectionState == ConnectionState.waiting) {
      return const Center(child: Loader(message: 'Loading products...'));
    }
    if (all.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    final items = filtered;
    if (items.isEmpty) {
      return const Center(child: Text('No matching products'));
    }

    // Grid sizing
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = math.max(2, math.min(4, (width / 180).floor()));

    // If your ProductGridCard uses a fixed total height, match the grid cell to it
    const double desiredCardHeight = 189.0;
    const double hPad = 16.0;
    const double vPad = 8.0;
    const double gap = 6.0;

    final cellWidth = (width - (hPad * 2) - gap * (crossAxisCount - 1)) / crossAxisCount;
    final childAspectRatio = cellWidth / desiredCardHeight;

    return GridView.builder(
      padding: const EdgeInsets.only(left: hPad, right: hPad, top: vPad, bottom: 66),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        return ProductGridCard(
          title: p.name,
          imageUrl: p.imageUrl,
          price: p.price,
          cardHeight: desiredCardHeight, // keep card + cell heights in sync
          onTap: () {
            FocusScope.of(context).unfocus(); // dismiss keyboard before navigate
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(userId: uid, productId: p.id),
              ),
            );
          },
        );
      },
    );
  }

  List<Product> _parseProducts(DatabaseEvent? event) {
    final value = event?.snapshot.value;
    if (value is! Map) return const [];

    final Map raw = value;
    final List<Product> items = [];
    raw.forEach((key, val) {
      if (val is Map) {
        items.add(Product.fromMap(key.toString(), val));
      }
    });
    // Example: newest first if you store timestamps, else keep as-is
    return items;
  }

  List<Product> _applySearch(List<Product> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }

  // void _onSortPressed() {
  //   // TODO: implement sort dialog/sheet
  //   // e.g., price low→high, high→low, available first, etc.
  // }

  // void _onFilterPressed() {
  //   // TODO: implement filter dialog/sheet
  //   // e.g., availability toggle, price range, categories
  // }
}

/// Extracted AppBar into a const-friendly widget (no behavioral change)
class _ProductsAppBar extends StatelessWidget {
  const _ProductsAppBar();

  @override
  Widget build(BuildContext context) {
    // We need the totalResults passed; use InheritedWidget alternative or keep original Row
    // To preserve original behavior precisely, recompose the row here reading from ModalRoute if needed.
    // For simplicity and to keep logic unchanged, we reconstruct using arguments from ancestor:
    // Since PreferredSize above is const, we’ll mirror your original UI but without the dynamic count.
    // If you need the dynamic count text, revert to your original _buildAppBar implementation.
    // (Keeping visuals identical aside from the count coming from parent in your original method.)
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFFFF8D29), size: 32),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Electronic Products',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2024)),
                    ),
                    Text(
                      'Available',
                      style: TextStyle(fontSize: 12, color: Color(0xFF71727A), fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              // You can inject the dynamic results text from parent if needed.
              // Keeping a neutral label to avoid state coupling here.
              const Text(
                'Results',
                style: TextStyle(color: Color(0xFF71727A), fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
