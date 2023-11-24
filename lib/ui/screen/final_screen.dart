import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';
//import the config.dart file here for api access

import 'package:http_parser/http_parser.dart';

Future main() async {
  await dotenv.load(fileName: "assets/.env");
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FinalPage(),
  ));
}

class FinalPage extends StatefulWidget {
  @override
  _FinalPageState createState() => _FinalPageState();
}

class _FinalPageState extends State<FinalPage> {
  bool isloading = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  String predictionResult = ''; // Added to store the prediction result

  Future getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile;
        uploadImage(pickedFile.path);
        isloading = true; //new bool is added
      } else {
        print('No image selected.');
        isloading = false; //new bool is added
      }
    });
  }

  Future uploadImage(String path) async {
    // make sure your flask api or any other ml api is working
    //  print('\n\nAPI URL: ${dotenv.env['flask_api']}');
    var request = http.MultipartRequest(
        'POST', Uri.parse('${dotenv.env['flask_api']!}/predict'));

    request.files.add(await http.MultipartFile.fromPath('file', path,
        contentType: MediaType('image', 'jpeg')));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        setState(() {
          predictionResult = responseBody; // Update the prediction result
          isloading = false; //new bool is added
        });
      }
    } catch (e) {
      print('Could not upload image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant disease detection'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => getImage(ImageSource.camera),
                icon: const Icon(Icons.add_a_photo),
                label: Text('Camera'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => getImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library),
                label: Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_image == null)
                  Text('No image selected.')
                else
                  Image.file(File(_image!.path)),
                //  Image.network(_image!.path),  ///use this or other this type of method to show result in web.
                SizedBox(height: 15),
                if (predictionResult.isNotEmpty)
                  Text('Prediction Result: $predictionResult'),

                // Display the prediction result
              ],
            ),
          ),
          if (isloading)
            Center(
                child:
                    CircularProgressIndicator()), // Show CircularProgressIndicator when isLoading is true
        ],
      ),
    );
  }
}
