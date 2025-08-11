import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ProductDetailPage extends StatelessWidget {
  final String userId;
  final String productId;

  const ProductDetailPage({
    Key? key,
    required this.userId,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DatabaseReference productRef =
        FirebaseDatabase.instance.ref('Shops/user/$userId/products/$productId');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder(
        stream: productRef.onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(child: Text("Product not found"));
          }

          final product = Map.from(snapshot.data!.snapshot.value as Map);

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 60, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Product Image Carousel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: product['imageUrl'] != ''
                          ? Image.network(
                              product['imageUrl'],
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: double.infinity,
                              height: 180,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, size: 80),
                            ),
                    ),
                    SizedBox(height: 24),

                    // Product Name & Price
                    Text(
                      product['name'] ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "₹${product['price']}",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 18),

                    // Description (use a sample description if none found)
                    Text(
                      product['description'] ?? "No description available.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Stock status chips
                    Text("Stock", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (product['available'] == false || product['available'].toString().toLowerCase() == 'false')
                          Chip(
                            label: Text('OUT OF STOCK', style: TextStyle(color: Colors.orange)),
                            backgroundColor: Colors.orange[50],
                          ),
                        if (product['available'] == true || product['available'].toString().toLowerCase() == 'true')
                          Chip(
                            label: Text('AVAILABLE', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Custom Back Arrow
              Positioned(
                top: 24,
                left: 12,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
              ),
              // Edit Button at bottom
              Positioned(
                bottom: 18,
                left: 24,
                right: 24,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Edit",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () {
                      // Navigate to edit screen
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductPage(...)));
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Bottom navigation bar to match design
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Home selected
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onTap: (idx) {
          // handle navigation as needed
        },
      ),
    );
  }
}
