import 'dart:developer';

import 'package:riverpod/riverpod.dart';
import 'package:camera/camera.dart';

import 'camera_state.dart';
import 'main.dart';

///Provides the camera controller provider
final applicationCameraControllerProvider =
    StateNotifierProvider<CameraFeatureController, CameraState>((ref) {
  return CameraFeatureController(
    CameraState(
      controller: CameraController(cameras[0], ResolutionPreset.max),
      lastPictureTaken: XFile(''),
    ),
  );
});

class CameraFeatureController extends StateNotifier<CameraState> {
  CameraFeatureController(super.state);

  ///Selects and sets the controller to the camera passed as a parameter.
  ///
  ///This method will select a new camera and set the controller to that camera
  ///will check whether the old controller is null or not and dispose that controller
  ///respectively.
  ///
  ///Call this when you want to switch from front to rear camera or vice versa.
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    //Get the old controller, set it to null and dispose it
    final CameraController? oldController = state.controller;
    if (oldController != null) {
      state.copyWith(controller: null);
      await oldController.dispose();
    }

    //[CameraController] with the given camera
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    //Update the state's controller
    state = state.copyWith(controller: cameraController);

    cameraController.addListener(() {
      if (mounted) {
        state = state.copyWith(controller: state.controller);
      }
      if (cameraController.value.hasError) {
        log('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await state.controller?.initialize();
    } on CameraException catch (e) {
      log('Error: ${e.code}');
    }

    //If dispose is not called yet, then update the state.
    if (mounted) {
      //This is the equivalent to setState((){})
      state = state.copyWith(controller: state.controller);
    }
  }

  void updateLastPictureTaken(XFile lastPictureTaken) {
    log(lastPictureTaken.path);
    state = state.copyWith(lastPictureTaken: lastPictureTaken);
  }

  ///Switches the camera between CameraLensDirection.front and CameraLensDirection.back
  ///
  ///Checks if the current state's camera is back or front, reverts it by
  ///iterating through the list of cameras retrieved in the [main] function and
  ///updates the state's controller through [onNewCameraSelected] method of state controller
  void switchCamera() {
    if (state.controller!.description.lensDirection ==
        CameraLensDirection.back) {
      for (final CameraDescription cameraDescription in cameras) {
        if (cameraDescription.lensDirection == CameraLensDirection.front) {
          onNewCameraSelected(cameraDescription);
        }
      }
    } else {
      for (final CameraDescription cameraDescription in cameras) {
        if (cameraDescription.lensDirection == CameraLensDirection.back) {
          onNewCameraSelected(cameraDescription);
        }
      }
    }
  }

  ///Switches the camera to [CameraLensDirection.front] if current LensDirection is [CameraLensDirection.back]
  void switchToFrontCamera() {
    state.controller!.addListener(() {
      if (state.controller!.value.isInitialized) {
        if (state.controller!.value.isInitialized) {
          if (state.controller!.description.lensDirection ==
              CameraLensDirection.back) {
            for (final CameraDescription cameraDescription in cameras) {
              if (cameraDescription.lensDirection ==
                  CameraLensDirection.front) {
                onNewCameraSelected(cameraDescription);
              }
            }
          }
        }
      }
    });
  }

  ///Switches the camera to [CameraLensDirection.back] if current LensDirection is [CameraLensDirection.front]
  void switchToRearCamera() {
    state.controller!.addListener(() {
      if (state.controller!.value.isInitialized) {
        if (state.controller!.description.lensDirection ==
            CameraLensDirection.front) {
          for (final CameraDescription cameraDescription in cameras) {
            if (cameraDescription.lensDirection == CameraLensDirection.back) {
              onNewCameraSelected(cameraDescription);
            }
          }
        }
      }
    });
  }
}
