import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera_riverpod_flutter/camera_feature_controller.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  runApp(const ProviderScope(child: MyApp()));
}

late List<CameraDescription> cameras;

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme:
            ColorScheme.fromSwatch().copyWith(primary: Colors.redAccent),
      ),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState with WidgetsBindingObserver {
  @override
  void didChangeDependencies() async {
    WidgetsBinding.instance.addObserver(this);

    for (final CameraDescription cameraDescription in cameras) {
      if (cameraDescription.lensDirection == CameraLensDirection.back) {
        ref
            .watch(applicationCameraControllerProvider.notifier)
            .onNewCameraSelected(cameraDescription);
      }
    }

    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController cameraController =
        ref.watch(applicationCameraControllerProvider).controller!;

    if (!cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      ref
          .watch(applicationCameraControllerProvider.notifier)
          .onNewCameraSelected(ref
              .watch(applicationCameraControllerProvider)
              .controller!
              .description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var stateController = ref.watch(applicationCameraControllerProvider);

    return Scaffold(
      body: Column(
        children: [
          _cameraPreviewWidget(),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CameraButton(
                callback: ref
                    .watch(applicationCameraControllerProvider.notifier)
                    .switchCamera,
                buttonStyle: OutlinedButton.styleFrom(
                  shape: const CircleBorder(
                      side: BorderSide(width: 2.0, color: Colors.white)),
                  backgroundColor: Colors.grey[800],
                ),
                child: Row(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Icon(Icons.flip_camera_android_outlined),
                    ),
                  ],
                ),
              ),
              CameraButton(
                callback: _takePicture,
                buttonStyle: ButtonStyle(
                  shape: MaterialStateProperty.all<CircleBorder>(
                    const CircleBorder(side: BorderSide.none),
                  ),
                ),
                child: Row(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Icon(Icons.camera_alt_outlined),
                    ),
                  ],
                ),
              ),
              CameraButton(
                callback: () {},
                buttonStyle: OutlinedButton.styleFrom(
                  shape: const CircleBorder(
                      side: BorderSide(width: 2.0, color: Colors.white)),
                  backgroundColor: Colors.grey[800],
                ),
                child: stateController.lastPictureTaken!.path.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Icon(Icons.camera_alt_outlined),
                      )
                    : Image.file(
                        File(stateController.lastPictureTaken!.path),
                        height: 30,
                      ),
              )
            ],
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    var controller = ref.watch(applicationCameraControllerProvider).controller;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              'Initialising Camera Controller',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 50.0),
            CircularProgressIndicator()
          ],
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(25.0),
            bottomLeft: Radius.circular(25.0)),
        child: CameraPreview(controller),
      );
    }
  }

  ///Takes picture and returns the Base64 value.
  ///
  ///This method provides the functionality
  ///of taking a picture using the controller
  ///of [CameraController] provider, converts
  ///the picture to Uint8List and then encodes
  ///the list to a Base64, which is then returned
  ///to the caller.
  Future<void> _takePicture() async {
    try {
      XFile pictureTaken = await ref
          .watch(applicationCameraControllerProvider)
          .controller!
          .takePicture();

      ref
          .watch(applicationCameraControllerProvider.notifier)
          .updateLastPictureTaken(pictureTaken);
    } catch (e) {
      log(e.toString());
    }
  }
}

class CameraButton extends StatelessWidget {
  final VoidCallback callback;
  final Widget child;
  final ButtonStyle buttonStyle;
  const CameraButton({
    Key? key,
    required this.callback,
    required this.child,
    required this.buttonStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      child: ElevatedButton(
        onPressed: callback,
        style: buttonStyle,
        child: child,
      ),
    );
  }
}
