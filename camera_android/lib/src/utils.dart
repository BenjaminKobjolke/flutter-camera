// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/services.dart';

import 'messages.g.dart';

/// Converts a [PlatformCameraLensDirection] to [CameraLensDirection].
CameraLensDirection cameraLensDirectionFromPlatform(
  PlatformCameraLensDirection direction,
) => switch (direction) {
  PlatformCameraLensDirection.front => CameraLensDirection.front,
  PlatformCameraLensDirection.back => CameraLensDirection.back,
  PlatformCameraLensDirection.external => CameraLensDirection.external,
};

/// Converts a [PlatformDeviceOrientation] to [DeviceOrientation].
DeviceOrientation deviceOrientationFromPlatform(
  PlatformDeviceOrientation orientation,
) => switch (orientation) {
  PlatformDeviceOrientation.portraitUp => DeviceOrientation.portraitUp,
  PlatformDeviceOrientation.portraitDown => DeviceOrientation.portraitDown,
  PlatformDeviceOrientation.landscapeLeft => DeviceOrientation.landscapeLeft,
  PlatformDeviceOrientation.landscapeRight => DeviceOrientation.landscapeRight,
};

/// Converts a [DeviceOrientation] to [PlatformDeviceOrientation].
PlatformDeviceOrientation deviceOrientationToPlatform(
  DeviceOrientation orientation,
) {
  switch (orientation) {
    case DeviceOrientation.portraitUp:
      return PlatformDeviceOrientation.portraitUp;
    case DeviceOrientation.portraitDown:
      return PlatformDeviceOrientation.portraitDown;
    case DeviceOrientation.landscapeLeft:
      return PlatformDeviceOrientation.landscapeLeft;
    case DeviceOrientation.landscapeRight:
      return PlatformDeviceOrientation.landscapeRight;
  }
  // This enum is defined outside of this package. This fall-through case
  // ensures that the code does not break if a new value is ever added.
  // ignore: dead_code
  return PlatformDeviceOrientation.portraitUp;
}

/// Converts a [PlatformExposureMode] to [ExposureMode].
ExposureMode exposureModeFromPlatform(PlatformExposureMode exposureMode) =>
    switch (exposureMode) {
      PlatformExposureMode.auto => ExposureMode.auto,
      PlatformExposureMode.locked => ExposureMode.locked,
    };

/// Converts a [ExposureMode] to [PlatformExposureMode].
PlatformExposureMode exposureModeToPlatform(ExposureMode exposureMode) {
  switch (exposureMode) {
    case ExposureMode.auto:
      return PlatformExposureMode.auto;
    case ExposureMode.locked:
      return PlatformExposureMode.locked;
  }
  // This enum is defined outside of this package. This fall-through case
  // ensures that the code does not break if a new value is ever added.
  // ignore: dead_code
  return PlatformExposureMode.auto;
}

/// Converts a [PlatformFocusMode] to [FocusMode].
FocusMode focusModeFromPlatform(PlatformFocusMode focusMode) =>
    switch (focusMode) {
      PlatformFocusMode.auto => FocusMode.auto,
      PlatformFocusMode.locked => FocusMode.locked,
    };

/// Converts a [FocusMode] to [PlatformFocusMode].
PlatformFocusMode focusModeToPlatform(FocusMode focusMode) {
  switch (focusMode) {
    case FocusMode.auto:
      return PlatformFocusMode.auto;
    case FocusMode.locked:
      return PlatformFocusMode.locked;
  }
  // This enum is defined outside of this package. This fall-through case
  // ensures that the code does not break if a new value is ever added.
  // ignore: dead_code
  return PlatformFocusMode.auto;
}

/// Converts a [MediaSettings] to [PlatformMediaSettings].
PlatformMediaSettings mediaSettingsToPlatform(MediaSettings? settings) {
  // Convert CameraResolution to PlatformCameraResolution
  PlatformCameraResolution resolution;

  if (settings?.resolution != null) {
    // Use explicit resolution if provided
    resolution = PlatformCameraResolution(
      width: settings!.resolution!.width,
      height: settings.resolution!.height,
      minFps: settings.resolution!.minFps,
      maxFps: settings.resolution!.maxFps,
    );
  } else {
    // Fall back to resolution preset converted to a default resolution
    // Using 1920x1080 @ 30fps as default for high preset
    final preset = settings?.resolutionPreset ?? ResolutionPreset.high;
    resolution = _resolutionPresetToDefaultResolution(preset);
  }

  return PlatformMediaSettings(
    resolution: resolution,
    enableAudio: settings?.enableAudio ?? false,
    videoBitrate: settings?.videoBitrate,
    audioBitrate: settings?.audioBitrate,
    fps: settings?.fps,
  );
}

/// Converts a [ResolutionPreset] to a default [PlatformCameraResolution].
PlatformCameraResolution _resolutionPresetToDefaultResolution(
  ResolutionPreset preset,
) {
  switch (preset) {
    case ResolutionPreset.low:
      return PlatformCameraResolution(width: 352, height: 288, minFps: 15, maxFps: 30);
    case ResolutionPreset.medium:
      return PlatformCameraResolution(width: 720, height: 480, minFps: 15, maxFps: 30);
    case ResolutionPreset.high:
      return PlatformCameraResolution(width: 1280, height: 720, minFps: 15, maxFps: 30);
    case ResolutionPreset.veryHigh:
      return PlatformCameraResolution(width: 1920, height: 1080, minFps: 15, maxFps: 30);
    case ResolutionPreset.ultraHigh:
      return PlatformCameraResolution(width: 3840, height: 2160, minFps: 15, maxFps: 30);
    case ResolutionPreset.max:
      return PlatformCameraResolution(width: 3840, height: 2160, minFps: 15, maxFps: 30);
  }
}

/// Converts an [ImageFormatGroup] to [PlatformImageFormatGroup].
///
/// [ImageFormatGroup.unknown] and [ImageFormatGroup.bgra8888] default to
/// [PlatformImageFormatGroup.yuv420], which is the default on Android.
PlatformImageFormatGroup imageFormatGroupToPlatform(ImageFormatGroup format) {
  switch (format) {
    case ImageFormatGroup.unknown:
      return PlatformImageFormatGroup.yuv420;
    case ImageFormatGroup.yuv420:
      return PlatformImageFormatGroup.yuv420;
    case ImageFormatGroup.bgra8888:
      return PlatformImageFormatGroup.yuv420;
    case ImageFormatGroup.jpeg:
      return PlatformImageFormatGroup.jpeg;
    case ImageFormatGroup.nv21:
      return PlatformImageFormatGroup.nv21;
  }
  // This enum is defined outside of this package. This fall-through case
  // ensures that the code does not break if a new value is ever added.
  // ignore: dead_code
  return PlatformImageFormatGroup.yuv420;
}

/// Converts a [FlashMode] to [PlatformFlashMode].
PlatformFlashMode flashModeToPlatform(FlashMode mode) {
  switch (mode) {
    case FlashMode.auto:
      return PlatformFlashMode.auto;
    case FlashMode.off:
      return PlatformFlashMode.off;
    case FlashMode.always:
      return PlatformFlashMode.always;
    case FlashMode.torch:
      return PlatformFlashMode.torch;
  }
  // This enum is defined outside of this package. This fall-through case
  // ensures that the code does not break if a new value is ever added.
  // ignore: dead_code
  return PlatformFlashMode.auto;
}

/// Converts a [Point<double>] to [PlatformPoint].
///
/// Null becomes null.
PlatformPoint? pointToPlatform(Point<double>? point) =>
    (point != null) ? PlatformPoint(x: point.x, y: point.y) : null;
