// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

import 'src/messages.g.dart';

/// An implementation of [FileSelectorPlatform] for Android.
class FileSelectorAndroid extends FileSelectorPlatform {
  /// Constructor for FileSelector.
  FileSelectorAndroid([this._hostApi]) {
    _hostApi = _hostApi ?? FileSelectorApi();

    _internalHostApi = _hostApi!;
  }

  late FileSelectorApi _internalHostApi;

  late FileSelectorApi? _hostApi;

  /// Registers the Android implementation.
  static void registerWith([FileSelectorApi? hostApi]) {
    FileSelectorPlatform.instance = FileSelectorAndroid(hostApi);
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String?> paths = await _internalHostApi.startFileExplorer(
        FileSelectorMethod.OPEN_FILE,
        SelectionOptions(
          allowMultiple: false,
          selectFolders: false,
          allowedTypes: _typeGroupsFromXTypeGroups(acceptedTypeGroups),
        ),
        initialDirectory,
        confirmButtonText);

    if (paths == null) {
      return null;
    }

    return paths.isEmpty ? null : XFile(paths.first!);
  }

  @override
  Future<String?> getDirectoryPath({
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String?> paths = await _internalHostApi.startFileExplorer(
        FileSelectorMethod.GET_DIRECTORY_PATH,
        SelectionOptions(
          allowMultiple: false,
          selectFolders: true,
          allowedTypes: <TypeGroup>[],
        ),
        initialDirectory,
        confirmButtonText);

    if (paths == null) {
      return null;
    }

    return paths.isEmpty ? null : paths.first!;
  }

  @override
  Future<List<XFile>> openFiles({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String?> paths = await _internalHostApi.startFileExplorer(
        FileSelectorMethod.OPEN_MULTIPLE_FILES,
        SelectionOptions(
          allowMultiple: true,
          selectFolders: false,
          allowedTypes: _typeGroupsFromXTypeGroups(acceptedTypeGroups),
        ),
        initialDirectory,
        confirmButtonText);

    if (paths == null) {
      return <XFile>[];
    }

    return paths.map((String? path) => XFile(path!)).toList();
  }

  @override
  Future<String?> getSavePath({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? suggestedName,
    String? confirmButtonText,
  }) async {
    return await _internalHostApi.openSaveDialog(
        SelectionOptions(
          allowMultiple: false,
          selectFolders: false,
          allowedTypes: _typeGroupsFromXTypeGroups(acceptedTypeGroups),
        ),
        initialDirectory,
        suggestedName,
        confirmButtonText);
  }
}

List<TypeGroup> _typeGroupsFromXTypeGroups(List<XTypeGroup>? xtypes) {
  return (xtypes ?? <XTypeGroup>[]).map((XTypeGroup xtype) {
    if (!xtype.allowsAny && (xtype.extensions?.isEmpty ?? true)) {
      throw ArgumentError('Provided type group $xtype does not allow '
          'all files, but does not set any of the Android-supported filter '
          'categories. "extensions" must be non-empty for Windows if '
          'anything is non-empty.');
    }
    return TypeGroup(
        label: xtype.label ?? '', extensions: xtype.extensions ?? <String>[]);
  }).toList();
}
