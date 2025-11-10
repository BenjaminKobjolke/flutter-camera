// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Represents a camera resolution with dimensions and FPS range.
@immutable
class CameraResolution {
  /// Creates a [CameraResolution].
  const CameraResolution({
    required this.width,
    required this.height,
    required this.minFps,
    required this.maxFps,
  });

  /// The width of the resolution in pixels.
  final int width;

  /// The height of the resolution in pixels.
  final int height;

  /// The minimum frames per second supported at this resolution.
  final int minFps;

  /// The maximum frames per second supported at this resolution.
  final int maxFps;

  /// Returns the aspect ratio (width / height) of this resolution.
  double get aspectRatio => width / height;

  /// Returns a human-readable string representation like "1920x1080 (30-60fps)".
  @override
  String toString() => '${width}x$height ($minFps-${maxFps}fps)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CameraResolution &&
        other.width == width &&
        other.height == height &&
        other.minFps == minFps &&
        other.maxFps == maxFps;
  }

  @override
  int get hashCode => Object.hash(width, height, minFps, maxFps);
}
