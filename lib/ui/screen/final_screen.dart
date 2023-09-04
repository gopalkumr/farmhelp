import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MyModel extends StatefulWidget {
  final CameraDescription camera;

  const MyModel({Key? key, required this.camera}) : super(key: key);

  @override
  _MyModelState createState() => _MyModelState();
}

class _MyModelState extends State<MyModel> {
  late CameraController _controller;
  late Interpreter _interpreter;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initCamera();
    _loadModel();
  }

  void _initCamera() async {
    try {
      await _controller.initialize();
      if (!mounted) {
        return;
      }
      setState(() {});
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions()
        ..addDelegate(XNNPackDelegate()); // Use XNNPACK for inference (Android)

      _interpreter = await Interpreter.fromAsset(
        'assets/model.tflite',
        options: interpreterOptions,
      );

      log('Model loaded successfully');
    } catch (e) {
      log('Error initializing model: $e');
    }
  }

  void _disposeModel() {
    _interpreter.close();
  }

  void _disposeCamera() {
    _controller.dispose();
  }

  Future<void> _capturePhotoAndDetect() async {
    if (!_isProcessing) {
      setState(() {
        _isProcessing = true;
      });

      try {
        if (_controller.value.isInitialized) {
          final XFile file = await _controller.takePicture();
          final Uint8List imageBytes = await File(file.path).readAsBytes();

          // Preprocess the image
          var inputImage = decodeImage(imageBytes);
          inputImage = copyResize(inputImage!, width: 300, height: 300);
          final normalizedInput = inputImage.getBytes(format: Format.rgba);

          // Prepare the input tensor
          final Float32List input = Float32List.fromList(
              normalizedInput.map((e) => e / 255.0).toList());

          // Perform inference
          final output = List<double>.filled(1 * 16, 0).reshape([1, 16]);
          _interpreter.run(input, output);

          // Post-process the output
          final List<double> probabilities = output[0];
          final int predictedClassIndex = probabilities
              .indexOf(probabilities.reduce((a, b) => a > b ? a : b));

          // Map the class index to a label (replace with your own labels)
          final List<String> labels = [
            'Class 0',
            'Class 1',
            // Add labels for all 16 classes here
          ];

          final String predictedLabel = labels[predictedClassIndex];

          log('Predicted Class: $predictedLabel');
          // Handle the predicted label as needed
        }
      } catch (e) {
        log('Error during inference: $e');
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _disposeModel();
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Disease Detection'),
        ),
        body: Stack(
          children: <Widget>[
            CameraPreview(_controller),
            Center(
              child: Text(
                _isProcessing ? 'Processing...' : '',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 24.0,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isProcessing ? null : () => _capturePhotoAndDetect(),
          child: Icon(Icons.camera),
        ),
      ),
    );
  }
}
