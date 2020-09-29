import 'package:my_camera/src/previewscreen/preview.screen.dart';
import 'package:path/path.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController controller;
  int selectedCameraId;
  String imagePath;
  List cameras;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras.length > 0) {
        setState(() {
          selectedCameraId = 0;
        });
        _initCameraController(cameras[selectedCameraId]).then((value) => {});
      }
    }).catchError((onError) =>
        print('Error: ${onError.code}\nError Message: ${onError.message}'));
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) await controller.dispose();

    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) setState(() {});

      if (controller.value.hasError)
        print('Camera error ${controller.value.errorDescription}');
    });

    try {
      await controller.initialize();
    } on CameraException catch (error) {
      _showCameraException(error);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: double.infinity,
            child: _cameraPreviewWidget(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _cameraTogglesRowWidget(),
              _captureControlRowWidget(context),
              Spacer()
            ],
          ),
        ],
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized)
      return const Text(
        'Aguarde...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w800,
        ),
      );

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(
        controller,
      ),
    );
  }

  Widget _cameraTogglesRowWidget() {
    if (cameras == null || cameras.isEmpty) return Spacer();

    CameraDescription selectedCamera = cameras[selectedCameraId];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Expanded(
      flex: 1,
      child: Align(
          alignment: Alignment.bottomLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                margin: EdgeInsets.all(10.0),
                child: FlatButton.icon(
                  onPressed: _onSwitchCamera,
                  icon: Icon(
                    _getCameraLensIcon(lensDirection),
                    color: Colors.white,
                  ),
                  label: Text(
                      ""), //${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1)}
                ),
              )
            ],
          )),
    );
  }

  Widget _captureControlRowWidget(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              margin: EdgeInsets.all(10.0),
              child: FloatingActionButton(
                elevation: 4,
                child: Icon(Icons.camera),
                backgroundColor: Colors.blueGrey,
                onPressed: () => _onCapturePressed(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  void _onSwitchCamera() {
    selectedCameraId =
        selectedCameraId < cameras.length - 1 ? selectedCameraId + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraId];
    _initCameraController(selectedCamera);
  }

  void _onCapturePressed(BuildContext context) async {
    try {
      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      print(path);
      await controller.takePicture(path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewImageScreen(imagePath: path),
        ),
      );
    } catch (error) {
      print('Error: $error');
    }
  }

  void _showCameraException(CameraException error) {
    String errorText =
        'Error: ${error.code}\nError Message: ${error.description}';
    print(errorText);
  }
}
