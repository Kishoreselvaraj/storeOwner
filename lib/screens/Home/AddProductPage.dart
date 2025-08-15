import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

  Future<void> saveProduct() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in")));
      return;
    }

    String? imageUrl = uploadedImageUrl;
    if (_selectedImage != null && uploadedImageUrl == null) {
      imageUrl = await uploadImageToImageKit(_selectedImage!);
    }
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image upload failed. Try again.")));
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

    setState(() {
      published = true;
    });
  }

  Widget _buildImageBox() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inside your Widget's build method:
if (published) {
  return Scaffold(
    backgroundColor: Colors.orange, // Make background orange
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // White badge with check
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
        appBar: AppBar(title: Text("Preview")),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildImageBox(),
              SizedBox(height: 16),
              Text(name, style: TextStyle(fontSize: 20)),
              Text("₹$price"),
              SizedBox(height: 8),
              Text(desc),
              SizedBox(height: 8),
              Text("Available: ${available ? "Yes" : "No"}"),
              Spacer(),
              Row(
                children: [
                  ElevatedButton(
                      onPressed: () => setState(() => previewMode = false),
                      child: Text("Edit")),
                  SizedBox(width: 8),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      onPressed: saveProduct,
                      child: Text("Publish"))
                ],
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildImageBox(),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(labelText: "Name"),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter product name' : null,
                  onChanged: (v) => name = v,
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(labelText: "Description"),
                  onChanged: (v) => desc = v,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter description' : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => price = int.tryParse(v) ?? 0,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter price' : null,
                ),
                SwitchListTile(
                    title: Text("Available"),
                    value: available,
                    onChanged: (v) => setState(() => available = v)),
                SizedBox(height: 20),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => previewMode = true);
                    }
                  },
                  child: Text("Preview"),
                )
              ],
            )),
      ),
    );
  }
}
