// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../Profile/profile/CreateStorePage.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   final user = FirebaseAuth.instance.currentUser;
//   DatabaseReference? userRef;

//   @override
//   void initState() {
//     super.initState();
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid != null && uid.isNotEmpty) {
//       userRef = FirebaseDatabase.instance.ref('Shops/user/$uid');
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFFFFFFF),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         title: const Text("Profile", style: TextStyle(color: Colors.black)),
//       ),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('stores') // Firestore collection for shops
//             .doc(user?.uid)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

//           return SingleChildScrollView(
//             child: Column(
//               children: [
//                 const SizedBox(height: 20),
//                 // Profile Avatar
//                 CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.orange.shade100,
//                   child: const Icon(Icons.person, size: 50, color: Colors.orange),
//                 ),
//                 const SizedBox(height: 10),

//                 // Store/Owner Name
//                 Text(
//                   data['storeName'] ?? user?.displayName ?? 'No Name',
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 5),

//                 // Phone / Email
//                 Text(
//                   data['phone'] ?? user?.phoneNumber ?? user?.email ?? 'N/A',
//                   style: TextStyle(color: Colors.grey.shade600),
//                 ),
//                 const SizedBox(height: 20),

//                 // Stats Box
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 20),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       _statCard("Booked", data['booked'] ?? 0),
//                       _statCard("Earnings", "₹${data['earnings'] ?? 0}"),
//                       _statCard("Pending", "₹${data['pending'] ?? 0}"),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 15),

//                 // UPI ID
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Row(
//                     children: [
//                       const Text("UPI ID: ",
//                           style: TextStyle(fontWeight: FontWeight.bold)),
//                       Text(
//                         data['upiId'] ?? "Not set",
//                         style: const TextStyle(color: Colors.orange),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Menu Options
//                 _menuTile(Icons.history, "History", () {
//                   // navigate to history page
//                 }),
//                 _menuTile(Icons.account_balance_wallet, "Update Account", () {
//                   // navigate to bank/upi details update
//                 }),
//                 _menuTile(Icons.store_mall_directory, "Create Store", () {
//                   Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const CreateStorePage()),
//                   );
//                 }),

//                 _menuTile(Icons.notifications, "Notifications", () {
//                   // notifications page
//                 }),
//                 _menuTile(Icons.color_lens, "Appearance", () {
//                   // appearance settings
//                 }),
//                 _menuTile(Icons.lock, "Privacy & Security", () {
//                   // privacy settings
//                 }),
//                 _menuTile(Icons.logout, "Logout", () {
//                   FirebaseAuth.instance.signOut();
//                 }),

//                 const SizedBox(height: 30),
//               ],
//             ),
//           );
//         },
//       ),
//       // Bottom Navigation Bar
      
//     );
//   }

//   Widget _statCard(String title, dynamic value) {
//     return Column(
//       children: [
//         Text(
//           "$value",
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 5),
//         Text(title, style: const TextStyle(color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.orange),
//       title: Text(title),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: onTap,
//     );
//   }
// }







import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:store/components/Loader.dart';
import '../Profile/profile/CreateStorePage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final User? _authUser;
  late final String? _uid;

  @override
  void initState() {
    super.initState();
    _authUser = FirebaseAuth.instance.currentUser;
    _uid = _authUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your profile')),
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('stores')
            .doc(_uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: Loader());
          }

          // If no store doc yet → show empty state + Create Store CTA
          if (!snap.hasData || !(snap.data!.exists)) {
            return _EmptyStoreState(onCreate: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateStorePage()),
              );
            });
          }

          final data = snap.data!.data()!;
          final storeName =
              (data['storeName'] as String?) ??
              (_authUser?.displayName) ??
              'No Name';
          final contact =
              (data['phone'] as String?) ??
              (_authUser?.phoneNumber) ??
              (_authUser?.email) ??
              'N/A';
          final upiId = (data['upiId'] as String?) ?? 'Not set';

          final booked = (data['booked'] ?? 0) as num;
          final earnings = (data['earnings'] ?? 0) as num;
          final pending = (data['pending'] ?? 0) as num;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.person, size: 50, color: Colors.orange),
                ),
                const SizedBox(height: 10),

                Text(
                  storeName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),

                Text(
                  contact,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
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
                      _statCard("Booked", '$booked'),
                      _statCard("Earnings", '₹$earnings'),
                      _statCard("Pending", '₹$pending'),
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
                      Text(upiId, style: const TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Menu
                _menuTile(Icons.history, "History", () {
                  // TODO: navigate to history page
                }),
                _menuTile(Icons.account_balance_wallet, "Update Account", () {
                  // TODO: navigate to bank/upi details update
                }),
                _menuTile(Icons.store_mall_directory, "Create Store", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateStorePage()),
                  );
                }),
                _menuTile(Icons.notifications, "Notifications", () {}),
                _menuTile(Icons.color_lens, "Appearance", () {}),
                _menuTile(Icons.lock, "Privacy & Security", () {}),
                _menuTile(Icons.logout, "Logout", () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.of(context).pop();
                }),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Column(
      children: [
        Text(
          value,
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

/// Empty state shown when there is no `stores/{uid}` document yet.
class _EmptyStoreState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyStoreState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_mall_directory, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'No store found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your store to start receiving bookings and payments.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Store'),
            ),
          ],
        ),
      ),
    );
  }
}
