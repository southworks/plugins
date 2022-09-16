// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/dart_file_selector_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:win32/win32.dart';
import 'dart_file_selector_api_test.mocks.dart';

@GenerateMocks(<Type>[FileOpenDialog])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockFileOpenDialog dialog = MockFileOpenDialog();

  setUp(() {
    when(dialog.setOptions(any)).thenReturn(1);
  });

  test('setDirectoryOptions call dialog setOptions', () {
    final DartFileSelectorAPI api = DartFileSelectorAPI();
    final Pointer<Uint32> options = calloc<Uint32>();
    const int hResult = 0;

    api.setDirectoryOptions(options, hResult, dialog);
    verify(dialog.setOptions(any)).called(1);
  });
}
