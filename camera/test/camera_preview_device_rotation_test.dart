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
      'when orientation not locked, not recording, and device orientation is portrait up, rotatedBox should not be rotated',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final FakeController controller = FakeController();
        addTearDown(controller.dispose);

        controller.value = controller.value.copyWith(
          isInitialized: true,
          deviceOrientation: DeviceOrientation.portraitUp,
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
        expect(rotatedBox.quarterTurns, 0);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'when orientation not locked, not recording, and device orientation is landscape right, rotatedBox should be rotated by one clockwise quarter turn',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final FakeController controller = FakeController();
        addTearDown(controller.dispose);

        controller.value = controller.value.copyWith(
          isInitialized: true,
          deviceOrientation: DeviceOrientation.landscapeRight,
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
        expect(rotatedBox.quarterTurns, 1);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'when orientation not locked, not recording, and device orientation is portrait down, rotatedBox should be rotated by two clockwise quarter turns',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final FakeController controller = FakeController();
        addTearDown(controller.dispose);

        controller.value = controller.value.copyWith(
          isInitialized: true,
          deviceOrientation: DeviceOrientation.portraitDown,
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
        expect(rotatedBox.quarterTurns, 2);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'when orientation not locked, not recording, and device orientation is landscape left, rotatedBox should be rotated by three clockwise quarter turns',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        final FakeController controller = FakeController();
        addTearDown(controller.dispose);

        controller.value = controller.value.copyWith(
          isInitialized: true,
          deviceOrientation: DeviceOrientation.landscapeLeft,
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
        expect(rotatedBox.quarterTurns, 3);

        debugDefaultTargetPlatformOverride = null;
      },
    );
  }, skip: kIsWeb);
}
