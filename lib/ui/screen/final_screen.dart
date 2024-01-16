import 'dart:convert';
import 'dart:io';

import 'package:farmhelp/main.dart';
import 'package:farmhelp/ui/screen/home_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  String predictionResult = '';

  Future getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile;
        uploadImage(pickedFile.path);
        isloading = true;
      } else {
        isloading = false;
      }
    });
  }

  Future uploadImage(String path) async {
    final uri = Uri.parse(
        'http://192.168.1.8:5000/predict'); // local testing Change on deployment
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      var response = await request.send();
      print(response);
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        predictionResult = responseBody;
        isloading = false;
        setState(() {});
      }
    } catch (e) {
      print('Could not upload image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> resultData = predictionResult.isNotEmpty
        ? (jsonDecode(predictionResult) as Map<String, dynamic>)
        : {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant disease detection'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
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
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => getImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            // Add this
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_image == null)
                    const Text('No image selected.')
                  else
                    Image.file(File(_image!.path)),
                  const SizedBox(height: 15),
                  AnimatedCrossFade(
                    crossFadeState: predictionResult.isNotEmpty
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 500),
                    firstChild: Container(width: double.infinity),
                    secondChild: _image == null
                        ? Container(width: double.infinity)
                        : buildPredictionResult(resultData),
                  ),
                ],
              ),
            ),
            // remaining code
          ),
          if (isloading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPredictionResult(Map<String, dynamic> resultData) {
    String description =
        resultData['description'] ?? 'No description available.';
    String prevention =
        resultData['prevent'] ?? 'No prevention measures available.';
    String supplementLink = resultData['supplement_buy_link'] ?? '';
    String supplementName =
        resultData['title'] ?? 'Supplement information not available.';

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.greenAccent,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(
                Icons.nature,
                color: Colors.green,
                size: 50,
              ),
              title: Text(
                'Prediction Result:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supplement Name:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    supplementName,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Prevention:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prevention,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  supplementLink.isNotEmpty
                      ? Center(
                          // Wrap your button with Center
                          child: Padding(
                            // You can add Padding for some space around the button
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (await canLaunch(supplementLink)) {
                                  await launch(supplementLink);
                                } else {
                                  throw 'Could not launch $supplementLink';
                                }
                              },
                              child: const Text('Buy Supplement'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blue, // background
                                onPrimary: Colors.white, // foreground
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 0),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
