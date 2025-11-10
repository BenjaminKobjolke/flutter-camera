# Flutter Camera Fork - Video Resolution API

This is a fork of the official [Flutter Camera plugin](https://github.com/flutter/packages/tree/main/packages/camera) with added support for querying native video resolutions via Android's CamcorderProfile API.

## Why This Fork?

The official Flutter camera plugin provides `availableCameras()` to list cameras and resolution presets, but it doesn't expose which resolutions are actually **supported for video recording**. This causes a critical issue:

### The Problem

When building a video recording app, the camera API returns **photo resolutions** (e.g., 4000×3000, 3264×2448) that may not be supported by the device's video encoder. Attempting to record video at these resolutions results in:

- ❌ Recording failures
- ❌ Crashes during video capture
- ❌ Poor user experience with misleading resolution options
- ❌ No way to query which resolutions actually work for video

### The Solution

This fork adds a new API: **`availableCameraVideoResolutions()`**

This function queries Android's `CamcorderProfile` to return only resolutions that are guaranteed to work for video recording (e.g., 1920×1080, 1280×720, 3840×2160).

## What's New

### New API Method

```dart
/// Get available video resolutions for a camera.
///
/// Returns resolutions supported by CamcorderProfile for video recording.
/// These resolutions are guaranteed to be usable for video recording,
/// unlike [availableCameraResolutions] which returns photo resolutions
/// that may not be supported for video.
Future<List<CameraResolution>> availableCameraVideoResolutions(
  CameraDescription cameraDescription,
);
```

### Example Usage

```dart
import 'package:camera/camera.dart';

Future<void> setupCamera() async {
  // Get available cameras
  final cameras = await availableCameras();
  final backCamera = cameras.first;

  // Get video-capable resolutions
  final videoResolutions = await availableCameraVideoResolutions(backCamera);

  // Pick highest video resolution
  final bestVideoResolution = videoResolutions.reduce((a, b) =>
    (a.width * a.height) > (b.width * b.height) ? a : b
  );

  print('Best video resolution: ${bestVideoResolution.width}×${bestVideoResolution.height}');
  // Output: Best video resolution: 1920×1080 (or 3840×2160 on devices that support 4K)

  // Create camera controller with video resolution
  final controller = CameraController.withResolution(
    backCamera,
    bestVideoResolution,
    enableAudio: true,
  );

  await controller.initialize();
}
```

## Implementation Details

### Changes Made

1. **Pigeon API Definition** (`camera_android/pigeons/messages.dart`)
   - Added `getAvailableVideoResolutions()` method to CameraApi interface

2. **Native Android Implementation** (`camera_android/android/src/main/java/io/flutter/plugins/camera/CameraApiImpl.java`)
   - Implemented method that queries `CamcorderProfile` for supported video quality levels
   - Queries: 2160P (4K), 1080P, 720P, 480P, QVGA, HIGH, LOW
   - Returns deduplicated list sorted by pixel count (descending)

3. **Dart Integration** (`camera_android/lib/src/android_camera.dart`)
   - Added Dart wrapper to bridge native calls to Flutter

4. **Platform Interface** (`camera_platform_interface/lib/src/platform_interface/camera_platform.dart`)
   - Added abstract method to platform interface

5. **Public API** (`camera/lib/camera.dart`)
   - Exported `availableCameraVideoResolutions()` as public API
   - Added comprehensive documentation and examples

### Technical Approach

The implementation uses Android's `CamcorderProfile` class to query which video resolutions are actually supported by the device:

```java
// Query all available CamcorderProfile quality levels
int[] qualityLevels = {
  CamcorderProfile.QUALITY_2160P,  // 4K (3840×2160)
  CamcorderProfile.QUALITY_1080P,  // 1080p (1920×1080)
  CamcorderProfile.QUALITY_720P,   // 720p (1280×720)
  CamcorderProfile.QUALITY_480P,   // 480p (640×480)
  CamcorderProfile.QUALITY_QVGA,   // QVGA
  CamcorderProfile.QUALITY_HIGH,   // Highest available
  CamcorderProfile.QUALITY_LOW     // Lowest available
};

for (int quality : qualityLevels) {
  if (CamcorderProfile.hasProfile(cameraId, quality)) {
    CamcorderProfile profile = CamcorderProfile.get(cameraId, quality);
    // Add resolution to list
  }
}
```

This guarantees that every returned resolution is supported for video recording.

## Comparison: Photo vs Video Resolutions

### Before (using `availableCameraResolutions()`)
```dart
final resolutions = await availableCameraResolutions(camera);
// Returns: [4000×3000, 3264×2448, 1920×1080, 1280×720, ...]
// ⚠️ 4000×3000 and 3264×2448 may NOT work for video!
```

### After (using `availableCameraVideoResolutions()`)
```dart
final videoResolutions = await availableCameraVideoResolutions(camera);
// Returns: [3840×2160, 1920×1080, 1280×720, ...]
// ✅ All resolutions are guaranteed to work for video recording
```

## Use Case

This fork was created for the [Android Folder Gallery](https://github.com/BenjaminKobjolke/android-folder-gallery) app, which needed reliable video recording with proper resolution selection:

- **Photo Mode:** Uses `availableCameraResolutions()` for high-quality photos
- **Video Mode:** Uses `availableCameraVideoResolutions()` for reliable video recording

## Installation

### Option 1: Use as Git Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  camera:
    git:
      url: https://github.com/BenjaminKobjolke/flutter-camera.git
      path: camera
  camera_android:
    git:
      url: https://github.com/BenjaminKobjolke/flutter-camera.git
      path: camera_android
```

### Option 2: Local Path (for development)

```yaml
dependencies:
  camera:
    path: ../flutter-camera/camera
  camera_android:
    path: ../flutter-camera/camera_android
```

## Compatibility

- **Minimum Android SDK:** 21 (Android 5.0 Lollipop)
- **Tested on:** Android 11-14
- **Flutter:** >= 3.9.2
- **Dart:** >= 3.0

## Known Limitations

- Currently Android-only (iOS still uses original implementation)
- `CamcorderProfile.get()` is deprecated in API 31+ but still functional
- Future versions may need migration to `EncoderProfiles` API

## Contributing

This fork is maintained for the Android Folder Gallery project. If you'd like similar functionality in the official Flutter camera plugin, please consider:

1. Opening an issue in the [official Flutter repository](https://github.com/flutter/flutter/issues)
2. Referencing this implementation as a proof-of-concept
3. Proposing it as a feature addition

## License

This fork maintains the same BSD-style license as the original Flutter camera plugin. See individual package LICENSE files for details.

## Credits

- **Original Plugin:** [Flutter Team](https://github.com/flutter/packages/tree/main/packages/camera)
- **Fork Maintainer:** [Benjamin Kobjolke](https://github.com/BenjaminKobjolke)
- **Implementation Assistance:** Claude Code by Anthropic

## Links

- **Original Repository:** https://github.com/flutter/packages/tree/main/packages/camera
- **This Fork:** https://github.com/BenjaminKobjolke/flutter-camera
- **Android Folder Gallery:** https://github.com/BenjaminKobjolke/android-folder-gallery
- **Issue Tracking:** Use GitHub Issues in this repository

---

**Last Updated:** November 10, 2025
**Fork Version:** Based on flutter/camera packages as of November 2025
