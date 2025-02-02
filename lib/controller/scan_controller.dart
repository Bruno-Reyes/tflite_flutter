import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFLite();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;

  var x = 0.0;
  var y = 0.0;
  var w = 0.0;
  var h = 0.0;

  var label = "";

  initCamera() async {
    if (await Permission.camera.request().isGranted){
      cameras = await availableCameras();
      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.max,
        );
        cameraController.initialize().then((value) {
        
            cameraController.startImageStream((image) {
              cameraCount++;
              if(cameraCount%10 == 0){
                cameraCount = 0;
                objectDetector(image);
              }
              update();
            });

          
        });
        isCameraInitialized(true);
        update();
    }else{
      log("Permiso a camara denegado");
    }
  }

  initTFLite() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labelmap.pbtxt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
      );
  }

  objectDetector(CameraImage image) async {
    var detector = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
    }).toList(),
    asynch: true,
    imageHeight: image.height,
    imageWidth: image.width,
    imageMean: 127.5,
    imageStd: 127.5,
    numResultsPerClass: 1,
    rotation: 90,
    threshold: 0.4,
    );

    if(detector != null && detector.length > 0){
      var detectedObject = detector.first;
      if(detectedObject["confidenceInClass"]*100 > 45){
        label = detectedObject["detectedClass"].toString();
        h = detectedObject["rect"]["h"];
        w = detectedObject["rect"]["w"];
        x = detectedObject["rect"]["x"];
        y = detectedObject["rect"]["y"];
      }
      update();
    }
  }
}