import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;

  final picker = ImagePicker();

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // or camera
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // Navigate to ML Kit detection
      Navigator.pushNamed(context, '/detect', arguments: _image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FoodImpact Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null ? Image.file(_image!, height: 200) : Container(),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Upload / Take Photo'),
            ),
          ],
        ),
      ),
    );
  }
}
