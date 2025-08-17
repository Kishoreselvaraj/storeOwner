import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../components/Loader.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? uploadedImageUrl;
  String name = '';
  String desc = '';
  int price = 0;
  bool available = true;
  bool previewMode = false;
  bool published = false;

  // ImageKit configuration (NOTE: keep private key safe in production!)
  final String privateKey = "private_BC0ONkiPUooHCm2mbPwBqk/h29E="; // <--- change yours
  final String uploadUrl = "https://upload.imagekit.io/api/v1/files/upload";

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
  }

  Future<void> pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Optional: counts shown under the images
int photoCount = 5;
int videoCount = 1;

Color get _orange => const Color(0xFFFF8A00);

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
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
}

Widget _sectionTitle(String text) => Padding(
  padding: const EdgeInsets.only(top: 22, bottom: 10),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
  ),
);

// Rounded image with indicators (uses _selectedImage & _orange)
Widget _roundedPreviewImage() {
  const double radius = 18;
  return Stack(
    alignment: Alignment.bottomCenter,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _selectedImage != null
              ? Image.file(_selectedImage!, fit: BoxFit.cover)
              : Container(color: const Color(0xFFEDEDED)),
        ),
      ),
      // Dot indicators (static look to match mock)
      // Padding(
      //   padding: const EdgeInsets.only(bottom: 12),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: List.generate(5, (i) {
      //       final bool active = i == 1; // second dot active (like screenshot)
      //       return Container(
      //         margin: const EdgeInsets.symmetric(horizontal: 4),
      //         width: 8,
      //         height: 8,
      //         decoration: BoxDecoration(
      //           shape: BoxShape.circle,
      //           color: active
      //               ? _orange
      //               : Colors.white.withOpacity(0.85),
      //         ),
      //       );
      //     }),
      //   ),
      // ),
    ],
  );
}

// Pill chip used for Stock
Widget _stockChip({
  required String label,
  required bool filled,
  required bool selected,
  required VoidCallback onTap,
}) {
  final bool isFilledAndSelected = filled && selected;
  final Color lightPeach = const Color(0xFFFFE7D1); // soft bg like mock

  return GestureDetector(
    onTap: onTap,
    child: Container(
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
    ),
  );
}


Widget _availabilityChips() {
  return Row(
    children: [
      ChoiceChip(
        label: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text("AVAILABLE",
              style: TextStyle(
                fontWeight: FontWeight.w600
              )),
        ),
        selected: available,
        selectedColor: _orange.withOpacity(.18),
        showCheckmark: false,
        shape: StadiumBorder(
          side: BorderSide(
              color: available ? _orange : const Color(0xFFE6E6E6)),
        ),
        onSelected: (_) => setState(() => available = true),
        labelStyle: TextStyle(
          color: available ? _orange : Colors.black87,
        ),
        backgroundColor: const Color(0xFFF7F7F7),
      ),
      const SizedBox(width: 12),
      ChoiceChip(
        label: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
          child: Text("OUT OF STOCK",
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        selected: !available,
        selectedColor: const Color(0xFFFFF1E3),
        showCheckmark: false,
        shape: StadiumBorder(
          side: BorderSide(
              color: !available ? _orange : const Color(0xFFE6E6E6)),
        ),
        onSelected: (_) => setState(() => available = false),
        labelStyle: TextStyle(
          color: !available ? _orange : Colors.black87,
        ),
        backgroundColor: const Color(0xFFF7F7F7),
      ),
    ],
  );
}

  Future<String?> uploadImageToImageKit(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$privateKey:'))}';
      request.headers['Authorization'] = basicAuth;
      request.fields['fileName'] = imageFile.path.split('/').last;
      request.fields['useUniqueFileName'] = 'true';
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      final respBody = await http.Response.fromStream(response);
      if (respBody.statusCode == 200) {
        final jsonResp = jsonDecode(respBody.body);
        return jsonResp['url'];
      } else {
        print("Upload failed: ${respBody.body}");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
  bool _saving = false;

  Future<void> saveProduct() async {
  if (_saving) return; // prevent double taps
  setState(() => _saving = true);

  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    String? imageUrl = uploadedImageUrl;
    if (_selectedImage != null && uploadedImageUrl == null) {
      imageUrl = await uploadImageToImageKit(_selectedImage!);
    }
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed. Try again.")),
      );
      return;
    }

    final userProductsRef =
        FirebaseDatabase.instance.ref('Shops/user/$userId/products');

    await userProductsRef.push().set({
      'name': name,
      'description': desc,
      'price': price,
      'available': available,
      'imageUrl': imageUrl,
    });

    if (!mounted) return;
    setState(() {
      published = true;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Something went wrong: $e")),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

Widget _buildSavingOverlay() {
  return Positioned.fill(
    child: AbsorbPointer(
      child: Container(
        color: Colors.black.withOpacity(0.15),
        child: Center(
          child: Loader(message: 'Saving...'),
        ),
      ),
    ),
  );
}



  Widget _buildImageBox() {
    return Container(
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
            : Center(
                child: Icon(Icons.add_a_photo, color: Colors.orange, size: 42),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
if (published) {
  return Scaffold(
    backgroundColor: Colors.orange, // Make background orange
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(16),
            child: Icon(Icons.check, color: Colors.orange, size: 40),
          ),
          SizedBox(height: 32),
          Text(
            name.isNotEmpty ? name : "Amazing Fan", // fallback example
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Published!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              setState(() {
                published = false;
                previewMode = false;
                name = '';
                desc = '';
                price = 0;
                available = true;
                _selectedImage = null;
                uploadedImageUrl = null;
              });
            },
            child: Text(
              "Add Another Product",
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    ),
  );
}
  

    if (previewMode) {
      return Scaffold(
  backgroundColor: Colors.white,
  body: SafeArea(
    child: Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            // Back row (custom, not AppBar)
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

            // Rounded preview image with dots like the mock
            _roundedPreviewImage(),

            const SizedBox(height: 24),

            // Title
            Text(
              name.isEmpty ? "Amazing Fan" : name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              "₹ $price",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              desc.isEmpty
                  ? "The perfect T-shirt for when you want to feel comfortable but still stylish. Amazing for all occasions. Made of 100% cotton fabric in four colours. Its modern style gives a lighter look to the outfit. Perfect for the warmest days."
                  : desc,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6C6C6C),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Stock",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // Stock chips (left: OUT OF STOCK, right: AVAILABLE)
            Row(
              children: [
                _stockChip(
                  label: "OUT OF STOCK",
                  filled: false,
                  selected: !available,
                  onTap: () => setState(() => available = false),
                ),
                const SizedBox(width: 12),
                _stockChip(
                  label: "AVAILABLE",
                  filled: true,
                  selected: available,
                  onTap: () => setState(() => available = true),
                ),
              ],
            ),
          ],
        ),

        // Sticky bottom "Publish" button
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: saveProduct,
                child: const Text(
                  "Publish",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
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

    return Scaffold(
    appBar: _buildAppBar(context, "Add Product"),
    backgroundColor: Color(0xFFFFFFFF),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // IMAGE AREA (unchanged per your request)
                _buildImageBox(),

                const SizedBox(height: 12),

                // “Uploaded 5 photos & 1 video”
                // Center(
                //   child: Text(
                //     "Uploaded $photoCount photos & $videoCount video",
                //     style: const TextStyle(
                //       fontSize: 14,
                //       color: Color(0xFF6C6C6C),
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),

                const SizedBox(height: 14),

                // Upload Product button (orange pill)
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload_rounded, size: 22),
                    label: const Text(
                      "Upload Product",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      pickImage();
                    },
                  ),
                ),

                // Name of Product
                _sectionTitle("Name of Product"),
                TextFormField(
                  decoration: _fieldDecoration("Enter product name"),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter product name' : null,
                  onChanged: (v) => name = v,
                ),

                // About Product
                _sectionTitle("About Product"),
                TextFormField(
                  decoration: _fieldDecoration(
                      "Product Description"),
                  onChanged: (v) => desc = v,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter description' : null,
                  maxLines: 4,
                  minLines: 3,
                ),

                // Stock Availability
                _sectionTitle("Stock Availability"),
                _availabilityChips(),

                // Price Range (single price input as per your data model)
                _sectionTitle("Price"),
                TextFormField(
                  decoration: _fieldDecoration("Enter price").copyWith(
                    prefixText: "₹ ",
                    prefixStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => price = int.tryParse(v) ?? 0,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter price' : null,
                ),
              ],
            ),

            // Big sticky “Preview” button (like the screenshot)
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() => previewMode = true);
                      }
                    },
                    child: const Text(
                      "Preview",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return PreferredSize(
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
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2024))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
