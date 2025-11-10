// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera_platform_interface/camera_platform_interface.dart';

export 'package:camera_platform_interface/camera_platform_interface.dart'
    show
        CameraDescription,
        CameraException,
        CameraLensDirection,
        CameraLensType,
        CameraResolution,
        ExposureMode,
        FlashMode,
        FocusMode,
        ImageFormatGroup,
        ResolutionPreset,
        XFile;

export 'src/camera_controller.dart';
export 'src/camera_image.dart';
export 'src/camera_preview.dart';

/// Gets available camera resolutions for the specified camera.
///
/// Returns a list of [CameraResolution] objects representing all
/// resolutions supported by the camera for photo/video capture.
///
/// The [cameraId] parameter is the index of the camera in the list
/// returned by [availableCameras].
///
/// Example:
/// ```dart
/// final cameras = await availableCameras();
/// final resolutions = await availableCameraResolutions(cameras[0]);
///
/// // Pick highest resolution
/// final highestResolution = resolutions.reduce((a, b) =>
///   (a.width * a.height) > (b.width * b.height) ? a : b
/// );
/// ```
Future<List<CameraResolution>> availableCameraResolutions(
  CameraDescription cameraDescription,
) async {
  // Get camera index from available cameras
  final cameras = await CameraPlatform.instance.availableCameras();
  final cameraId = cameras.indexWhere((c) => c.name == cameraDescription.name);

  if (cameraId == -1) {
    throw CameraException(
      'cameraNotFound',
      'Camera ${cameraDescription.name} not found',
    );
  }

  return CameraPlatform.instance.getAvailableResolutions(cameraId);
}

/// Get available video resolutions for a camera.
///
/// Returns resolutions supported by CamcorderProfile for video recording.
/// These resolutions are guaranteed to be usable for video recording,
/// unlike [availableCameraResolutions] which returns photo resolutions
/// that may not be supported for video.
///
/// Example:
/// ```dart
/// final cameras = await availableCameras();
/// final videoResolutions = await availableCameraVideoResolutions(cameras[0]);
///
/// // Pick highest video resolution
/// final highestVideoResolution = videoResolutions.reduce((a, b) =>
///   (a.width * a.height) > (b.width * b.height) ? a : b
/// );
/// ```
Future<List<CameraResolution>> availableCameraVideoResolutions(
  CameraDescription cameraDescription,
) async {
  // Get camera index from available cameras
  final cameras = await CameraPlatform.instance.availableCameras();
  final cameraId = cameras.indexWhere((c) => c.name == cameraDescription.name);

  if (cameraId == -1) {
    throw CameraException(
      'cameraNotFound',
      'Camera ${cameraDescription.name} not found',
    );
  }

  return CameraPlatform.instance.getAvailableVideoResolutions(cameraId);
}
