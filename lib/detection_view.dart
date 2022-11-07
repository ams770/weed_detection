import 'dart:io';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:weed_detection/app_preferences.dart';

class DetectionView extends StatefulWidget {
  const DetectionView({Key? key}) : super(key: key);

  @override
  State<DetectionView> createState() => _DetectionViewState();
}

class _DetectionViewState extends State<DetectionView> {
  DetectionOutput? _result;
  File? _pickedImg;
  bool modelInitialized = false;
  bool _isDarkMode = false;
  ImagePicker image = ImagePicker();
  final Color _darkColor = Colors.grey.shade900;
  final Color _lightColor = Colors.grey.shade200;
  final Color _primaryColor = const Color(0xFF5F915B);

  @override
  void initState() {
    super.initState();
    _changeLightMode(mode: AppPreferences.getMode());
    _loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return _buildView();
  }

  _changeLightMode({bool? mode}) {
    if (mode != null) {
      setState(() {
        _isDarkMode = mode;
      });
    } else {
      setState(() {
        _isDarkMode = !_isDarkMode;
      });
    }
    AppPreferences.setMode(_isDarkMode);
  }

  _loadModel() async {
    await Tflite.loadModel(
      model: "assets/tflite/model_unquant.tflite",
      labels: "assets/tflite/labels.txt",
    ).then((value) {
      setState(() {
        modelInitialized = true;
      });
    });
  }

  _detectImage(File file) async {
    List<dynamic>? prediction = await Tflite.runModelOnImage(
      path: file.path,
      numResults: 2,
      threshold: 0.6,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    _setResult(prediction ?? []);
  }

  _setResult(List<dynamic> prediction) {
    if (prediction.isNotEmpty) {
      setState(() {
        double accPercent =
            (double.parse((prediction[0]['confidence']).toString()) * 100);
        String labelResult = (prediction[0]['label']).toString().substring(2);
        _result = DetectionOutput(
            labelResult.toString(), accPercent.toStringAsFixed(2));
      });
    }
  }


  Widget _buildView() => Scaffold(
        backgroundColor: _isDarkMode ? _darkColor : _lightColor,
        appBar: AppBar(
          backgroundColor: _isDarkMode ? _darkColor : _lightColor,
          elevation: 0.0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              _changeLightMode();
            },
            icon: Icon(
              Icons.light_mode_outlined,
              color: _primaryColor,
              size: 30,
            ),
            splashRadius: 20,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: _isDarkMode ? _darkColor : _lightColor,
            statusBarIconBrightness:
                _isDarkMode ? Brightness.light : Brightness.dark,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Click on Weed to Detect Images',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: GestureDetector(
                    onTap: _pickImg,
                    child: Image.asset(
                      'assets/images/app_icon.png',
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ConditionalBuilder(
                            condition: _result != null,
                            builder: (context) => Image.file(
                              _pickedImg!,
                              fit: BoxFit.cover,
                            ),
                            fallback: (context) => const Center(
                              child: Text(
                                'No Image Picked Yet',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ConditionalBuilder(
                        condition: _result != null,
                        builder: (context) => _buildResultView(),
                        fallback: (context) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      );

  Widget _buildResultView() =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          _result!.label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          'Accuracy: ' + _result!.accuracy + "%",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ]);

  _pickImg() {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return Container(
            height: 135,
            color: _isDarkMode
                ? Colors.black
                : const Color(0xFF737373),
            child: Container(
              decoration:_getInnerSheetDecoration(),

              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                        backgroundColor: _isDarkMode
                            ? _darkColor
                            : _lightColor,
                        radius: 16,
                        child: Icon(
                          CupertinoIcons.photo,
                          size: 20,
                          color: _primaryColor,
                        )),
                    title: Text(
                      'Pick From Gallery',
                      style: TextStyle(
                          color: _isDarkMode
                              ? _lightColor
                              : _darkColor,
                          fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                        backgroundColor: _isDarkMode
                            ? _darkColor
                            : _lightColor,
                        radius: 16,
                        child: Icon(
                          CupertinoIcons.camera,
                          size: 20,
                          color: _primaryColor,
                        )),
                    title: Text(
                      'Pick From Camera',
                      style: TextStyle(
                          color: _isDarkMode
                              ? _lightColor
                              : _darkColor,
                          fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  _pickImageFromGallery() async {
    XFile? img = await image.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _pickedImg = File(img.path);
      });
      _detectImage(_pickedImg!);
    }
  }

  _pickImageFromCamera() async {
    XFile? img = await image.pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() {
        _pickedImg = File(img.path);
      });
      _detectImage(_pickedImg!);
    }
  }

  Decoration _getInnerSheetDecoration() {
    return BoxDecoration(
      color: _isDarkMode ? Colors.grey.shade900  : _lightColor,
      borderRadius:
      const BorderRadiusDirectional.only(
        topEnd: Radius.circular(20),
        topStart: Radius.circular(20),
      ),
    );
  }

}

class DetectionOutput {
  String label;
  String accuracy;
  DetectionOutput(this.label, this.accuracy);
}



