// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/dart_file_open_dialog_api.dart';
import 'package:file_selector_windows/src/dart_file_selector_api.dart';
import 'package:file_selector_windows/src/dart_shell_item_api.dart';
import 'package:file_selector_windows/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:win32/win32.dart';
import 'dart_file_selector_api_test.mocks.dart';

@GenerateMocks(<Type>[FileOpenDialogAPI, ShellItemAPI])
void main() {
  const int defaultReturnValue = 1;
  const int successReturnValue = 0;
  const String defaultPath = 'C:';
  const List<String> expectedPaths = <String>[defaultPath];
  const List<String> expectedMultiplePaths = <String>[defaultPath, defaultPath];
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockFileOpenDialogAPI mockFileOpenDialogAPI = MockFileOpenDialogAPI();
  final MockShellItemAPI mockShellItemAPI = MockShellItemAPI();
  late DartFileSelectorAPI api;
  late Pointer<Uint32> ptrOptions;
  late int hResult;
  late FileOpenDialog dialog;

  tearDown(() {
    reset(mockFileOpenDialogAPI);
    reset(mockShellItemAPI);
  });

  group('#Isolated functions', () {
    final TypeGroup imagesTypeGroup =
        TypeGroup(extensions: <String?>[], label: 'Images');
    final SelectionOptions singleFileSelectionOptions = SelectionOptions(
      allowMultiple: false,
      selectFolders: false,
      allowedTypes: <TypeGroup?>[imagesTypeGroup],
    );

    setUp(() {
      api = DartFileSelectorAPI(mockFileOpenDialogAPI, mockShellItemAPI);
      ptrOptions = calloc<Uint32>();
      hResult = 0;
      api.initializeComLibrary();
      dialog = FileOpenDialog.createInstance();
      setDefaultMocks(mockFileOpenDialogAPI, mockShellItemAPI,
          successReturnValue, defaultReturnValue, defaultPath);
    });

    test('setDirectoryOptions should call dialog setOptions', () {
      final SelectionOptions selectOptions = SelectionOptions(
          allowMultiple: false,
          selectFolders: true,
          allowedTypes: <TypeGroup>[]);
      expect(defaultReturnValue,
          api.setDialogOptions(ptrOptions, selectOptions, dialog));
      verify(mockFileOpenDialogAPI.setOptions(any, any)).called(1);
    });

    test('getOptions should call dialog getOptions', () {
      final Pointer<Uint32> pfos = calloc<Uint32>();
      expect(defaultReturnValue, api.getOptions(pfos, dialog));
      verify(mockFileOpenDialogAPI.getOptions(pfos, dialog))
          .called(defaultReturnValue);
    });

    test('addConfirmButtonLabel should call dialog setOkButtonLabel', () {
      const String confirmationText = 'Text';
      expect(defaultReturnValue,
          api.addConfirmButtonLabel(confirmationText, dialog));
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

      expect(defaultReturnValue, api.addFileFilters(selectionOptions, dialog));
      verify(mockFileOpenDialogAPI.setFileTypes(filterSpecification, dialog))
          .called(1);
    });

    test(
        'invoking addFileFilters twice should call dialog setFileTypes with proper parameters',
        () {
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

      expect(defaultReturnValue, api.addFileFilters(selectionOptions, dialog));
      expect(defaultReturnValue, api.addFileFilters(selectionOptions, dialog));
      verify(mockFileOpenDialogAPI.setFileTypes(filterSpecification, dialog))
          .called(2);
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

      expect(successReturnValue, api.addFileFilters(selectionOptions, dialog));
      verifyNever(mockFileOpenDialogAPI.setFileTypes(any, dialog));
    });

    test(
        'returnSelectedElements should call dialog getResult and should return selected path',
        () {
      expect(
          expectedPaths,
          api.returnSelectedElements(
              hResult, singleFileSelectionOptions, dialog));
      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
    });

    test(
        'returnSelectedElements should throw if dialog getResult returns an error',
        () {
      when(mockFileOpenDialogAPI.getResult(any, any)).thenReturn(-1);
      try {
        api.returnSelectedElements(hResult, singleFileSelectionOptions, dialog);
        expect(false, true);
      } on WindowsException catch (_) {
        expect(true, true);
      }

      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
      verifyNever(mockShellItemAPI.getDisplayName(any, any));
    });

    test(
        'returnSelectedElements should throw if dialog getDisplayName returns an error',
        () {
      when(mockShellItemAPI.getDisplayName(any, any)).thenReturn(-1);
      try {
        api.returnSelectedElements(hResult, singleFileSelectionOptions, dialog);
        expect(false, true);
      } on WindowsException catch (_) {
        expect(true, true);
      }

      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
      verify(mockShellItemAPI.getDisplayName(any, any)).called(1);
    });

    test(
        'returnSelectedElements should throw if dialog releaseItem returns an error',
        () {
      when(mockShellItemAPI.releaseItem(any)).thenReturn(-1);
      try {
        api.returnSelectedElements(hResult, singleFileSelectionOptions, dialog);
        expect(false, true);
      } on WindowsException catch (_) {
        expect(true, true);
      }

      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
      verify(mockShellItemAPI.getDisplayName(any, any)).called(1);
      verify(mockShellItemAPI.releaseItem(any)).called(1);
    });

    test(
        'returnSelectedElements should throw if dialog release returns an error',
        () {
      when(mockFileOpenDialogAPI.release(any)).thenReturn(-1);
      try {
        api.returnSelectedElements(hResult, singleFileSelectionOptions, dialog);
        expect(false, true);
      } on WindowsException catch (_) {
        expect(true, true);
      }

      verify(mockFileOpenDialogAPI.getResult(any, dialog)).called(1);
      verify(mockShellItemAPI.getDisplayName(any, any)).called(1);
      verify(mockShellItemAPI.releaseItem(any)).called(1);
      verify(mockFileOpenDialogAPI.release(any)).called(1);
    });

    test(
        'returnSelectedElements should return without a path when the user cancels interaction',
        () {
      const int cancelledhResult = -2147023673;

      expect(
          <String>[],
          api.returnSelectedElements(
              cancelledhResult, singleFileSelectionOptions, dialog));

      verifyNever(mockFileOpenDialogAPI.getResult(any, dialog));
      verifyNever(mockShellItemAPI.getDisplayName(any, any));
      verifyNever(mockShellItemAPI.getUserSelectedPath(any));
      verify(mockFileOpenDialogAPI.release(dialog)).called(1);
    });

    test('returnSelectedElements should call dialog release', () {
      expect(
          expectedPaths,
          api.returnSelectedElements(
              hResult, singleFileSelectionOptions, dialog));
      verify(mockFileOpenDialogAPI.release(dialog)).called(1);
    });

    test('returnSelectedElements should call dialog getDisplayName', () {
      expect(
          expectedPaths,
          api.returnSelectedElements(
              hResult, singleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.getDisplayName(any, any)).called(1);
    });

    test('returnSelectedElements should call dialog getUserSelectedPath', () {
      expect(
          expectedPaths,
          api.returnSelectedElements(
              hResult, singleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.getUserSelectedPath(any)).called(1);
    });

    test('setInitialDirectory should return param if initialDirectory is empty',
        () {
      expect(successReturnValue, api.setInitialDirectory('', dialog));
    });

    test(
        'setInitialDirectory should return successReturnValue if initialDirectory is null',
        () {
      expect(successReturnValue, api.setInitialDirectory(null, dialog));
    });

    test('setInitialDirectory should success when initialDirectory is valid',
        () {
      expect(successReturnValue, api.setInitialDirectory(defaultPath, dialog));
    });

    test(
        'setInitialDirectory should throw WindowsException when initialDirectory is invalid',
        () {
      when(mockFileOpenDialogAPI.createItemFromParsingName(any, any, any))
          .thenReturn(-1);
      expect(() => api.setInitialDirectory(':/', dialog),
          throwsA(predicate((Object? e) => e is WindowsException)));
    });

    test('getSavePath should call setFileName', () {
      const String fileName = 'fileName';
      expect(
          defaultPath,
          api.getSavePath(
            suggestedFileName: fileName,
          ));
      verify(mockFileOpenDialogAPI.setFileName(fileName, any)).called(1);
    });

    test('getSavePath should not call setFileName without a suggestedFileName',
        () {
      const String fileName = 'fileName';
      expect(
          defaultPath,
          api.getSavePath(
            confirmButtonText: 'Choose',
            initialDirectory: defaultPath,
          ));
      verifyNever(mockFileOpenDialogAPI.setFileName(fileName, any));
    });

    test('getOptions should return 8 if fileMustExist is false', () {
      const int options = 6152;
      expect(8, api.getDialogOptions(options, singleFileSelectionOptions));
    });

    test(
        'getOptions should return 520 if fileMustExist is false and allowMultiple is true',
        () {
      const int options = 6152;
      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: true,
        selectFolders: false,
        allowedTypes: <TypeGroup?>[imagesTypeGroup],
      );
      expect(520, api.getDialogOptions(options, selectionOptions));
    });

    test(
        'getOptions should return 40 if fileMustExist is false and selectFolders is true',
        () {
      const int options = 6152;
      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: false,
        selectFolders: true,
        allowedTypes: <TypeGroup?>[imagesTypeGroup],
      );
      expect(40, api.getDialogOptions(options, selectionOptions));
    });

    test('getOptions should return 6152 if fileMustExist is true', () {
      const int options = 6152;
      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: false,
        selectFolders: false,
        allowedTypes: <TypeGroup?>[imagesTypeGroup],
      );
      api.fileMustExist = true;
      expect(6152, api.getDialogOptions(options, selectionOptions));
    });

    test(
        'getOptions should return 6664 if fileMustExist is true and allowMultiple is true',
        () {
      const int options = 6152;
      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: true,
        selectFolders: false,
        allowedTypes: <TypeGroup?>[imagesTypeGroup],
      );
      api.fileMustExist = true;
      expect(6664, api.getDialogOptions(options, selectionOptions));
    });

    test(
        'getOptions should return 6184 if fileMustExist is true and selectFolders is true',
        () {
      const int options = 6152;
      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: false,
        selectFolders: true,
        allowedTypes: <TypeGroup?>[imagesTypeGroup],
      );
      api.fileMustExist = true;
      expect(6184, api.getDialogOptions(options, selectionOptions));
    });

    test(
        'getOptions should return 6696 if fileMustExist is true, allowMultiple is true and selectFolders is true',
        () {
      const int options = 6152;
      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: true,
        selectFolders: true,
        allowedTypes: <TypeGroup?>[imagesTypeGroup],
      );
      api.fileMustExist = true;
      expect(6696, api.getDialogOptions(options, selectionOptions));
    });

    test('getSavePath should call setFolder', () {
      expect(
          defaultPath,
          api.getSavePath(
            confirmButtonText: 'Choose',
            initialDirectory: defaultPath,
          ));
      verify(mockFileOpenDialogAPI.setFolder(any, any)).called(1);
    });
  });

  group('#Multi file selection', () {
    final SelectionOptions multipleFileSelectionOptions = SelectionOptions(
      allowMultiple: true,
      selectFolders: false,
      allowedTypes: <TypeGroup?>[],
    );
    setUp(() {
      api = DartFileSelectorAPI(mockFileOpenDialogAPI, mockShellItemAPI);
      ptrOptions = calloc<Uint32>();
      hResult = 0;
      api.initializeComLibrary();
      dialog = FileOpenDialog.createInstance();
      setDefaultMocks(mockFileOpenDialogAPI, mockShellItemAPI,
          successReturnValue, defaultReturnValue, defaultPath);
    });

    test(
        'returnSelectedElements should call dialog getResults and return the paths',
        () {
      mockGetCount(mockShellItemAPI, 1);
      expect(
          expectedPaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockFileOpenDialogAPI.getResults(any, any)).called(1);
    });

    test(
        'returnSelectedElements should call createShellItemArray and return the paths',
        () {
      mockGetCount(mockShellItemAPI, 1);
      expect(
          expectedPaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.createShellItemArray(any)).called(1);
    });

    test('returnSelectedElements should call getCount and return the paths',
        () {
      mockGetCount(mockShellItemAPI, 1);
      expect(
          expectedPaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.getCount(any, any)).called(1);
    });

    test('returnSelectedElements should call getItemAt and return the paths',
        () {
      const int selectedFiles = 2;
      mockGetCount(mockShellItemAPI, selectedFiles);
      expect(
          expectedMultiplePaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.getItemAt(any, any, any)).called(selectedFiles);
    });

    test('returnSelectedElements should call release and return the paths', () {
      const int selectedFiles = 2;
      mockGetCount(mockShellItemAPI, selectedFiles);
      expect(
          expectedMultiplePaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.release(any)).called(selectedFiles);
    });

    test('returnSelectedElements should call createShellItem', () {
      const int selectedFiles = 2;
      mockGetCount(mockShellItemAPI, selectedFiles);
      expect(
          expectedMultiplePaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.createShellItem(any)).called(selectedFiles);
    });

    test('returnSelectedElements should call getDisplayName', () {
      const int selectedFiles = 2;
      mockGetCount(mockShellItemAPI, selectedFiles);
      expect(
          expectedMultiplePaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.getDisplayName(any, any)).called(selectedFiles);
    });

    test('returnSelectedElements should call getUserSelectedPath', () {
      const int selectedFiles = 2;
      mockGetCount(mockShellItemAPI, selectedFiles);
      expect(
          expectedMultiplePaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.getUserSelectedPath(any)).called(selectedFiles);
    });

    test('returnSelectedElements should call releaseItem', () {
      const int selectedFiles = 2;
      mockGetCount(mockShellItemAPI, selectedFiles);
      expect(
          expectedMultiplePaths,
          api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog));
      verify(mockShellItemAPI.releaseItem(any)).called(selectedFiles);
    });

    test(
        'returnSelectedElements should throw if dialog getResults returns an error',
        () {
      when(mockFileOpenDialogAPI.getResults(any, any)).thenReturn(-1);

      expect(
          () => api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog),
          throwsA(predicate((Object? e) => e is WindowsException)));

      verifyNever(mockShellItemAPI.createShellItemArray(any));
    });

    test('returnSelectedElements should throw if getItemAt returns an error',
        () {
      mockGetCount(mockShellItemAPI, 1);
      when(mockShellItemAPI.getItemAt(any, any, any)).thenReturn(-1);

      expect(
          () => api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog),
          throwsA(predicate((Object? e) => e is WindowsException)));

      verifyNever(mockShellItemAPI.createShellItem(any));
    });

    test(
        'returnSelectedElements should throw if getDisplayName returns an error',
        () {
      mockGetCount(mockShellItemAPI, 1);
      when(mockShellItemAPI.getDisplayName(any, any)).thenReturn(-1);

      expect(
          () => api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog),
          throwsA(predicate((Object? e) => e is WindowsException)));

      verifyNever(mockShellItemAPI.getUserSelectedPath(any));
    });

    test('returnSelectedElements should throw if releaseItem returns an error',
        () {
      mockGetCount(mockShellItemAPI, 1);
      when(mockShellItemAPI.releaseItem(any)).thenReturn(-1);

      expect(
          () => api.returnSelectedElements(
              hResult, multipleFileSelectionOptions, dialog),
          throwsA(predicate((Object? e) => e is WindowsException)));

      verifyNever(mockShellItemAPI.release(any));
    });
  });

  group('#Public facing functions', () {
    setUp(() {
      api = DartFileSelectorAPI(mockFileOpenDialogAPI, mockShellItemAPI);
      ptrOptions = calloc<Uint32>();
      hResult = 0;
      api.initializeComLibrary();
      dialog = FileOpenDialog.createInstance();
      setDefaultMocks(mockFileOpenDialogAPI, mockShellItemAPI,
          successReturnValue, defaultReturnValue, defaultPath);
    });

    test('getDirectory should return selected path', () {
      expect(defaultPath, api.getDirectoryPath());
    });

    test('getFile should return selected path', () {
      final TypeGroup typeGroup =
          TypeGroup(extensions: <String?>['jpg'], label: 'Images');

      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: false,
        selectFolders: false,
        allowedTypes: <TypeGroup?>[typeGroup],
      );
      expect(
          expectedPaths,
          api.getFiles(
              selectionOptions: selectionOptions,
              initialDirectory: 'c:',
              confirmButtonText: 'Choose'));
    });

    test('getFile with multiple selection should return selected paths', () {
      mockGetCount(mockShellItemAPI, 2);
      final TypeGroup typeGroup =
          TypeGroup(extensions: <String?>['jpg'], label: 'Images');

      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: true,
        selectFolders: false,
        allowedTypes: <TypeGroup?>[typeGroup],
      );
      expect(
          expectedMultiplePaths,
          api.getFiles(
              selectionOptions: selectionOptions,
              initialDirectory: 'c:',
              confirmButtonText: 'Choose'));
    });

    test('getSavePath should return full path with file name and extension',
        () {
      const String fileName = 'file.txt';
      when(mockShellItemAPI.getUserSelectedPath(any))
          .thenReturn('$defaultPath$fileName');
      final TypeGroup typeGroup =
          TypeGroup(extensions: <String?>['txt'], label: 'Text');

      final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: false,
        selectFolders: false,
        allowedTypes: <TypeGroup?>[typeGroup],
      );
      expect(
          '$defaultPath$fileName',
          api.getSavePath(
              confirmButtonText: 'Choose',
              initialDirectory: defaultPath,
              selectionOptions: selectionOptions,
              suggestedFileName: fileName));
    });
  });
}

void mockGetCount(MockShellItemAPI mockShellItemAPI, int numberOfElements) {
  when(mockShellItemAPI.getCount(any, any))
      .thenAnswer((Invocation realInvocation) {
    final Pointer<Uint32> pointer =
        realInvocation.positionalArguments.first as Pointer<Uint32>;
    pointer.value = numberOfElements;
  });
}

void setDefaultMocks(
    MockFileOpenDialogAPI mockFileOpenDialogAPI,
    MockShellItemAPI mockShellItemAPI,
    int successReturnValue,
    int defaultReturnValue,
    String defaultPath) {
  when(mockFileOpenDialogAPI.setOptions(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.getOptions(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.setOkButtonLabel(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.setFileTypes(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.show(any, any)).thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.getResult(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.getResults(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.release(any)).thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.setFolder(any, any))
      .thenReturn(successReturnValue);
  when(mockFileOpenDialogAPI.setFileName(any, any))
      .thenReturn(defaultReturnValue);
  when(mockFileOpenDialogAPI.createItemFromParsingName(any, any, any))
      .thenReturn(defaultReturnValue);
  final Pointer<Pointer<COMObject>> ppsi = calloc<Pointer<COMObject>>();
  when(mockShellItemAPI.createShellItem(any))
      .thenReturn(IShellItem(ppsi.cast()));
  when(mockShellItemAPI.createShellItemArray(any))
      .thenReturn(IShellItemArray(ppsi.cast()));
  free(ppsi);
  when(mockShellItemAPI.getDisplayName(any, any))
      .thenReturn(defaultReturnValue);
  when(mockShellItemAPI.getUserSelectedPath(any)).thenReturn(defaultPath);
  when(mockShellItemAPI.releaseItem(any)).thenReturn(defaultReturnValue);
  when(mockShellItemAPI.getItemAt(any, any, any))
      .thenReturn(defaultReturnValue);
}
