// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'camera_preview_test.dart';

void main() {
  group('RotatedBox (Android only)', () {
testWidgets(
      'when recording in DeviceOrientaiton.portraitUp, rotatedBox should not be rotated',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final FakeController controller = FakeController();
        addTearDown(controller.dispose);

        controller.value = controller.value.copyWith(
          isInitialized: true,
          isRecordingVideo: true,
          deviceOrientation: DeviceOrientation.portraitDown,
          lockedCaptureOrientation:
              const Optional<DeviceOrientation>.fromNullable(
                DeviceOrientation.landscapeRight,
              ),
          recordingOrientation: const Optional<DeviceOrientation>.fromNullable(
            DeviceOrientation.portraitUp,
          ),
          previewSize: const Size(480, 640), // preview size irrelevant to test
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CameraPreview(controller),
          ),
        );
        expect(find.byType(RotatedBox), findsOneWidget);

        final RotatedBox rotatedBox = tester.widget<RotatedBox>(
          find.byType(RotatedBox),
        );
        expect(rotatedBox.quarterTurns, 0);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'when recording in DeviceOrientaiton.landscapeRight, rotatedBox should be rotated by one clockwise quarter turn',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final FakeController controller = FakeController();
        addTearDown(controller.dispose);

        controller.value = controller.value.copyWith(
          isInitialized: true,
          isRecordingVideo: true,
          deviceOrientation: DeviceOrientation.portraitUp,
          lockedCaptureOrientation:
              const Optional<DeviceOrientation>.fromNullable(
                DeviceOrientation.landscapeLeft,
              ),
          recordingOrientation: const Optional<DeviceOrientation>.fromNullable(
            DeviceOrientation.landscapeRight,
          ),
          previewSize: const Size(480, 640), // preview size irrelevant to test
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CameraPreview(controller),
          ),
        );
        expect(find.byType(RotatedBox), findsOneWidget);

        final RotatedBox rotatedBox = tester.widget<RotatedBox>(
          find.byType(RotatedBox),
        );
        expect(rotatedBox.quarterTurns, 1);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'when recording in DeviceOrientaiton.portraitDown, rotatedBox should be rotated by two clockwise quarter turns',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final FakeController controller = FakeController();
        addTearDown(controller.dispose);

        controller.value = controller.value.copyWith(
          isInitialized: true,
          isRecordingVideo: true,
          deviceOrientation: DeviceOrientation.portraitUp,
          lockedCaptureOrientation:
              const Optional<DeviceOrientation>.fromNullable(
                DeviceOrientation.landscapeRight,
              ),
          recordingOrientation: const Optional<DeviceOrientation>.fromNullable(
            DeviceOrientation.portraitDown,
          ),
          previewSize: const Size(480, 640), // preview size irrelevant to test
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CameraPreview(controller),
          ),
        );
        expect(find.byType(RotatedBox), findsOneWidget);

        final RotatedBox rotatedBox = tester.widget<RotatedBox>(
          find.byType(RotatedBox),
        );
        expect(rotatedBox.quarterTurns, 2);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'when recording in DeviceOrientaiton.landscapeLeft, rotatedBox should be rotated by three clockwise quarter turns',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final FakeController controller = FakeController();
        addTearDown(controller.dispose);

        controller.value = controller.value.copyWith(
          isInitialized: true,
          isRecordingVideo: true,
          deviceOrientation: DeviceOrientation.portraitUp,
          lockedCaptureOrientation:
              const Optional<DeviceOrientation>.fromNullable(
                DeviceOrientation.landscapeRight,
              ),
          recordingOrientation: const Optional<DeviceOrientation>.fromNullable(
            DeviceOrientation.landscapeLeft,
          ),
          previewSize: const Size(480, 640), // preview size irrelevant to test
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CameraPreview(controller),
          ),
        );
        expect(find.byType(RotatedBox), findsOneWidget);

        final RotatedBox rotatedBox = tester.widget<RotatedBox>(
          find.byType(RotatedBox),
        );
        expect(rotatedBox.quarterTurns, 3);

        debugDefaultTargetPlatformOverride = null;
      },
    );
  }, skip: kIsWeb);
}
