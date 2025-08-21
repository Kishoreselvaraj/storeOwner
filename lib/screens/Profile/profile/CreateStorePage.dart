import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CreateStorePage extends StatefulWidget {
  const CreateStorePage({super.key});

  @override
  State<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState extends State<CreateStorePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  LatLng? _pickedLocation;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick store location on map")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storeId = FirebaseFirestore.instance.collection("shops").doc().id;

    final storeData = {
      "storeId": storeId,
      "ownerId": user.uid,
      "storeName": _storeNameController.text.trim(),
      "upiId": _upiIdController.text.trim(),
      "phone": _phoneController.text.trim(),
      "description": _descController.text.trim(),
      "category": _categoryController.text.trim(),
      "address": _addressController.text.trim(),
      "latitude": _pickedLocation!.latitude,
      "longitude": _pickedLocation!.longitude,
      "createdAt": FieldValue.serverTimestamp(),
    };

    // Save globally
    await FirebaseFirestore.instance.collection("shops").doc(storeId).set(storeData);

    // Save under user’s profile
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("storeDetails")
        .doc(storeId)
        .set(storeData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Store created successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Store")),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _currentLocation!, zoom: 15),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _pickedLocation != null
                        ? {
                            Marker(
                              markerId: const MarkerId("picked"),
                              position: _pickedLocation!,
                            ),
                          }
                        : {},
                    onTap: (pos) {
                      setState(() => _pickedLocation = pos);
                    },
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _storeNameController,
                            decoration: const InputDecoration(
                              labelText: "Store Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter store name" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: "Category (e.g. Electronics, Grocery)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "Phone Number",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _upiIdController,
                            decoration: const InputDecoration(
                              labelText: "UPI ID",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: "Address",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "Store Description",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _saveStore,
                            icon: const Icon(Icons.save),
                            label: const Text("Save Store"),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
