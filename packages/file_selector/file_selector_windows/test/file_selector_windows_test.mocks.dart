// Mocks generated by Mockito 5.3.0 from annotations
// in file_selector_windows/example/windows/flutter/ephemeral/.plugin_symlinks/file_selector_windows/test/file_selector_windows_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:ffi' as _i5;

import 'package:file_selector_windows/src/dart_file_selector_api.dart' as _i4;
import 'package:file_selector_windows/src/messages.g.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;
import 'package:win32/win32.dart' as _i6;

import 'test_api.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [TestFileSelectorApi].
///
/// See the documentation for Mockito's code generation for more information.
class MockTestFileSelectorApi extends _i1.Mock
    implements _i2.TestFileSelectorApi {
  MockTestFileSelectorApi() {
    _i1.throwOnMissingStub(this);
  }

  @override
  List<String?> showOpenDialog(_i3.SelectionOptions? options,
          String? initialDirectory, String? confirmButtonText) =>
      (super.noSuchMethod(
          Invocation.method(
              #showOpenDialog, [options, initialDirectory, confirmButtonText]),
          returnValue: <String?>[]) as List<String?>);
  @override
  List<String?> showSaveDialog(
          _i3.SelectionOptions? options,
          String? initialDirectory,
          String? suggestedName,
          String? confirmButtonText) =>
      (super.noSuchMethod(
          Invocation.method(#showSaveDialog,
              [options, initialDirectory, suggestedName, confirmButtonText]),
          returnValue: <String?>[]) as List<String?>);
}

/// A class which mocks [DartFileSelectorAPI].
///
/// See the documentation for Mockito's code generation for more information.
class MockDartFileSelectorAPI extends _i1.Mock
    implements _i4.DartFileSelectorAPI {
  MockDartFileSelectorAPI() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get title =>
      (super.noSuchMethod(Invocation.getter(#title), returnValue: '')
          as String);
  @override
  set title(String? _title) =>
      super.noSuchMethod(Invocation.setter(#title, _title),
          returnValueForMissingStub: null);
  @override
  String get fileNameLabel =>
      (super.noSuchMethod(Invocation.getter(#fileNameLabel), returnValue: '')
          as String);
  @override
  set fileNameLabel(String? _fileNameLabel) =>
      super.noSuchMethod(Invocation.setter(#fileNameLabel, _fileNameLabel),
          returnValueForMissingStub: null);
  @override
  String get fileName =>
      (super.noSuchMethod(Invocation.getter(#fileName), returnValue: '')
          as String);
  @override
  set fileName(String? _fileName) =>
      super.noSuchMethod(Invocation.setter(#fileName, _fileName),
          returnValueForMissingStub: null);
  @override
  set defaultExtension(String? _defaultExtension) => super.noSuchMethod(
      Invocation.setter(#defaultExtension, _defaultExtension),
      returnValueForMissingStub: null);
  @override
  Map<String, String> get filterSpecification =>
      (super.noSuchMethod(Invocation.getter(#filterSpecification),
          returnValue: <String, String>{}) as Map<String, String>);
  @override
  set filterSpecification(Map<String, String>? _filterSpecification) =>
      super.noSuchMethod(
          Invocation.setter(#filterSpecification, _filterSpecification),
          returnValueForMissingStub: null);
  @override
  set defaultFilterIndex(int? _defaultFilterIndex) => super.noSuchMethod(
      Invocation.setter(#defaultFilterIndex, _defaultFilterIndex),
      returnValueForMissingStub: null);
  @override
  bool get hidePinnedPlaces =>
      (super.noSuchMethod(Invocation.getter(#hidePinnedPlaces),
          returnValue: false) as bool);
  @override
  set hidePinnedPlaces(bool? _hidePinnedPlaces) => super.noSuchMethod(
      Invocation.setter(#hidePinnedPlaces, _hidePinnedPlaces),
      returnValueForMissingStub: null);
  @override
  bool get forceFileSystemItems =>
      (super.noSuchMethod(Invocation.getter(#forceFileSystemItems),
          returnValue: false) as bool);
  @override
  set forceFileSystemItems(bool? _forceFileSystemItems) => super.noSuchMethod(
      Invocation.setter(#forceFileSystemItems, _forceFileSystemItems),
      returnValueForMissingStub: null);
  @override
  bool get fileMustExist =>
      (super.noSuchMethod(Invocation.getter(#fileMustExist), returnValue: false)
          as bool);
  @override
  set fileMustExist(bool? _fileMustExist) =>
      super.noSuchMethod(Invocation.setter(#fileMustExist, _fileMustExist),
          returnValueForMissingStub: null);
  @override
  bool get isDirectoryFixed =>
      (super.noSuchMethod(Invocation.getter(#isDirectoryFixed),
          returnValue: false) as bool);
  @override
  set isDirectoryFixed(bool? _isDirectoryFixed) => super.noSuchMethod(
      Invocation.setter(#isDirectoryFixed, _isDirectoryFixed),
      returnValueForMissingStub: null);
  @override
  int get hWndOwner =>
      (super.noSuchMethod(Invocation.getter(#hWndOwner), returnValue: 0)
          as int);
  @override
  set hWndOwner(int? _hWndOwner) =>
      super.noSuchMethod(Invocation.setter(#hWndOwner, _hWndOwner),
          returnValueForMissingStub: null);
  @override
  List<String> getFile(_i3.SelectionOptions? selectionOptions,
          String? initialDirectory, String? confirmButtonText) =>
      (super.noSuchMethod(
          Invocation.method(#getFile,
              [selectionOptions, initialDirectory, confirmButtonText]),
          returnValue: <String>[]) as List<String>);
  @override
  int getOptions(_i5.Pointer<_i5.Uint32>? pfos, int? hResult,
          _i6.IFileOpenDialog? dialog) =>
      (super.noSuchMethod(
          Invocation.method(#getOptions, [pfos, hResult, dialog]),
          returnValue: 0) as int);
  @override
  int setDialogOptions(
          _i5.Pointer<_i5.Uint32>? pfos,
          int? hResult,
          _i3.SelectionOptions? selectionOptions,
          _i6.IFileOpenDialog? dialog) =>
      (super.noSuchMethod(
          Invocation.method(
              #setDialogOptions, [pfos, hResult, selectionOptions, dialog]),
          returnValue: 0) as int);
  @override
  int initializeComLibrary() =>
      (super.noSuchMethod(Invocation.method(#initializeComLibrary, []),
          returnValue: 0) as int);
  @override
  List<String> returnSelectedElement(int? hResult,
          _i3.SelectionOptions? selectionOptions, _i6.FileOpenDialog? dialog) =>
      (super.noSuchMethod(
          Invocation.method(
              #returnSelectedElement, [hResult, selectionOptions, dialog]),
          returnValue: <String>[]) as List<String>);
  @override
  int addConfirmButtonLabel(
          _i6.FileOpenDialog? dialog, String? confirmButtonText) =>
      (super.noSuchMethod(
          Invocation.method(
              #addConfirmButtonLabel, [dialog, confirmButtonText]),
          returnValue: 0) as int);
  @override
  int addFileFilters(int? hResult, _i6.FileOpenDialog? fileDialog,
          _i3.SelectionOptions? selectionOptions) =>
      (super.noSuchMethod(
          Invocation.method(
              #addFileFilters, [hResult, fileDialog, selectionOptions]),
          returnValue: 0) as int);
  @override
  void clearFilterSpecification() =>
      super.noSuchMethod(Invocation.method(#clearFilterSpecification, []),
          returnValueForMissingStub: null);
}
