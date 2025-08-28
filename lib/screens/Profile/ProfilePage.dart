import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:store/components/Loader.dart';
import '../Profile/profile/CreateStorePage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  DatabaseReference get _userRef =>
      FirebaseDatabase.instance.ref('Shops/user/${user?.uid ?? "_"}');

  DatabaseReference get _storeRef =>
      FirebaseDatabase.instance.ref('Shops/Location/${user?.uid ?? "_"}');

  // helpers
  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
      ),

      // Read both: Shops/user/<uid> + Shops/Location/<uid>
      body: StreamBuilder<DatabaseEvent>(
        stream: _userRef.onValue,
        builder: (context, userSnap) {
          final userMap = (userSnap.data?.snapshot.value is Map)
              ? Map<String, dynamic>.from(
                  userSnap.data!.snapshot.value as Map)
              : <String, dynamic>{};

          return StreamBuilder<DatabaseEvent>(
            stream: _storeRef.onValue,
            builder: (context, storeSnap) {
              if (userSnap.connectionState == ConnectionState.waiting ||
                  storeSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: Loader());
              }

              final storeExists = storeSnap.data?.snapshot.exists == true;
              final rawStore = (storeSnap.data?.snapshot.value is Map)
                  ? Map<String, dynamic>.from(
                      storeSnap.data!.snapshot.value as Map)
                  : <String, dynamic>{};

              // Normalize to the keys CreateStorePage expects
              final normalizedStore = {
                "storeName": (rawStore["storeName"] ?? "").toString(),
                "upi": (rawStore["upi"] ?? rawStore["upiId"] ?? "").toString(),
                "address": (rawStore["address"] ?? "").toString(),
                "description": (rawStore["description"] ?? "").toString(),
                "latitude": _toDouble(rawStore["latitude"]),
                "longitude": _toDouble(rawStore["longitude"]),
                "booked": rawStore["booked"] ?? 0,
                "earnings": rawStore["earnings"] ?? 0,
                "pending": rawStore["pending"] ?? 0,
              };

              // UI fields
              final displayName =
                  normalizedStore["storeName"]!.toString().isNotEmpty
                      ? normalizedStore["storeName"]!.toString()
                      : (userMap["name"] ??
                          user?.displayName ??
                          "No Name").toString();

              final contactLine =
                  (userMap["mobile"] ??
                          user?.phoneNumber ??
                          userMap["email"] ??
                          user?.email ??
                          "N/A")
                      .toString();

              final upiText =
                  (normalizedStore["upi"] as String).isNotEmpty
                      ? normalizedStore["upi"] as String
                      : "Not set";

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.person,
                          size: 50, color: Colors.orange),
                    ),
                    const SizedBox(height: 10),

                    // Store/Owner Name
                    Text(displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),

                    // Phone / Email
                    Text(contactLine,
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 20),

                    // Stats
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
                          _statCard("Booked", normalizedStore['booked'] ?? 0),
                          _statCard("Earnings",
                              "₹${normalizedStore['earnings'] ?? 0}"),
                          _statCard("Pending",
                              "₹${normalizedStore['pending'] ?? 0}"),
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
                          Text(upiText,
                              style: const TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Menu
                    _menuTile(Icons.history, "History", () {
                      // TODO: navigate to history
                    }),
                    _menuTile(Icons.account_balance_wallet, "Update Account",
                        () {
                      // TODO: bank/UPI settings
                    }),

                    // Create / Edit Store
                    _menuTile(Icons.store_mall_directory,
                        storeExists ? "Edit Store" : "Create Store", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateStorePage(
                            isEdit: storeExists,
                            // pass initialData only if exists
                            initialData: storeExists ? normalizedStore : null,
                            // If your CreateStorePage also accepts storeId, pass uid
                            // storeId: user!.uid,
                          ),
                        ),
                      );
                    }),

                    _menuTile(Icons.notifications, "Notifications", () {}),
                    _menuTile(Icons.color_lens, "Appearance", () {}),
                    _menuTile(Icons.lock, "Privacy & Security", () {}),
                    _menuTile(Icons.logout, "Logout", () {
                      FirebaseAuth.instance.signOut();
                    }),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
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
