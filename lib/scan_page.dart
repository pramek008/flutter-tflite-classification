import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  /// The image that the user has selected, or null if no image has been
  /// selected.
  File? _image;

  /// The results of the most recent image scan, or an empty list if no
  /// image has been scanned.
  late List _scanResults;
  bool imageSelected = false;

  /// This ensures the model is loaded before the UI
  /// can interact with it
  @override
  void initState() {
    super.initState();
    loadModel();
  }

  /// Load the TFLite model that we'll use to scan images.
  Future loadModel() async {
    // Close the TFLite model, in case one is already open.
    Tflite.close();

    // Open the TFLite model. The model and labels
    // stored in the 'assets' directory of
    // the Flutter app.
    await Tflite.loadModel(
      model: 'assets/pet_models.tflite',
      labels: 'assets/labels.txt',
    );
  }

  /// Run the TFLite model on the given image.
  // Run the TFLite model on the image. The result is a list of
  // recognitions, where each recognition is a map with the following
  // keys:
  //
  // * 'index': an integer index of the recognition
  // * 'label': the label of the recognition
  // * 'confidence': the confidence of the recognition, as a value between 0 and 1
  //
  // The 'numResults' parameter specifies the maximum number of
  // recognitions to return. The 'threshold' parameter specifies the
  // minimum confidence required for a recognition to be returned.
  Future scanImage(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.2,
      asynch: true,
    );

    // Update the state with the results of the scan.
    setState(() {
      _scanResults = recognitions!;
      _image = image;
      imageSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Cat Animal Detection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            imageSelected
                ? Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  )
                : Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                  ),
            const SizedBox(height: 20),
            imageSelected
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${_scanResults[0]['label']}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Confidence: ${_scanResults[0]['confidence']}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : const Text('No image selected'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                pickImage();
              },
              child: const Text('Select Image'),
            ),
          ],
        ),
      ),
    );
  }

  /// This function opens the image picker, and if an image
  /// is selected, it calls [scanImage] to classify the image.
  /// If the widget is not mounted, it does not show the [SnackBar].
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? selectedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (selectedImage == null) return;

    try {
      // Open the selected image file
      final File imageFile = File(selectedImage.path);
      // Run the TFLite model on the image and store the results
      await scanImage(imageFile);
    } on Exception catch (error) {
      // If an error occurs, show a SnackBar with the error message.
      // If the widget is not mounted, do nothing.
      mounted
          ? ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString()),
              ),
            )
          : null;
    }
  }
}
