import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../components/Loader.dart';
import '../../../utils/SizeHelper.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show EagerGestureRecognizer, OneSequenceGestureRecognizer;


class CreateStorePage extends StatefulWidget {
  /// When true, the screen loads existing store data and updates it on save.
  final bool isEdit;

  /// If you store each user's store under a generated id, pass it here.
  /// If you store a single store directly under user.uid, leave this null.

  /// Optionally pass initial data (to skip fetching from DB).
  /// Keys: storeName, upi, address, description, latitude, longitude
  final Map<String, dynamic>? initialData;

  const CreateStorePage({
    Key? key,
    this.isEdit = false,
    this.initialData,
  }) : super(key: key);

  @override
  State<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState extends State<CreateStorePage> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  LatLng? _pickedLocation;
  bool _resolvingAddress = false;

  // Overlay loader
  bool _overlayLoading = false;
  String _overlayMessage = "Loading...";

  // Theme tokens
  final Color _primary = const Color(0xFFFF8A3D); // warm orange
  final Color _peach   = const Color(0xFFFFEFE3); // soft peach
  final Color _textDim = const Color(0xFF8A8A8A);

  // --------------------------- Lifecycle ---------------------------
  @override
  void initState() {
    super.initState();
    _initEditPrefillIfNeeded();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _upiIdController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _initEditPrefillIfNeeded() async {
    if (!widget.isEdit) return;

    // If data is provided, use it. Else fetch from DB.
    if (widget.initialData != null) {
      _applyDataMap(widget.initialData!);
      return;
    }

    _showOverlay(true, "Loading store...");
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Not authenticated";

      final dbRef = FirebaseDatabase.instance.ref()
          .child("Shops")
          .child("Location");

      // If a storeId is used in your structure:
      final snap = (widget.isEdit)
          ? await dbRef.child(user.uid).get()
          : await dbRef.get();

      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        _applyDataMap(data);
      } else {
        // Nothing to prefill; keep empty
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load store: $e")),
        );
      }
    } finally {
      _showOverlay(false);
    }
  }

  void _applyDataMap(Map<String, dynamic> data) {
    _storeNameController.text = (data["storeName"] ?? "").toString();
    _upiIdController.text     = (data["upi"] ?? "").toString();
    _addressController.text   = (data["address"] ?? "").toString();
    _descController.text      = (data["description"] ?? "").toString();

    final lat = (data["latitude"] is num) ? (data["latitude"] as num).toDouble() : null;
    final lng = (data["longitude"] is num) ? (data["longitude"] as num).toDouble() : null;
    if (lat != null && lng != null) {
      _pickedLocation = LatLng(lat, lng);
    }
    setState(() {}); // refresh UI / summary
  }

  void _showOverlay(bool show, [String? message]) {
    setState(() {
      _overlayLoading = show;
      if (message != null) _overlayMessage = message;
    });
  }

  // --------------------------- Address helpers ---------------------------
  String _formatPlacemark(Placemark p) {
    final street = (p.street ?? '').trim();
    final name = (p.name ?? '').trim();
    final parts = <String>[
      if (name.isNotEmpty && name != street) name,
      if (street.isNotEmpty) street,
      if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
      if ((p.subAdministrativeArea ?? '').trim().isNotEmpty)
        p.subAdministrativeArea!.trim(),
      if ((p.administrativeArea ?? '').trim().isNotEmpty)
        p.administrativeArea!.trim(),
      if ((p.postalCode ?? '').trim().isNotEmpty) p.postalCode!.trim(),
      if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
    ];
    return parts.join(', ');
  }

  String? _bestAddressFromPlacemarks(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return null;

    for (final p in placemarks) {
      final addr = _formatPlacemark(p);
      if (addr.isNotEmpty &&
          (((p.street ?? '').isNotEmpty) || ((p.locality ?? '').isNotEmpty))) {
        return addr;
      }
    }
    for (final p in placemarks) {
      final addr = _formatPlacemark(p);
      if (addr.isNotEmpty) return addr;
    }
    return null;
  }

  Future<String> _getReadableAddress(double lat, double lng) async {
    try {
      final a1 = await placemarkFromCoordinates(lat, lng);
      final best1 = _bestAddressFromPlacemarks(a1);
      if (best1 != null && best1.trim().isNotEmpty) return best1;

      for (final d in <int>[6, 5, 4]) {
        final snappedLat = double.parse(lat.toStringAsFixed(d));
        final snappedLng = double.parse(lng.toStringAsFixed(d));
        final a2 = await placemarkFromCoordinates(snappedLat, snappedLng);
        final best2 = _bestAddressFromPlacemarks(a2);
        if (best2 != null && best2.trim().isNotEmpty) return best2;
      }

      if (a1.isNotEmpty) {
        final p = a1.first;
        final coarse = [
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
          if ((p.administrativeArea ?? '').trim().isNotEmpty)
            p.administrativeArea!.trim(),
          if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
        ].join(', ');
        if (coarse.isNotEmpty) return coarse;
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    }
    return "Nearby known area";
  }

  // ------------------------- Location interactions ------------------------
  Future<void> _resolveAndFillAddress(LatLng pos) async {
    _resolvingAddress = true;
    _showOverlay(true, "Resolving address...");
    try {
      final address = await _getReadableAddress(pos.latitude, pos.longitude);
      setState(() => _addressController.text = address);
    } finally {
      _resolvingAddress = false;
      _showOverlay(false);
    }
  }

  Future<void> _getCurrentLocation() async {
    _showOverlay(true, "Getting current location...");
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable location services.")),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final pos = LatLng(position.latitude, position.longitude);
      setState(() => _pickedLocation = pos);
      await _resolveAndFillAddress(pos);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to get current location: $e")),
      );
    } finally {
      _showOverlay(false);
    }
  }

  // ------------------------- Bottom Sheet (themed) ------------------------
  void _openMapBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        LatLng initialPosition =
            _pickedLocation ?? const LatLng(10.9974, 76.9589);
        LatLng? tempLocation = _pickedLocation;
        String? tempAddress;
        bool resolving = false;

        GoogleMapController? _controller;

        Future<void> _resolveTemp(
          LatLng pos,
          void Function(void Function()) setModalState,
        ) async {
          setModalState(() {
            resolving = true;
            tempAddress = null;
          });
          final addr = await _getReadableAddress(pos.latitude, pos.longitude);
          setModalState(() {
            resolving = false;
            tempAddress = addr;
          });
        }

        Future<void> _pickCurrent(
          void Function(void Function()) setModalState,
        ) async {
          try {
            final serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enable location services.")),
              );
              return;
            }
            var permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Location permission denied.")),
              );
              return;
            }
            final p = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            final pos = LatLng(p.latitude, p.longitude);
            setModalState(() => tempLocation = pos);
            _controller?.animateCamera(
              CameraUpdate.newLatLngZoom(pos, 15),
            );
            await _resolveTemp(pos, setModalState);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Unable to get current location: $e")),
            );
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.78,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: SizeHelper.byHeight(context, 10)),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(height: SizeHelper.byHeight(context, 12)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeHelper.byWidth(context, 16),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                "Select Store Location",
                                style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: SizeHelper.byHeight(context, 4)),

                        // Address preview card
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeHelper.byWidth(context, 16),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              SizeHelper.byWidth(context, 12),
                            ),
                            decoration: BoxDecoration(
                              color: _peach,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.place_rounded, color: _primary),
                                SizedBox(width: SizeHelper.byWidth(context, 10)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        resolving
                                            ? "Resolving address…"
                                            : (tempAddress?.trim().isNotEmpty == true
                                                ? tempAddress!.trim()
                                                : (tempLocation == null
                                                    ? "Tap the map to drop a pin"
                                                    : "Nearby known area")),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: SizeHelper.byHeight(context, 4)),
                                      Text(
                                        resolving
                                            ? "Resolving address…"
                                            : (tempAddress?.trim().isNotEmpty == true
                                                ? tempAddress!.trim()            // full, formatted address
                                                : (tempLocation == null
                                                    ? ""                          // nothing until user taps
                                                    : "Nearby known area")),
                                        style: TextStyle(fontSize: 12, color: _textDim),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Quick actions
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeHelper.byWidth(context, 16),
                            vertical: SizeHelper.byHeight(context, 8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickCurrent(setModalState),
                                  icon: const Icon(Icons.my_location_rounded, size: 18),
                                  label: const Text("Use Current"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: SizeHelper.byHeight(context, 12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: SizeHelper.byWidth(context, 10)),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: tempLocation == null
                                      ? null
                                      : () => _controller?.animateCamera(
                                            CameraUpdate.newLatLngZoom(
                                                tempLocation!, 16),
                                          ),
                                  icon: const Icon(Icons.center_focus_strong, size: 18),
                                  label: const Text("Recenter"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: SizeHelper.byHeight(context, 12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Map
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: SizeHelper.byWidth(context, 8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: GoogleMap(
                                onMapCreated: (c) => _controller = c,
                                initialCameraPosition: CameraPosition(target: initialPosition, zoom: 14),
                                onTap: (pos) { setModalState(() => tempLocation = pos); _resolveTemp(pos, setModalState); },
                                markers: {
                                  if (tempLocation != null)
                                    Marker(markerId: const MarkerId("selected"), position: tempLocation!),
                                },
                                myLocationButtonEnabled: false,
                                myLocationEnabled: false,
                                mapToolbarEnabled: false,
                                zoomControlsEnabled: false,

                                // 👇 give the map first dibs on gestures
                                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
                                },
                              ),
                            ),
                          ),
                        ),

                        // Confirm button
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            SizeHelper.byWidth(context, 16),
                            SizeHelper.byHeight(context, 12),
                            SizeHelper.byWidth(context, 16),
                            SizeHelper.byHeight(context, 16),
                          ),
                          child: ElevatedButton(
                            onPressed: tempLocation == null
                                ? null
                                : () async {
                                    setState(() => _pickedLocation = tempLocation);
                                    final addr = tempAddress ??
                                        await _getReadableAddress(
                                          tempLocation!.latitude,
                                          tempLocation!.longitude,
                                        );
                                    setState(() => _addressController.text = addr);
                                    if (mounted) Navigator.pop(context);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              minimumSize: Size(
                                double.infinity,
                                SizeHelper.byHeight(context, 52),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text("Confirm Location"),
                          ),
                        ),
                      ],
                    ),

                    // Inline loader overlay for resolving within sheet
                    if (resolving)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.05),
                          alignment: Alignment.center,
                          child: Loader(message: "Resolving address..."),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------- Save data ------------------------------
  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location")),
      );
      return;
    }

    _showOverlay(true, widget.isEdit ? "Updating store..." : "Creating store...");

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Not authenticated";

      final dbRef = FirebaseDatabase.instance.ref()
          .child("Shops")
          .child("Location");

      final storeData = {
        "storeName": _storeNameController.text.trim(),
        "upi": _upiIdController.text.trim(),
        "address": _addressController.text.trim(),
        "description": _descController.text.trim(),
        "latitude": _pickedLocation!.latitude,
        "longitude": _pickedLocation!.longitude,
        "updatedAt": DateTime.now().toIso8601String(),
      };

      // If your structure uses a storeId node, this will update it.
      if (widget.isEdit) {
        await dbRef.child(user.uid).update(storeData);
      } else {
        // Single store per user (overwrite)
        // If creating, add createdAt only once
        if (!widget.isEdit) {
          storeData["createdAt"] = DateTime.now().toIso8601String();
        }
        await dbRef.set(storeData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEdit
            ? "Store Updated Successfully"
            : "Store Created Successfully")),
      );
      Navigator.pop(context, true); // return success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      _showOverlay(false);
    }
  }

  // ---------------------------------- UI ----------------------------------
  InputDecoration _inputDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(
        horizontal: SizeHelper.byWidth(context, 16),
        vertical: SizeHelper.byHeight(context, 14),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary, width: 1.6),
      ),
      suffixIcon: suffix,
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: SizeHelper.byWidth(context, 40),
        height: SizeHelper.byWidth(context, 40),
        decoration: BoxDecoration(
          color: _peach,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: _primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: TextStyle(color: _textDim)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.black54),
      contentPadding: EdgeInsets.symmetric(
        horizontal: SizeHelper.byWidth(context, 12),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return PreferredSize(
      preferredSize: Size.fromHeight(SizeHelper.byHeight(context, 70)),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeHelper.byWidth(context, 16),
              vertical: SizeHelper.byHeight(context, 10),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Color(0xFFFF8D29), size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeHelper.byWidth(context, 6)),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1F2024),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _resolvingAddress;

    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeHelper.byWidth(context, 16),
        SizeHelper.byHeight(context, 12),
        SizeHelper.byWidth(context, 16),
        SizeHelper.byHeight(context, 24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SizedBox(height: SizeHelper.byHeight(context, 10)),
            TextFormField(
              controller: _storeNameController,
              decoration: _inputDecoration("Store Name"),
              validator: (v) => v!.isEmpty ? "Enter store name" : null,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: SizeHelper.byHeight(context, 12)),
            TextFormField(
              controller: _upiIdController,
              decoration: _inputDecoration("UPI ID (For Payments)"),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: SizeHelper.byHeight(context, 12)),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration(
                "Store Address",
                suffix: busy
                    ? Padding(
                        padding: EdgeInsets.all(SizeHelper.byWidth(context, 10)),
                        child: Loader(message: "Finding address..."),
                      )
                    : const Icon(Icons.edit_location_alt_outlined),
              ),
              maxLines: 2,
            ),
            SizedBox(height: SizeHelper.byHeight(context, 8)),

            // Location actions
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _settingsTile(
                    icon: Icons.my_location_rounded,
                    title: "Use Current Location",
                    subtitle: "Detect and fill address automatically",
                    onTap: busy ? null : _getCurrentLocation,
                    trailing: busy
                        ? SizedBox(
                            height: SizeHelper.byHeight(context, 20),
                            width: SizeHelper.byWidth(context, 20),
                            child: Loader(message: "...")
                          )
                        : null,
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _settingsTile(
                    icon: Icons.map_rounded,
                    title: "Select on Map",
                    subtitle: "Tap a point and confirm",
                    onTap: busy ? null : _openMapBottomSheet,
                  ),
                ],
              ),
            ),

            SizedBox(height: SizeHelper.byHeight(context, 14)),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: _inputDecoration("Description"),
            ),
            SizedBox(height: SizeHelper.byHeight(context, 18)),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : _saveStore,
                icon: const Icon(Icons.save),
                label: Text(widget.isEdit ? "Update Store" : "Save Store"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(
                    double.infinity,
                    SizeHelper.byHeight(context, 52),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, widget.isEdit ? "Edit Store" : "Create Store"),
      body: Stack(
        children: [
          content,
          if (_overlayLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.06),
                alignment: Alignment.center,
                child: Loader(message: _overlayMessage),
              ),
            ),
        ],
      ),
    );
  }
}
