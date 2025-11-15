// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import android.media.Image;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import androidx.exifinterface.media.ExifInterface;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

/** Saves a JPEG {@link Image} into the specified {@link File}. */
public class ImageSaver implements Runnable {

  private static final String TAG = "ImageSaver";

  /** The JPEG image */
  private final Image image;

  /** The file we save the image into. */
  private final File file;

  /** Used to report the status of the save action. */
  private final Callback callback;

  /** The JPEG orientation in degrees (0, 90, 180, 270) */
  private final int jpegOrientation;

  /**
   * Creates an instance of the ImageSaver runnable
   *
   * @param image - The image to save
   * @param file - The file to save the image to
   * @param callback - The callback that is run on completion, or when an error is encountered.
   * @param jpegOrientation - The JPEG orientation in degrees (0, 90, 180, or 270)
   */
  ImageSaver(@NonNull Image image, @NonNull File file, @NonNull Callback callback, int jpegOrientation) {
    this.image = image;
    this.file = file;
    this.callback = callback;
    this.jpegOrientation = jpegOrientation;
  }

  @Override
  public void run() {
    ByteBuffer buffer = image.getPlanes()[0].getBuffer();
    byte[] bytes = new byte[buffer.remaining()];
    buffer.get(bytes);
    FileOutputStream output = null;
    try {
      // Write the raw JPEG bytes to file
      output = FileOutputStreamFactory.create(file);
      output.write(bytes);
      output.close();
      output = null; // Mark as closed

      Log.d(TAG, "[ORIENTATION_DEBUG] Image saved, now writing EXIF orientation: " + jpegOrientation + "°");

      // Write EXIF orientation metadata
      writeExifOrientation();

      callback.onComplete(file.getAbsolutePath());

    } catch (IOException e) {
      callback.onError("IOError", "Failed saving image");
    } finally {
      image.close();
      if (null != output) {
        try {
          output.close();
        } catch (IOException e) {
          callback.onError("cameraAccess", e.getMessage());
        }
      }
    }
  }

  /**
   * Writes EXIF orientation metadata to the saved JPEG file.
   * Converts JPEG orientation degrees (0, 90, 180, 270) to EXIF orientation values (1, 6, 3, 8).
   */
  private void writeExifOrientation() {
    try {
      ExifInterface exif = new ExifInterface(file.getAbsolutePath());

      // Convert camera sensor orientation degrees to EXIF orientation value
      // Camera sensor stores images in specific orientations regardless of device rotation
      // Mapping based on empirical testing of raw image data (EXIF stripped):
      // Sensor 0° (Portrait)         → Raw needs 90° CW  → EXIF 6 (Rotate 90° CW)
      // Sensor 90° (Landscape Left)  → Raw needs 90° CCW → EXIF 8 (Rotate 270° CW)
      // Sensor 180° (Portrait Down)  → Raw needs 90° CW  → EXIF 6 (Rotate 90° CW)
      // Sensor 270° (Landscape Right)→ Raw needs 90° CW  → EXIF 6 (Rotate 90° CW)
      // Sensor -90° (Landscape Right, alternative)→ Raw needs 180° → EXIF 3 (Rotate 180°)
      int exifOrientation;
      switch (jpegOrientation) {
        case 0:
          exifOrientation = ExifInterface.ORIENTATION_ROTATE_90;
          break;
        case 90:
          exifOrientation = ExifInterface.ORIENTATION_ROTATE_270;
          break;
        case 180:
          exifOrientation = ExifInterface.ORIENTATION_ROTATE_90;
          break;
        case 270:
          exifOrientation = ExifInterface.ORIENTATION_ROTATE_90;
          break;
        case -90:
          exifOrientation = ExifInterface.ORIENTATION_ROTATE_180;
          break;
        default:
          Log.w(TAG, "[ORIENTATION_DEBUG] ⚠️ Unknown JPEG orientation: " + jpegOrientation + "°, defaulting to ROTATE_90");
          exifOrientation = ExifInterface.ORIENTATION_ROTATE_90;
          break;
      }

      exif.setAttribute(ExifInterface.TAG_ORIENTATION, String.valueOf(exifOrientation));
      exif.saveAttributes();

      Log.d(TAG, "[ORIENTATION_DEBUG] ✅ EXIF orientation written: " + exifOrientation + " (from " + jpegOrientation + "°)");

    } catch (IOException e) {
      Log.e(TAG, "[ORIENTATION_DEBUG] ❌ Failed to write EXIF orientation: " + e.getMessage());
    }
  }

  /**
   * The interface for the callback that is passed to ImageSaver, for detecting completion or
   * failure of the image saving task.
   */
  public interface Callback {
    /**
     * Called when the image file has been saved successfully.
     *
     * @param absolutePath - The absolute path of the file that was saved.
     */
    void onComplete(@NonNull String absolutePath);

    /**
     * Called when an error is encountered while saving the image file.
     *
     * @param errorCode - The error code.
     * @param errorMessage - The human readable error message.
     */
    void onError(@NonNull String errorCode, @NonNull String errorMessage);
  }

  /** Factory class that assists in creating a {@link FileOutputStream} instance. */
  static class FileOutputStreamFactory {
    /**
     * Creates a new instance of the {@link FileOutputStream} class.
     *
     * <p>This method is visible for testing purposes only and should never be used outside this *
     * class.
     *
     * @param file - The file to create the output stream for
     * @return new instance of the {@link FileOutputStream} class.
     * @throws FileNotFoundException when the supplied file could not be found.
     */
    @VisibleForTesting
    public static FileOutputStream create(File file) throws FileNotFoundException {
      return new FileOutputStream(file);
    }
  }
}
