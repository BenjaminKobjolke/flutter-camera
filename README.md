# Flutter Camera Fork - Direct Resolution Access

This is a fork of the official [Flutter Camera plugin](https://github.com/flutter/packages/tree/main/packages/camera) with added support for querying the device's **actual camera resolutions** instead of being limited to abstract presets.

## Why This Fork?

The official Flutter camera plugin only provides **resolution presets** like `ResolutionPreset.max`, `ResolutionPreset.high`, `ResolutionPreset.medium`, etc. These presets:

- ❌ Don't tell you the actual resolution (width × height)
- ❌ Map to different resolutions on different devices
- ❌ Don't let you choose specific resolutions you need
- ❌ Make it impossible to show users what resolution they're actually using
- ❌ Prevent precise control over photo and video quality

### The Problem

**For Photos:**
You can't query what photo resolutions are actually available. You're stuck with vague presets and no way to let users choose "4K" vs "8MP" vs "1080p" for photos.

**For Videos:**
Even worse - photo resolutions may not be supported by the video encoder! Trying to record video at a photo resolution can cause:
- Recording failures
- Crashes during video capture
- No way to query which resolutions actually work for video

### The Solution

This fork adds **two new APIs** that expose the device's actual camera capabilities:

**1. `availableCameraResolutions()`** - Get all photo resolutions
Returns all resolutions supported by the camera sensor (e.g., 4000×3000, 3264×2448, 1920×1080)

**2. `availableCameraVideoResolutions()`** - Get video-capable resolutions
Returns resolutions guaranteed to work for video recording via CamcorderProfile (e.g., 3840×2160, 1920×1080, 1280×720)

## What's New

### New API Methods

**1. Photo Resolutions API**
```dart
/// Returns all available resolutions for the specified camera.
///
/// Returns a list of [CameraResolution] objects representing all
/// resolutions supported by the camera sensor for photo/video capture.
/// This gives you actual pixel dimensions instead of abstract presets.
Future<List<CameraResolution>> availableCameraResolutions(
  CameraDescription cameraDescription,
);
```

**2. Video Resolutions API**
```dart
/// Get available video resolutions for a camera.
///
/// Returns resolutions supported by CamcorderProfile for video recording.
/// These resolutions are guaranteed to be usable for video recording,
/// unlike [availableCameraResolutions] which returns all sensor resolutions
/// that may not be supported by the video encoder.
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

  // PHOTO MODE: Get all available photo resolutions
  final photoResolutions = await availableCameraResolutions(backCamera);
  print('Photo resolutions available: ${photoResolutions.length}');
  photoResolutions.forEach((res) {
    print('  ${res.width}×${res.height} @ ${res.minFps}-${res.maxFps}fps');
  });
  // Example output:
  // Photo resolutions available: 15
  //   4000×3000 @ 15-30fps
  //   3264×2448 @ 15-30fps
  //   1920×1080 @ 15-30fps
  //   1280×720 @ 15-30fps

  // Pick highest photo resolution
  final bestPhotoResolution = photoResolutions.reduce((a, b) =>
    (a.width * a.height) > (b.width * b.height) ? a : b
  );

  // VIDEO MODE: Get video-capable resolutions only
  final videoResolutions = await availableCameraVideoResolutions(backCamera);
  print('Video resolutions available: ${videoResolutions.length}');
  videoResolutions.forEach((res) {
    print('  ${res.width}×${res.height} @ ${res.minFps}-${res.maxFps}fps');
  });
  // Example output:
  // Video resolutions available: 5
  //   3840×2160 @ 15-30fps  (4K)
  //   1920×1080 @ 15-30fps  (1080p)
  //   1280×720 @ 15-30fps   (720p)
  //   640×480 @ 15-30fps    (480p)

  // Pick highest video resolution
  final bestVideoResolution = videoResolutions.reduce((a, b) =>
    (a.width * a.height) > (b.width * b.height) ? a : b
  );

  // Create camera controller with chosen resolution
  final controller = CameraController.withResolution(
    backCamera,
    isVideoMode ? bestVideoResolution : bestPhotoResolution,
    enableAudio: isVideoMode,
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

## Comparison: Presets vs Direct Resolution Access

### Before (Official Plugin - Preset-Based)
```dart
// Official plugin only has vague presets
final controller = CameraController(
  camera,
  ResolutionPreset.max,  // What resolution is this? 🤷
);

// Problems:
// ❌ Can't query available resolutions
// ❌ Can't show users what resolution they're using
// ❌ Can't let users choose specific resolutions
// ❌ "max" might be 4K on one device, 1080p on another
// ❌ No way to know if a resolution works for video
```

### After (This Fork - Direct Access)
```dart
// Get ALL photo resolutions (sensor capabilities)
final photoResolutions = await availableCameraResolutions(camera);
// Returns: [4000×3000, 3264×2448, 1920×1080, 1280×720, ...]
// ✅ See exactly what the camera sensor supports
// ✅ Show users a list to choose from
// ✅ Perfect for high-quality photos

// Get video-capable resolutions (encoder-safe)
final videoResolutions = await availableCameraVideoResolutions(camera);
// Returns: [3840×2160, 1920×1080, 1280×720, 640×480, ...]
// ✅ Guaranteed to work for video recording
// ✅ No crashes or recording failures
// ✅ CamcorderProfile-verified resolutions

// Use the resolution you want
final controller = CameraController.withResolution(
  camera,
  photoResolutions.first,  // Exact control!
);
```

## Use Case

This fork was created for the [Android Folder Gallery](https://github.com/BenjaminKobjolke/android-folder-gallery) app, which needed direct control over camera resolutions for both photos and videos:

### Why It Was Needed

The app provides users with a **resolution picker** to choose their desired photo/video quality. With the official plugin's preset system, this was impossible because:

1. **Can't show actual resolutions** - Users need to see "1920×1080" not "ResolutionPreset.high"
2. **Can't guarantee video works** - Photo resolutions might fail when recording video
3. **Can't offer precise control** - Users want to choose between 4K, 1080p, 720p explicitly

### How This Fork Solves It

- **Photo Mode:** Uses `availableCameraResolutions()` to show all available sensor resolutions
- **Video Mode:** Uses `availableCameraVideoResolutions()` to show only encoder-safe resolutions
- **User Control:** Users see actual pixel dimensions and can choose exactly what they want
- **Reliability:** Video mode only shows resolutions guaranteed to work by CamcorderProfile

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
