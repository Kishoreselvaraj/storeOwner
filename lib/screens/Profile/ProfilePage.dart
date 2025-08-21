import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Profile/profile/CreateStorePage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stores') // Firestore collection for shops
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.person, size: 50, color: Colors.orange),
                ),
                const SizedBox(height: 10),

                // Store/Owner Name
                Text(
                  data['storeName'] ?? user?.displayName ?? 'No Name',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),

                // Phone / Email
                Text(
                  data['phone'] ?? user?.phoneNumber ?? user?.email ?? 'N/A',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // Stats Box
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statCard("Booked", data['booked'] ?? 0),
                      _statCard("Earnings", "₹${data['earnings'] ?? 0}"),
                      _statCard("Pending", "₹${data['pending'] ?? 0}"),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // UPI ID
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text("UPI ID: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        data['upiId'] ?? "Not set",
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Menu Options
                _menuTile(Icons.history, "History", () {
                  // navigate to history page
                }),
                _menuTile(Icons.account_balance_wallet, "Update Account", () {
                  // navigate to bank/upi details update
                }),
                _menuTile(Icons.store_mall_directory, "Create Store", () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateStorePage()),
                  );
                }),

                _menuTile(Icons.notifications, "Notifications", () {
                  // notifications page
                }),
                _menuTile(Icons.color_lens, "Appearance", () {
                  // appearance settings
                }),
                _menuTile(Icons.lock, "Privacy & Security", () {
                  // privacy settings
                }),
                _menuTile(Icons.logout, "Logout", () {
                  FirebaseAuth.instance.signOut();
                }),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      // Bottom Navigation Bar
      
    );
  }

  Widget _statCard(String title, dynamic value) {
    return Column(
      children: [
        Text(
          "$value",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
