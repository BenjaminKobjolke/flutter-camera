// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera.features.resolution;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.hardware.camera2.CaptureRequest;
import android.media.CamcorderProfile;
import android.media.EncoderProfiles;
import android.os.Build;
import android.util.Size;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.plugins.camera.CameraProperties;
import io.flutter.plugins.camera.SdkCapabilityChecker;
import io.flutter.plugins.camera.features.CameraFeature;
import java.util.List;

/**
 * Controls the resolutions configuration on the {@link android.hardware.camera2} API.
 *
 * <p>The {@link ResolutionFeature} is responsible for configuring the camera resolution
 * using the {@link android.hardware.camera2} API.
 */
public class ResolutionFeature extends CameraFeature<Size> {
  @Nullable private Size captureSize;
  @Nullable private Size previewSize;
  private CamcorderProfile recordingProfileLegacy;
  private EncoderProfiles recordingProfile;
  @NonNull private Size currentSetting;
  private int cameraId;

  /**
   * Creates a new instance of the {@link ResolutionFeature}.
   *
   * @param cameraProperties Collection of characteristics for the current camera device.
   * @param resolution The desired resolution for camera capture.
   * @param cameraName Camera identifier of the camera for which to configure the resolution.
   */
  public ResolutionFeature(
      @NonNull CameraProperties cameraProperties,
      @NonNull Size resolution,
      @NonNull String cameraName) {
    super(cameraProperties);
    this.currentSetting = resolution;
    try {
      this.cameraId = Integer.parseInt(cameraName, 10);
    } catch (NumberFormatException e) {
      this.cameraId = -1;
      return;
    }
    configureResolution(resolution, cameraId);
  }

  /**
   * Gets the {@link android.media.CamcorderProfile} containing the information to configure the
   * resolution using the {@link android.hardware.camera2} API.
   *
   * @return Resolution information to configure the {@link android.hardware.camera2} API.
   */
  @Nullable
  public CamcorderProfile getRecordingProfileLegacy() {
    return this.recordingProfileLegacy;
  }

  @Nullable
  public EncoderProfiles getRecordingProfile() {
    return this.recordingProfile;
  }

  /**
   * Gets the optimal preview size based on the configured resolution.
   *
   * @return The optimal preview size.
   */
  @Nullable
  public Size getPreviewSize() {
    return this.previewSize;
  }

  /**
   * Gets the optimal capture size based on the configured resolution.
   *
   * @return The optimal capture size.
   */
  @Nullable
  public Size getCaptureSize() {
    return this.captureSize;
  }

  @NonNull
  @Override
  public String getDebugName() {
    return "ResolutionFeature";
  }

  @SuppressLint("KotlinPropertyAccess")
  @NonNull
  @Override
  public Size getValue() {
    return currentSetting;
  }

  @Override
  public void setValue(@NonNull Size value) {
    this.currentSetting = value;
    configureResolution(currentSetting, cameraId);
  }

  @Override
  public boolean checkIsSupported() {
    return cameraId >= 0;
  }

  @Override
  public void updateBuilder(@NonNull CaptureRequest.Builder requestBuilder) {
    // No-op: when setting a resolution there is no need to update the request builder.
  }

  @VisibleForTesting
  static Size computeBestPreviewSize(int cameraId, ResolutionPreset preset)
      throws IndexOutOfBoundsException {
    if (preset.ordinal() > ResolutionPreset.high.ordinal()) {
      preset = ResolutionPreset.high;
    }
    if (SdkCapabilityChecker.supportsEncoderProfiles()) {
      EncoderProfiles profile =
          getBestAvailableCamcorderProfileForResolutionPreset(cameraId, preset);
      List<EncoderProfiles.VideoProfile> videoProfiles = profile.getVideoProfiles();
      EncoderProfiles.VideoProfile defaultVideoProfile = videoProfiles.get(0);

      if (defaultVideoProfile != null) {
        return new Size(defaultVideoProfile.getWidth(), defaultVideoProfile.getHeight());
      }
    }

    // TODO(camsim99): Suppression is currently safe because legacy code is used as a fallback for SDK < S.
    // This should be removed when reverting that fallback behavior: https://github.com/flutter/flutter/issues/119668.
    CamcorderProfile profile =
        getBestAvailableCamcorderProfileForResolutionPresetLegacy(cameraId, preset);
    return new Size(profile.videoFrameWidth, profile.videoFrameHeight);
  }

  /**
   * Computes the best preview size based on capture resolution dimensions.
   * Simply returns the provided dimensions as the preview size.
   *
   * @param width The width of the capture resolution.
   * @param height The height of the capture resolution.
   * @return The computed preview size.
   */
  @VisibleForTesting
  static Size computeBestPreviewSize(int width, int height) {
    return new Size(width, height);
  }

  /**
   * Gets the best possible {@link android.media.CamcorderProfile} for the supplied {@link
   * ResolutionPreset}. Supports SDK < 31.
   *
   * @param cameraId Camera identifier which indicates the device's camera for which to select a
   *     {@link android.media.CamcorderProfile}.
   * @param preset The {@link ResolutionPreset} for which is to be translated to a {@link
   *     android.media.CamcorderProfile}.
   * @return The best possible {@link android.media.CamcorderProfile} that matches the supplied
   *     {@link ResolutionPreset}.
   */
  @SuppressLint("UseRequiresApi")
  @TargetApi(Build.VERSION_CODES.R)
  // All of these cases deliberately fall through to get the best available profile.
  @SuppressWarnings({"fallthrough", "deprecation"})
  @NonNull
  public static CamcorderProfile getBestAvailableCamcorderProfileForResolutionPresetLegacy(
      int cameraId, @NonNull ResolutionPreset preset) {
    if (cameraId < 0) {
      throw new AssertionError(
          "getBestAvailableCamcorderProfileForResolutionPreset can only be used with valid (>=0) camera identifiers.");
    }

    switch (preset) {
      case max:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_HIGH)) {
          return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_HIGH);
        }
        // fall through
      case ultraHigh:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_2160P)) {
          return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_2160P);
        }
        // fall through
      case veryHigh:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_1080P)) {
          return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_1080P);
        }
        // fall through
      case high:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_720P)) {
          return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_720P);
        }
        // fall through
      case medium:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_480P)) {
          return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_480P);
        }
        // fall through
      case low:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_QVGA)) {
          return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_QVGA);
        }
        // fall through
      default:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
          return CamcorderProfile.get(cameraId, CamcorderProfile.QUALITY_LOW);
        } else {
          throw new IllegalArgumentException(
              "No capture session available for current capture session.");
        }
    }
  }

  @SuppressLint("UseRequiresApi")
  @TargetApi(Build.VERSION_CODES.S)
  // All of these cases deliberately fall through to get the best available profile.
  @SuppressWarnings("fallthrough")
  @NonNull
  public static EncoderProfiles getBestAvailableCamcorderProfileForResolutionPreset(
      int cameraId, @NonNull ResolutionPreset preset) {
    if (cameraId < 0) {
      throw new AssertionError(
          "getBestAvailableCamcorderProfileForResolutionPreset can only be used with valid (>=0) camera identifiers.");
    }

    String cameraIdString = Integer.toString(cameraId);

    switch (preset) {
      case max:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_HIGH)) {
          return CamcorderProfile.getAll(cameraIdString, CamcorderProfile.QUALITY_HIGH);
        }
        // fall through
      case ultraHigh:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_2160P)) {
          return CamcorderProfile.getAll(cameraIdString, CamcorderProfile.QUALITY_2160P);
        }
        // fall through
      case veryHigh:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_1080P)) {
          return CamcorderProfile.getAll(cameraIdString, CamcorderProfile.QUALITY_1080P);
        }
        // fall through
      case high:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_720P)) {
          return CamcorderProfile.getAll(cameraIdString, CamcorderProfile.QUALITY_720P);
        }
        // fall through
      case medium:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_480P)) {
          return CamcorderProfile.getAll(cameraIdString, CamcorderProfile.QUALITY_480P);
        }
        // fall through
      case low:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_QVGA)) {
          return CamcorderProfile.getAll(cameraIdString, CamcorderProfile.QUALITY_QVGA);
        }
        // fall through
      default:
        if (CamcorderProfile.hasProfile(cameraId, CamcorderProfile.QUALITY_LOW)) {
          return CamcorderProfile.getAll(cameraIdString, CamcorderProfile.QUALITY_LOW);
        }

        throw new IllegalArgumentException(
            "No capture session available for current capture session.");
    }
  }

  private void configureResolution(Size resolution, int cameraId) {
    if (!checkIsSupported()) {
      return;
    }

    // Directly use the provided resolution
    this.captureSize = resolution;
    this.previewSize = computeBestPreviewSize(resolution.getWidth(), resolution.getHeight());

    // Find the best matching CamcorderProfile for video recording
    // This is critical for video recording to work with custom resolutions
    if (SdkCapabilityChecker.supportsEncoderProfiles()) {
      this.recordingProfile = findBestEncoderProfileForSize(cameraId, resolution);
    } else {
      this.recordingProfileLegacy = findBestCamcorderProfileForSize(cameraId, resolution);
    }
  }

  /**
   * Finds the best matching EncoderProfiles for the given resolution.
   * Tries to find a profile with the closest resolution to the target.
   *
   * @param cameraId Camera identifier
   * @param targetSize Target resolution
   * @return EncoderProfiles matching the target resolution, or null if not found
   */
  @TargetApi(Build.VERSION_CODES.S)
  @Nullable
  private EncoderProfiles findBestEncoderProfileForSize(int cameraId, Size targetSize) {
    if (cameraId < 0) return null;

    String cameraIdString = Integer.toString(cameraId);
    int targetPixels = targetSize.getWidth() * targetSize.getHeight();

    // Try exact matches first with standard quality levels
    int[] qualityLevels = {
      CamcorderProfile.QUALITY_2160P, // 4K
      CamcorderProfile.QUALITY_1080P, // 1080p
      CamcorderProfile.QUALITY_720P,  // 720p
      CamcorderProfile.QUALITY_480P,  // 480p
      CamcorderProfile.QUALITY_QVGA,  // QVGA
      CamcorderProfile.QUALITY_HIGH,  // Highest available
      CamcorderProfile.QUALITY_LOW    // Lowest available
    };

    EncoderProfiles bestMatch = null;
    int smallestDifference = Integer.MAX_VALUE;

    for (int quality : qualityLevels) {
      if (CamcorderProfile.hasProfile(cameraId, quality)) {
        try {
          EncoderProfiles profile = CamcorderProfile.getAll(cameraIdString, quality);
          if (profile != null && !profile.getVideoProfiles().isEmpty()) {
            EncoderProfiles.VideoProfile videoProfile = profile.getVideoProfiles().get(0);
            int profilePixels = videoProfile.getWidth() * videoProfile.getHeight();
            int difference = Math.abs(profilePixels - targetPixels);

            if (difference < smallestDifference) {
              smallestDifference = difference;
              bestMatch = profile;
            }

            // If exact match found, return immediately
            if (difference == 0) {
              return bestMatch;
            }
          }
        } catch (Exception e) {
          // Continue to next profile if this one fails
        }
      }
    }

    return bestMatch;
  }

  /**
   * Finds the best matching CamcorderProfile for the given resolution (legacy).
   * Tries to find a profile with the closest resolution to the target.
   *
   * @param cameraId Camera identifier
   * @param targetSize Target resolution
   * @return CamcorderProfile matching the target resolution, or null if not found
   */
  @SuppressWarnings("deprecation")
  @Nullable
  private CamcorderProfile findBestCamcorderProfileForSize(int cameraId, Size targetSize) {
    if (cameraId < 0) return null;

    int targetPixels = targetSize.getWidth() * targetSize.getHeight();

    // Try exact matches first with standard quality levels
    int[] qualityLevels = {
      CamcorderProfile.QUALITY_2160P, // 4K
      CamcorderProfile.QUALITY_1080P, // 1080p
      CamcorderProfile.QUALITY_720P,  // 720p
      CamcorderProfile.QUALITY_480P,  // 480p
      CamcorderProfile.QUALITY_QVGA,  // QVGA
      CamcorderProfile.QUALITY_HIGH,  // Highest available
      CamcorderProfile.QUALITY_LOW    // Lowest available
    };

    CamcorderProfile bestMatch = null;
    int smallestDifference = Integer.MAX_VALUE;

    for (int quality : qualityLevels) {
      if (CamcorderProfile.hasProfile(cameraId, quality)) {
        try {
          CamcorderProfile profile = CamcorderProfile.get(cameraId, quality);
          if (profile != null) {
            int profilePixels = profile.videoFrameWidth * profile.videoFrameHeight;
            int difference = Math.abs(profilePixels - targetPixels);

            if (difference < smallestDifference) {
              smallestDifference = difference;
              bestMatch = profile;
            }

            // If exact match found, return immediately
            if (difference == 0) {
              return bestMatch;
            }
          }
        } catch (Exception e) {
          // Continue to next profile if this one fails
        }
      }
    }

    return bestMatch;
  }
}
