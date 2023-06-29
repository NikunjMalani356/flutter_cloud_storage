
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Uploader',
      home: ImageUploader(),
    );
  }
}

Future<void> get() async {
  var status = await Permission.camera.status;
  var status1 = await Permission.storage.status;
  if (status.isDenied && status1.isDenied) {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();
  }
}

Future<String> _uploadImage(File image) async {
  final storage = FirebaseStorage.instance;
  final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  final reference = storage.ref().child('images/$fileName');

  final uploadTask = reference.putFile(image);
  final snapshot = await uploadTask.whenComplete(() {});
  final imageUrl = await snapshot.ref.getDownloadURL();

  try {
   await uploadTask.whenComplete(() {});
  } catch (error) {
  }
  return imageUrl;
}

void _updateFirestore(String imageUrl) {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('images');

  final data = {
    'image_url': imageUrl,
    // Add any additional fields as needed
  };

  collection.add(data);
}

class ImageUploader extends StatefulWidget {
  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}




class _ImageUploaderState extends State<ImageUploader> {


  File? _selectedImage;
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadAndSave() async {
    if (_selectedImage != null) {
      final imageUrl = await _uploadImage(_selectedImage!);
      _updateFirestore(imageUrl);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Uploader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null) ...[
              Image.file(
                _selectedImage!,
                height: 200,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadAndSave,
                child: Text('Upload Image'),
              ),
            ] else ...[
              Text('No image selected'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Select Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
