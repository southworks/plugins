// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'messages.g.dart';

/// The Android implementation of [FileSelectorPlatform].
class FileSelectorAndroid extends FileSelectorPlatform {
  final FileSelectorApi _api = FileSelectorApi();

  /// Registers this class as the default instance of [FileSelectorPlatform].
  static void registerWith() {
    FileSelectorPlatform.instance = FileSelectorAndroid();
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String?> path = await _api.openFiles(
        SelectionOptions(
          allowMultiple: false,
          allowedTypes: _typeGroupsFromXTypeGroups(acceptedTypeGroups),
        ),
        initialDirectory,
        confirmButtonText);

    return path.first == null ? null : XFile(path.first!);
  }

  @override
  Future<List<XFile>> openFiles({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String?> paths = await _api.openFiles(
        SelectionOptions(
          allowMultiple: true,
          allowedTypes: _typeGroupsFromXTypeGroups(acceptedTypeGroups),
        ),
        initialDirectory,
        confirmButtonText);

    return paths.map((String? path) => XFile(path!)).toList();
  }

  /// Android doesn't currently support to set the Confirm Button Text
  /// For references, please check the following link:
  /// https://developer.android.com/reference/android/content/Intent#ACTION_OPEN_DOCUMENT_TREE
  @override
  Future<String?> getDirectoryPath({
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    return _api.getDirectoryPath(initialDirectory);
  }
}

List<TypeGroup> _typeGroupsFromXTypeGroups(List<XTypeGroup>? xtypes) {
  return (xtypes ?? <XTypeGroup>[]).map((XTypeGroup xtype) {
    if (xtype.allowsAny) {
      return TypeGroup(
          label: xtype.label ?? '',
          extensions: <String>['*'],
          mimeTypes: <String>['*']);
    }

    if (!xtype.allowsAny &&
        (xtype.extensions?.isEmpty ?? true) &&
        (xtype.mimeTypes?.isEmpty ?? true)) {
      throw ArgumentError('Provided type group $xtype does not allow '
          'all files, but does not set any of the Android-supported filter '
          'categories. "extensions" or "mimeTypes" must be non-empty for Android if '
          'anything is non-empty.');
    }

    return TypeGroup(
        label: xtype.label ?? '',
        extensions: xtype.extensions ?? <String>[],
        mimeTypes: xtype.mimeTypes ?? <String>[]);
  }).toList();
}
