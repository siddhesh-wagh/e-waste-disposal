import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';

class EwasteDetectionPage extends StatefulWidget {
  @override
  _EwasteDetectionPageState createState() => _EwasteDetectionPageState();
}

class _EwasteDetectionPageState extends State<EwasteDetectionPage> {
  File? _image;
  String? _result;
  Interpreter? _interpreter;
  final int imageSize = 224;
  final List<String> labels = [
    'TV', 'Microwave', 'Smartwatch', 'Keyboards', 'Mobile', 'Mouses',
    'Laptop', 'Camera', 'Washing Machine', 'Printer', 'Player', 'PCB'
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model/e_waste_classifier.tflite');
      print("✅ Model loaded successfully");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      classifyImage(_image!);
    }
  }

  Future<void> classifyImage(File image) async {
    if (_interpreter == null) {
      print("⚠️ Model not yet loaded.");
      return;
    }

    try {
      var imageBytes = image.readAsBytesSync();
      img.Image? imageInput = img.decodeImage(imageBytes);
      imageInput = img.copyResize(imageInput!, width: imageSize, height: imageSize);

      var input = List.generate(1, (i) => List.generate(imageSize, (j) =>
          List.generate(imageSize, (k) => List.generate(3, (c) => 0.0), growable: false), growable: false), growable: false);


      for (int y = 0; y < imageSize; y++) {
        for (int x = 0; x < imageSize; x++) {
          var pixel = imageInput.getPixel(x, y);
          input[0][y][x][0] = ((pixel >> 16) & 0xFF) / 255.0;
          input[0][y][x][1] = ((pixel >> 8) & 0xFF) / 255.0;
          input[0][y][x][2] = (pixel & 0xFF) / 255.0;
        }
      }

      var output = List.generate(1, (index) => List.filled(labels.length, 0.0));
      _interpreter!.run(input, output);

      int maxPos = output[0].indexWhere((val) => val == output[0].reduce((a, b) => a > b ? a : b));
      double confidence = output[0][maxPos] * 100;

      setState(() {
        _result = "Detected: ${labels[maxPos]}\nConfidence: ${confidence.toStringAsFixed(2)}%";
      });
    } catch (e) {
      print("❌ Error in classification: $e");
    }
  }

  void _searchOnline(String query) async {
    final url = Uri.parse("https://www.google.com/search?q=${Uri.encodeComponent(query)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    } else {
      print("❌ Could not launch search for $query");
    }
  }

  void showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.camera),
            title: Text('Take a Photo'),
            onTap: () => pickImage(ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text('Choose from Gallery'),
            onTap: () => pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("E-Waste Scanner")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: _image == null
                ? Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.camera_alt, size: 100, color: Colors.white),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(_image!, height: 250, width: 250, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 20),
          _result == null
              ? Text("Import Your Image", style: TextStyle(fontSize: 16))
              : GestureDetector(
            onTap: () => _searchOnline(_result!.split(':')[1].trim()),
            child: Text(
              _result!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: showImageSourceSelection,
            icon: Icon(Icons.camera, color: Colors.black),
            label: Text("Scan Image", style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}