import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../utils/SizeHelper.dart';
import '../../components/Loader.dart';

class ProductEditPage extends StatefulWidget {
  final String productId;
  const ProductEditPage({super.key, required this.productId});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // state
  bool _loading = true;         // initial load
  bool _saving = false;         // while updating
  bool previewMode = false;     // preview screen
  bool published = false;       // success screen
  bool available = true;

  File? _selectedImage;         // newly picked image
  String? uploadedImageUrl;     // current/existing image url

  // DB
  DatabaseReference? _productRef;

  // ImageKit (keep secret safe in prod)
  final String privateKey = "private_BC0ONkiPUooHCm2mbPwBqk/h29E=";
  final String uploadUrl = "https://upload.imagekit.io/api/v1/files/upload";

  Color get _orange => const Color(0xFFFF8A00);

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in')),
        );
      }
      return;
    }
    _productRef = FirebaseDatabase.instance
        .ref('Shops/user/$uid/products/${widget.productId}');

    try {
      final snap = await _productRef!.get();
      if (!mounted) return;

      if (!snap.exists || snap.value is! Map) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
        return;
      }

      final m = Map<String, dynamic>.from(snap.value as Map);
      _nameCtrl.text = (m['name'] ?? '').toString();
      _descCtrl.text = (m['description'] ?? '').toString();

      final priceRaw = m['price'];
      if (priceRaw is num) {
        _priceCtrl.text = priceRaw.toStringAsFixed(0);
      } else {
        _priceCtrl.text = (double.tryParse('$priceRaw') ?? 0).toStringAsFixed(0);
      }

      uploadedImageUrl = (m['imageUrl'] ?? '').toString();
      available = (m['available'] ?? true) == true;

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ---------- UI helpers ----------
  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE9E9E9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _orange, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
      );

  Widget _availabilityChips() => Row(
        children: [
          ChoiceChip(
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text("AVAILABLE", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            selected: available,
            selectedColor: _orange.withOpacity(.18),
            showCheckmark: false,
            shape: StadiumBorder(
              side: BorderSide(color: available ? _orange : const Color(0xFFE6E6E6)),
            ),
            onSelected: (_) => setState(() => available = true),
            labelStyle: TextStyle(color: available ? _orange : Colors.black87),
            backgroundColor: const Color(0xFFF7F7F7),
          ),
          const SizedBox(width: 12),
          ChoiceChip(
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
              child: Text("OUT OF STOCK", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            selected: !available,
            selectedColor: const Color(0xFFFFF1E3),
            showCheckmark: false,
            shape: StadiumBorder(
              side: BorderSide(color: !available ? _orange : const Color(0xFFE6E6E6)),
            ),
            onSelected: (_) => setState(() => available = false),
            labelStyle: TextStyle(color: !available ? _orange : Colors.black87),
            backgroundColor: const Color(0xFFF7F7F7),
          ),
        ],
      );

  Widget _roundedPreviewImage() {
    const radius = 18.0;
    final url = uploadedImageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _selectedImage != null
            ? Image.file(_selectedImage!, fit: BoxFit.cover)
            : (url != null && url.isNotEmpty)
                ? Image.network(url, fit: BoxFit.cover)
                : Container(color: const Color(0xFFEDEDED)),
      ),
    );
  }

  Widget _buildSavingOverlay() => Positioned.fill(
        child: AbsorbPointer(
          child: Container(
            color: Colors.black.withOpacity(0.15),
            child: const Center(child: Loader(message: 'Saving...')),
          ),
        ),
      );

  // ---------- image pick/upload ----------
  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<String?> uploadImageToImageKit(File file) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      final auth = 'Basic ${base64Encode(utf8.encode('$privateKey:'))}';
      req.headers['Authorization'] = auth;
      req.fields['fileName'] = file.path.split('/').last;
      req.fields['useUniqueFileName'] = 'true';
      req.files.add(await http.MultipartFile.fromPath('file', file.path));
      final resp = await req.send();
      final body = await http.Response.fromStream(resp);
      if (body.statusCode == 200) {
        final json = jsonDecode(body.body);
        return json['url'] as String?;
      }
      debugPrint('Upload failed: ${body.body}');
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ---------- save (update) ----------
  Future<void> saveProduct() async {
    if (_saving || _productRef == null) return;
    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;

      if (name.isEmpty || desc.isEmpty || price <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please complete all fields with valid values.')));
        return;
      }

      String? imageUrl = uploadedImageUrl;
      if (_selectedImage != null) {
        final uploaded = await uploadImageToImageKit(_selectedImage!);
        if (uploaded == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Image upload failed. Try again.')));
          return;
        }
        imageUrl = uploaded;
      }

      await _productRef!.update({
        'name': name,
        'description': desc,
        'price': price,
        'available': available,
        'imageUrl': imageUrl ?? '',
      });

      if (!mounted) return;
      setState(() => published = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // success screen (auto back after 10s)
    if (published) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && published) {
          Navigator.pop(context);
          setState(() => published = false);
        }
      });
      return Scaffold(
        backgroundColor: const Color(0xFFFF8D29),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/product_add/Approval.png', width: 118, height: 118),
              SizedBox(height: SizeHelper.byHeight(context, 62)),
              Text(
                _nameCtrl.text.isNotEmpty ? _nameCtrl.text : "Product",
                style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: SizeHelper.byHeight(context, 9)),
              const Text("Updated!",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: Center(child: Loader(message: 'Loading...'))),
      );
    }

    if (previewMode) {
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final priceStr = _priceCtrl.text.trim();

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  InkWell(
                    onTap: () => setState(() => previewMode = false),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, color: _orange, size: 30),
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
                  _roundedPreviewImage(),
                  const SizedBox(height: 24),
                  Text(
                    name.isEmpty ? "Product" : name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹ $priceStr",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    desc.isEmpty ? "No description available." : desc,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF6C6C6C), height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Stock",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _stockChip(label: "OUT OF STOCK", filled: false, selected: !available, onTap: () {
                        setState(() => available = false);
                      }),
                      const SizedBox(width: 12),
                      _stockChip(label: "AVAILABLE", filled: true, selected: available, onTap: () {
                        setState(() => available = true);
                      }),
                    ],
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: saveProduct,
                      child: const Text(
                        "Update",
                        style:
                            TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
              if (_saving) _buildSavingOverlay(),
            ],
          ),
        ),
      );
    }

    // ---------- EDIT FORM ----------
    return Scaffold(
      appBar: _buildAppBar(context, "Edit Product"),
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  // image box
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          )
                        : (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(uploadedImageUrl!, fit: BoxFit.cover),
                              )
                            : const Center(
                                child: Icon(Icons.image, color: Colors.orange, size: 42),
                              ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload_rounded, size: 22),
                      label: const Text(
                        "Replace Image",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: pickImage,
                    ),
                  ),

                  _sectionTitle("Name of Product"),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _fieldDecoration("Enter product name"),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter product name' : null,
                  ),

                  _sectionTitle("About Product"),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: _fieldDecoration("Product Description"),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
                    maxLines: 4,
                    minLines: 3,
                  ),

                  _sectionTitle("Stock Availability"),
                  _availabilityChips(),

                  _sectionTitle("Price"),
                  TextFormField(
                    controller: _priceCtrl,
                    decoration: _fieldDecoration("Enter price").copyWith(
                      prefixText: "₹ ",
                      prefixStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter price' : null,
                  ),
                ],
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => previewMode = true);
                        }
                      },
                      child: const Text(
                        "Preview",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
              if (_saving) _buildSavingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // preview chip
  Widget _stockChip({
    required String label,
    required bool filled,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final bool isFilledAndSelected = filled && selected;
    final lightPeach = const Color(0xFFFFE7D1);
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isFilledAndSelected ? _orange : lightPeach,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isFilledAndSelected ? Colors.white : _orange,
          letterSpacing: 0.5,
        ),
      ),
    );
    return GestureDetector(onTap: onTap, child: child);
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) => PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
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
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2024))),
                ],
              ),
            ),
          ),
        ),
      );
}
