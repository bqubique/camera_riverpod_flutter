import 'dart:developer';
import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:camera/camera.dart';

import 'camera_state.dart';
import 'main.dart';

///Provides the camera controller provider
final applicationCameraControllerProvider =
    StateNotifierProvider<CameraFeatureController, CameraState>((ref) {
  return CameraFeatureController(
    CameraState(
      controller: CameraController(
        cameras[0],
        ResolutionPreset.max,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      ),
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
  ///Call this when you want to switch from front to rear camera, or when you're
  ///selecting a camera for the first time.
  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    //Get the old controller, set it to null and dispose it
    final CameraController? oldController = state.controller;
    if (oldController != null) {
      state.copyWith(controller: null);
      await oldController.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    state = state.copyWith(controller: cameraController);

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        state = state.copyWith(controller: state.controller);
      }
      if (cameraController.value.hasError) {
        log('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await state.controller!.initialize();
    } on CameraException catch (e) {
      log('error is $e');
    }

    if (mounted) {
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
  Future<void> switchCamera() async {
    if (state.controller!.description.lensDirection ==
        CameraLensDirection.back) {
      await onNewCameraSelected(cameras.firstWhere((selectedCamera) =>
          selectedCamera.lensDirection == CameraLensDirection.front));
    } else {
      await onNewCameraSelected(cameras.firstWhere((selectedCamera) =>
          selectedCamera.lensDirection == CameraLensDirection.back));
    }
  }

  ///Switches the camera to [CameraLensDirection.front] if current LensDirection is [CameraLensDirection.back]
  Future<void> switchToFrontCamera() async {
    if (state.controller!.description.lensDirection ==
        CameraLensDirection.front) {
      return;
    }

    await onNewCameraSelected(cameras.firstWhere((selectedCamera) =>
        selectedCamera.lensDirection == CameraLensDirection.front));
  }

  ///Switches the camera to [CameraLensDirection.back] if current LensDirection is [CameraLensDirection.front]
  Future<void> switchToRearCamera() async {
    if (state.controller!.description.lensDirection ==
        CameraLensDirection.back) {
      return;
    }

    await onNewCameraSelected(cameras.firstWhere((selectedCamera) =>
        selectedCamera.lensDirection == CameraLensDirection.back));
  }

  ///Safely take a picture using the camera controller by checking for [controller.isTakingPicture] property before.
  Future<XFile?> takePicture() async {
    final CameraController? cameraController = state.controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      log('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      log(e.description!);
      return null;
    }
  }
}
