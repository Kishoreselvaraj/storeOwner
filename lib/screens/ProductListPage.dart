import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'AddProductPage.dart';
import 'ProductDetailPage.dart';

class ProductListPage extends StatefulWidget {
  @override
  State createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late DatabaseReference productsRef;
  String searchQuery = '';
  int filterCount = 2; // Example: Number of active filters

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    productsRef = FirebaseDatabase.instance.ref('Shops/user/$userId/products');
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Electronic Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        Text('Available', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  StreamBuilder(
                    stream: productsRef.onValue,
                    builder: (context, AsyncSnapshot snapshot) {
                      int result = 0;
                      if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                        Map productsMap = snapshot.data!.snapshot.value as Map;
                        result = productsMap.length;
                      }
                      return Text('$result results', style: TextStyle(color: Colors.grey[700]));
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
            // Search bar
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
            child: TextField(
              decoration: InputDecoration(
              hintText: 'Fans',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              ),
              onChanged: (v) => setState(() {
              searchQuery = v;
              }),
            ),
            ),
            // Sort and filter row
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            child: Row(
              children: [
              MaterialButton(
                color: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Row(
                children: [
                  Icon(Icons.sort, size: 18),
                  Text('Sort', style: TextStyle(fontSize: 14)),
                ],
                ),
                onPressed: () {
                // Sort logic or dialog
                },
              ),
              SizedBox(width: 10),
              Stack(
                children: [
                MaterialButton(
                  color: Colors.grey[200],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, size: 18),
                    Text('Filter', style: TextStyle(fontSize: 14)),
                  ],
                  ),
                  onPressed: () {
                  // Filter logic or dialog
                  },
                ),
                if (filterCount > 0)
                  Positioned(
                  right: 4,
                  top: 2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.orange,
                    child: Text('$filterCount', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  ),
                ],
              ),
              ],
            ),
            ),
          
          // Products list
          Expanded(
            child: StreamBuilder(
              stream: productsRef.onValue,
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text("No products found"));
                }

                Map productsMap = snapshot.data!.snapshot.value as Map;
                var productsList = productsMap.entries.map((entry) {
                  final value = Map.from(entry.value);
                  return {
                    'id': entry.key,
                    'name': value['name'] ?? '',
                    'description': value['description'] ?? '',
                    'price': value['price'] ?? 0,
                    'available': value['available'] ?? true,
                    'imageUrl': value['imageUrl'] ?? '',
                  };
                }).toList();

                if (searchQuery.isNotEmpty) {
                  productsList = productsList
                      .where((p) => p['name'].toLowerCase().contains(searchQuery.toLowerCase()))
                      .toList();
                }

                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: productsList.length,
                  itemBuilder: (context, index) {
                    final product = productsList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(
                              userId: userId,
                              productId: product['id'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 1.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                              child: product['imageUrl'] != ''
                                  ? Image.network(
                                      product['imageUrl'],
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.image, size: 60, color: Colors.grey),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['name'], style: TextStyle(fontWeight: FontWeight.w600)),
                                  SizedBox(height: 6),
                                  Text("₹${product['price']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Add Products Button (mimicking your image style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Add Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductPage()));
                },
              ),
            ),
          ),
        ],
      ),
      // Bottom nav bar, matching your screenshot
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
          // handle navigation
        },
      ),
    );
  }
}
