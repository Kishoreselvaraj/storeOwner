import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ✅ Added for reverse geocoding

class CreateStorePage extends StatefulWidget {
  const CreateStorePage({Key? key}) : super(key: key);

  @override
  State<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState extends State<CreateStorePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  LatLng? _pickedLocation;

  /// ✅ Convert LatLng to Address
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Unknown Location";
  }

  /// ✅ Get Current Location
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _pickedLocation = LatLng(position.latitude, position.longitude);
    });

    // ✅ Get actual address
    String address = await _getAddressFromLatLng(position.latitude, position.longitude);
    setState(() {
      _addressController.text = address;
    });
  }

  /// ✅ Open Map in Bottom Sheet
  void _openMapBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        LatLng initialPosition =
            _pickedLocation ?? const LatLng(12.9716, 77.5946); // Default Bangalore
        LatLng? tempLocation = _pickedLocation;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: const Text(
                      "Select Store Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialPosition,
                        zoom: 14,
                      ),
                      onTap: (pos) {
                        setModalState(() => tempLocation = pos);
                      },
                      markers: {
                        if (tempLocation != null)
                          Marker(
                            markerId: const MarkerId("selected"),
                            position: tempLocation!,
                          ),
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: tempLocation == null
                          ? null
                          : () async {
                              setState(() {
                                _pickedLocation = tempLocation;
                              });

                              // ✅ Get actual address for selected point
                              String address = await _getAddressFromLatLng(
                                tempLocation!.latitude,
                                tempLocation!.longitude,
                              );

                              setState(() {
                                _addressController.text = address;
                              });

                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Confirm Location"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ Save Store Data to Realtime Database
  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    // Generate unique store ID
    final storeId = dbRef.push().key;

    final storeData = {
      "storeId": storeId,
      "ownerId": user.uid,
      "storeName": _storeNameController.text.trim(),
      "category": _categoryController.text.trim(),
      "address": _addressController.text.trim(),
      "description": _descController.text.trim(),
      "latitude": _pickedLocation!.latitude,
      "longitude": _pickedLocation!.longitude,
      "createdAt": DateTime.now().toIso8601String(),
    };

    try {
      await dbRef
          .child("Shops")
          .child("Location")
          .child(user.uid)
          .child(storeId!)
          .set(storeData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Store Created Successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Your Store"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
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
                validator: (v) => v!.isEmpty ? "Enter store name" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: "Category (e.g. Grocery, Electronics)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Store Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text("Current Location"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openMapBottomSheet,
                      icon: const Icon(Icons.map),
                      label: const Text("Select on Map"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _saveStore,
                icon: const Icon(Icons.save),
                label: const Text("Save Store"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
