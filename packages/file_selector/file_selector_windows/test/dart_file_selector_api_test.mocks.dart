// Mocks generated by Mockito 5.3.0 from annotations
// in file_selector_windows/test/dart_file_selector_api_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:ffi' as _i4;

import 'package:file_selector_windows/src/dart_file_open_dialog_api.dart'
    as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:win32/win32.dart' as _i3;

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

/// A class which mocks [FileOpenDialogAPI].
///
/// See the documentation for Mockito's code generation for more information.
class MockFileOpenDialogAPI extends _i1.Mock implements _i2.FileOpenDialogAPI {
  MockFileOpenDialogAPI() {
    _i1.throwOnMissingStub(this);
  }

  @override
  int setOptions(int? fos, _i3.IFileOpenDialog? dialog) =>
      (super.noSuchMethod(Invocation.method(#setOptions, [fos, dialog]),
          returnValue: 0) as int);
  @override
  int getOptions(_i4.Pointer<_i4.Uint32>? fos, _i3.IFileOpenDialog? dialog) =>
      (super.noSuchMethod(Invocation.method(#getOptions, [fos, dialog]),
          returnValue: 0) as int);
  @override
  int setOkButtonLabel(String? confirmationText, _i3.IFileOpenDialog? dialog) =>
      (super.noSuchMethod(
          Invocation.method(#setOkButtonLabel, [confirmationText, dialog]),
          returnValue: 0) as int);
  @override
  int setFileTypes(Map<String, String>? filterSpecification, int? hResult,
          _i3.IFileOpenDialog? dialog) =>
      (super.noSuchMethod(
          Invocation.method(
              #setFileTypes, [filterSpecification, hResult, dialog]),
          returnValue: 0) as int);
}
