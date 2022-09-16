// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/dart_file_open_dialog_api.dart';
import 'package:file_selector_windows/src/dart_file_selector_api.dart';
import 'package:file_selector_windows/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:win32/win32.dart';
import 'dart_file_selector_api_test.mocks.dart';

@GenerateMocks(<Type>[FileOpenDialogAPI])
void main() {
  const int defaultReturnValue = 1;
  const String defaultPath = 'C://';
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockFileOpenDialogAPI mockFileOpenDialogAPI = MockFileOpenDialogAPI();
  late DartFileSelectorAPI api;
  late Pointer<Uint32> options;
  late int hResult;
  late FileOpenDialog dialog;

  tearDown(() {
    reset(mockFileOpenDialogAPI);
  });
  group('#Isolated functions', () {
    setUp(() {
      api = DartFileSelectorAPI(mockFileOpenDialogAPI);
      options = calloc<Uint32>();
      hResult = 0;
      api.initializeComLibrary();
      dialog = FileOpenDialog.createInstance();
      setDefaultMocks(mockFileOpenDialogAPI, defaultReturnValue, defaultPath);
    });

    test('setDirectoryOptions should call dialog setOptions', () {
      const int expectedDirectoryOptions = 2144;
      expect(defaultReturnValue,
          api.setDirectoryOptions(options, hResult, dialog));
      verify(mockFileOpenDialogAPI.setOptions(expectedDirectoryOptions, dialog))
          .called(1);
    });

    test('getOptions should call dialog getOptions', () {
      final Pointer<Uint32> pfos = calloc<Uint32>();
      expect(defaultReturnValue, api.getOptions(pfos, hResult, dialog));
      verify(mockFileOpenDialogAPI.getOptions(pfos, dialog))
          .called(defaultReturnValue);
    });

    test('addConfirmButtonLabel should call dialog setOkButtonLabel', () {
      const String confirmationText = 'Text';
      expect(defaultReturnValue,
          api.addConfirmButtonLabel(dialog, confirmationText));
      verify(mockFileOpenDialogAPI.setOkButtonLabel(confirmationText, dialog))
          .called(defaultReturnValue);
    });

    test('addFileFilters should call dialog setFileTypes', () {
      final TypeGroup typeGroup =
          TypeGroup(extensions: <String?>['jpg', 'png'], label: 'Images');

      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: true,
        selectFolders: true,
        allowedTypes: <TypeGroup?>[typeGroup],
      );

      final Map<String, String> filterSpecification = <String, String>{
        'Images': '*.jpg;*.png;',
      };

      expect(defaultReturnValue,
          api.addFileFilters(hResult, dialog, selectionOptions));
      verify(mockFileOpenDialogAPI.setFileTypes(
              filterSpecification, hResult, dialog))
          .called(1);
    });

    test(
        'addFileFilters should not call dialog setFileTypes if filterSpecification is empty',
        () {
      final TypeGroup typeGroup =
          TypeGroup(extensions: <String?>[], label: 'Images');

      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: true,
        selectFolders: true,
        allowedTypes: <TypeGroup?>[typeGroup],
      );

      expect(hResult, api.addFileFilters(hResult, dialog, selectionOptions));
      verifyNever(mockFileOpenDialogAPI.setFileTypes(any, hResult, dialog));
    });

    test(
        'returnSelectedElement should call dialog getResult and should return selected path',
        () {
      expect(defaultPath, api.returnSelectedElement(hResult, dialog));
      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
    });

    test(
        'returnSelectedElement should throw if dialog getResult returns an error',
        () {
      when(mockFileOpenDialogAPI.getResult(any, any)).thenReturn(-1);
      try {
        api.returnSelectedElement(hResult, dialog);
        expect(false, true);
      } on WindowsException catch (_) {
        expect(true, true);
      }

      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
      verifyNever(mockFileOpenDialogAPI.getDisplayName(any, any));
    });

    test(
        'returnSelectedElement should throw if dialog getDisplayName returns an error',
        () {
      when(mockFileOpenDialogAPI.getDisplayName(any, any)).thenReturn(-1);
      try {
        api.returnSelectedElement(hResult, dialog);
        expect(false, true);
      } on WindowsException catch (_) {
        expect(true, true);
      }

      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
      verify(mockFileOpenDialogAPI.getDisplayName(any, any)).called(1);
    });

    test(
        'returnSelectedElement should throw if dialog releaseItem returns an error',
        () {
      when(mockFileOpenDialogAPI.releaseItem(any)).thenReturn(-1);
      try {
        api.returnSelectedElement(hResult, dialog);
        expect(false, true);
      } on WindowsException catch (_) {
        expect(true, true);
      }

      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
      verify(mockFileOpenDialogAPI.getDisplayName(any, any)).called(1);
      verify(mockFileOpenDialogAPI.releaseItem(any)).called(1);
    });

    test(
        'returnSelectedElement should throw if dialog release returns an error',
        () {
      when(mockFileOpenDialogAPI.release(any)).thenReturn(-1);
      try {
        api.returnSelectedElement(hResult, dialog);
        expect(false, true);
      } on WindowsException catch (_) {
        expect(true, true);
      }

      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
      verify(mockFileOpenDialogAPI.getDisplayName(any, any)).called(1);
      verify(mockFileOpenDialogAPI.releaseItem(any)).called(1);
      verify(mockFileOpenDialogAPI.release(any)).called(1);
    });

    test(
        'returnSelectedElement should return without a path when the user cancels interaction',
        () {
      const int cancelledhResult = -2147023673;
      expect(null, api.returnSelectedElement(cancelledhResult, dialog));
      verifyNever(mockFileOpenDialogAPI.getResult(any, dialog));
      verifyNever(mockFileOpenDialogAPI.getDisplayName(any, any));
      verifyNever(mockFileOpenDialogAPI.getUserSelectedPath(any));
      verify(mockFileOpenDialogAPI.release(dialog)).called(1);
    });

    test('returnSelectedElement should call dialog release', () {
      expect(defaultPath, api.returnSelectedElement(hResult, dialog));
      verify(mockFileOpenDialogAPI.release(dialog)).called(1);
    });

    test('returnSelectedElement should call dialog getDisplayName', () {
      expect(defaultPath, api.returnSelectedElement(hResult, dialog));
      verify(mockFileOpenDialogAPI.getDisplayName(any, any)).called(1);
    });

    test('returnSelectedElement should call dialog getUserSelectedPath', () {
      expect(defaultPath, api.returnSelectedElement(hResult, dialog));
      verify(mockFileOpenDialogAPI.getUserSelectedPath(any)).called(1);
    });
  });

  group('#Public facing functions', () {
    setUp(() {
      api = DartFileSelectorAPI(mockFileOpenDialogAPI);
      options = calloc<Uint32>();
      hResult = 0;
      api.initializeComLibrary();
      dialog = FileOpenDialog.createInstance();
      setDefaultMocks(mockFileOpenDialogAPI, defaultReturnValue, defaultPath);
    });

    test('getDirectory should return selected path', () {
      expect(defaultPath, api.getDirectoryPath());
    });

    test('getFile should return selected path', () {
      final TypeGroup typeGroup =
          TypeGroup(extensions: <String?>['jpg'], label: 'Images');

      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: true,
        selectFolders: true,
        allowedTypes: <TypeGroup?>[typeGroup],
      );
      expect(defaultPath,
          api.getFile(selectionOptions, 'C://Directory', 'Choose'));
    });
  });
}

void setDefaultMocks(MockFileOpenDialogAPI mockFileOpenDialogAPI,
    int defaultReturnValue, String defaultPath) {
  when(mockFileOpenDialogAPI.setOptions(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.getOptions(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.setOkButtonLabel(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.setFileTypes(any, any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.show(any, any)).thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.getResult(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.release(any)).thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.getDisplayName(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.getUserSelectedPath(any)).thenReturn(defaultPath);
  when(mockFileOpenDialogAPI.releaseItem(any)).thenReturn(defaultReturnValue);
}
