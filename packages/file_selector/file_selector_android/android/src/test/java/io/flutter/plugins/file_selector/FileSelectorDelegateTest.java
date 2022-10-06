// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import static io.flutter.plugins.file_selector.FileSelectorDelegate.REQUEST_CODE_OPEN_FILE;
import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_GET_DIRECTORY_PATH;
import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_GET_SAVE_PATH;
import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_OPEN_FILE;
import static io.flutter.plugins.file_selector.TestHelpers.buildMethodCall;
import static io.flutter.plugins.file_selector.TestHelpers.setMockUris;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.net.Uri;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;

public class FileSelectorDelegateTest {
  final ArrayList<String> textMimeType = new ArrayList<String>(Collections.singletonList("text"));
  final ArrayList<String> pngMimeType = new ArrayList<String>(Collections.singletonList("png"));
  String fakeFolder = "fakeFolder";
  int numberOfPickedFiles = 2;

  @Mock Activity mockActivity;
  @Mock MethodChannel.Result mockResult;
  @Mock Intent mockIntent;
  @Mock Uri mockUri;
  @Mock PathUtils mockPathUtils;
  @Spy FileSelectorDelegate spyFileSelectorDelegate;
  @Mock ClipData mockClipData;
  @Mock ClipData.Item mockItem;

  @Before
  public void setUp() {
    MockitoAnnotations.openMocks(this);
    spyFileSelectorDelegate.cacheFolder = fakeFolder;

    spyFileSelectorDelegate = spy(new FileSelectorDelegate(mockActivity));

    when(mockIntent.getData()).thenReturn(mockUri);
  }

  @After
  public void tearDown() {
    reset(mockUri);
    reset(mockActivity);
    reset(mockIntent);
    reset(mockPathUtils);
    reset(mockResult);
    reset(spyFileSelectorDelegate);
    reset(mockClipData);
    reset(mockItem);
  }

  @Test
  public void getDirectoryPath_WhenPendingResultExists_FinishesWithAlreadyActiveError() {
    MethodCall call = buildMethodCall(METHOD_GET_DIRECTORY_PATH);
    FileSelectorDelegate delegate = new FileSelectorDelegate(mockActivity, mockResult, call);

    delegate.getDirectoryPath(call, mockResult);

    verifyFinishedWithAlreadyActiveError();
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void getSavePath_WhenPendingResultExists_FinishesWithAlreadyActiveError() {
    MethodCall call = buildMethodCall(METHOD_GET_SAVE_PATH);
    FileSelectorDelegate delegate = new FileSelectorDelegate(mockActivity, mockResult, call);

    delegate.getSavePath(call, mockResult);

    verifyFinishedWithAlreadyActiveError();
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void onActivityResult_WhenGetDirectoryPathCanceled_FinishesWithNull() {
    MethodCall call = buildMethodCall(METHOD_GET_DIRECTORY_PATH);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    delegate.onActivityResult(
        FileSelectorDelegate.REQUEST_CODE_GET_DIRECTORY_PATH, Activity.RESULT_CANCELED, null);

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void onActivityResult_GetDirectoryPathReturnsSuccessfully() {
    MethodCall call = buildMethodCall(METHOD_GET_DIRECTORY_PATH);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);
    delegate.onActivityResult(
        FileSelectorDelegate.REQUEST_CODE_GET_DIRECTORY_PATH, Activity.RESULT_OK, mockIntent);

    verify(mockResult).success(mockUri.toString());
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void getSavePath_WhenItIsCalled_launchGetDirectoryPath_NullArguments() {
    MethodCall call = buildMethodCall(METHOD_GET_SAVE_PATH, null, null, null, null, null);
    spyFileSelectorDelegate = spy(new FileSelectorDelegate(mockActivity));

    doAnswer(
            (invocation) -> {
              return null;
            })
        .when(spyFileSelectorDelegate)
        .launchGetSavePath(null, null);

    spyFileSelectorDelegate.getSavePath(call, mockResult);

    verify(spyFileSelectorDelegate).launchGetSavePath(null, null);
  }

  @Test
  public void getSavePath_WhenItIsCalled_launchGetDirectoryPath_WithInitialDirAndSuggestedName() {
    MethodCall call =
        buildMethodCall(METHOD_GET_SAVE_PATH, "testDir", null, "testName", null, null);
    spyFileSelectorDelegate = spy(new FileSelectorDelegate(mockActivity));

    doAnswer(
            (invocation) -> {
              return null;
            })
        .when(spyFileSelectorDelegate)
        .launchGetSavePath("testDir", "testName");

    spyFileSelectorDelegate.getSavePath(call, mockResult);

    verify(spyFileSelectorDelegate).launchGetSavePath("testDir", "testName");
  }

  @Test
  public void onActivityResult_WhenGetSavePath_InvokesHandleGetSavePathResult() {
    doAnswer(
            (invocation) -> {
              return null;
            })
        .when(spyFileSelectorDelegate)
        .handleGetSavePathResult(Activity.RESULT_OK, mockIntent);

    spyFileSelectorDelegate.onActivityResult(
        FileSelectorDelegate.REQUEST_CODE_GET_SAVE_PATH, Activity.RESULT_OK, mockIntent);

    verify(spyFileSelectorDelegate).handleGetSavePathResult(Activity.RESULT_OK, mockIntent);
  }

  @Test
  public void handleGetSavePathResult_WhenItIsCalled_InvokesGetSavePathUriFromPathUtils() {
    MethodCall call = buildMethodCall(METHOD_GET_SAVE_PATH, null, null, null, null, null);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      delegate.handleGetSavePathResult(Activity.RESULT_OK, mockIntent);

      mockedPathUtils.verify(() -> PathUtils.getSavePathUri(mockUri, mockActivity), times(1));
    }
  }

  @Test
  public void openFile_WhenPendingResultExists_FinishesWithAlreadyActiveError() {
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE);
    FileSelectorDelegate delegate = new FileSelectorDelegate(mockActivity, mockResult, call);

    delegate.openFile(call, mockResult);

    verifyFinishedWithAlreadyActiveError();
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void onActivityResult_WhenOpenFileCanceled_FinishesWithNull() {
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);
    delegate.onActivityResult(
        FileSelectorDelegate.REQUEST_CODE_OPEN_FILE, Activity.RESULT_CANCELED, null);

    verify(mockResult).success(null);
    verifyNoMoreInteractions(mockResult);
  }

  @Test
  public void openFile_WhenItIsCalled_InvokesLaunchOpenFile() {
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    spyFileSelectorDelegate = spy(new FileSelectorDelegate(mockActivity));

    doAnswer(
            (invocation) -> {
              return null;
            })
        .when(spyFileSelectorDelegate)
        .launchOpenFile(false, textMimeType);

    spyFileSelectorDelegate.openFile(call, mockResult);

    verify(spyFileSelectorDelegate).launchOpenFile(false, textMimeType);
  }

  @Test
  public void clearCache_WhenItIsCalled_InvokesClearCacheFromPathUtils() {
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);
    delegate.cacheFolder = fakeFolder;

    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      delegate.clearCache();

      mockedPathUtils.verify(() -> PathUtils.clearCache(mockActivity, fakeFolder), times(1));
    }
  }

  @Test
  public void onActivityResult_WhenOpenFile_InvokesHandleOpenFileResult() {
    doAnswer(
            (invocation) -> {
              return null;
            })
        .when(spyFileSelectorDelegate)
        .handleOpenFileResult(Activity.RESULT_OK, mockIntent);

    spyFileSelectorDelegate.onActivityResult(
        FileSelectorDelegate.REQUEST_CODE_OPEN_FILE, Activity.RESULT_OK, mockIntent);

    verify(spyFileSelectorDelegate).handleOpenFileResult(Activity.RESULT_OK, mockIntent);
  }

  @Test
  public void handleOpenFileResult_WhenItIsCalled_InvokesCopyFileToInternalStorageFromPathUtils() {
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);
    delegate.cacheFolder = fakeFolder;
    ArrayList<Uri> uris = setMockUris(1, mockUri);

    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      when(mockIntent.getData()).thenReturn(mockUri);
      when(spyFileSelectorDelegate.uriHandler(mockIntent)).thenReturn(uris);

      spyFileSelectorDelegate.handleOpenFileResult(Activity.RESULT_OK, mockIntent);

      mockedPathUtils.verify(
          () -> PathUtils.copyFilesToInternalStorage(uris, mockActivity, fakeFolder), times(1));
    }
  }

  @Test
  public void
      handleOpenFileResult_WhenItIsCalledWithMultipleFiles_InvokesCopyFileToInternalStorageFromPathUtilsWithCorrespondingUrisArray() {
    ArrayList<Uri> uris = setMockUris(numberOfPickedFiles, mockUri);

    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      when(spyFileSelectorDelegate.uriHandler(mockIntent)).thenReturn(uris);

      spyFileSelectorDelegate.handleOpenFileResult(Activity.RESULT_OK, mockIntent);

      mockedPathUtils.verify(
          () -> PathUtils.copyFilesToInternalStorage(uris, mockActivity, fakeFolder), times(1));
    }
  }

  @Test
  public void
      handleOpenFileResult_WhenResultCodeIsNotOk_NotInvokesCopyFileToInternalStorageFromPathUtils() {
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);
    delegate.cacheFolder = fakeFolder;

    delegate.handleOpenFileResult(Activity.RESULT_CANCELED, mockIntent);

    verifyNoMoreInteractions(mockPathUtils);
  }

  @Test
  public void handleOpenFileResult_WhenItIsCalled_ShouldInvokeHandleOpenFileActionResults() {
    ArrayList<Uri> uris = setMockUris(1, mockUri);
    ArrayList<String> paths = new ArrayList<>();

    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      when(mockIntent.getData()).thenReturn(mockUri);
      when(spyFileSelectorDelegate.uriHandler(mockIntent)).thenReturn(uris);

      spyFileSelectorDelegate.handleOpenFileResult(Activity.RESULT_OK, mockIntent);

      mockedPathUtils
          .when(() -> PathUtils.copyFilesToInternalStorage(uris, mockActivity, fakeFolder))
          .thenReturn(paths);

      verify(spyFileSelectorDelegate).handleOpenFileActionResults(paths);
    }
  }

  @Test
  public void
      handleOpenFileActionResults_WhenItIsCalled_ShouldInvokeSuccessAndFinishWithListSuccessMethods() {
    ArrayList<String> paths = new ArrayList<>();
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    spyFileSelectorDelegate = spy(new FileSelectorDelegate(mockActivity, mockResult, call));

    spyFileSelectorDelegate.handleOpenFileActionResults(paths);

    verify(mockResult).success(paths);
    verify(spyFileSelectorDelegate).finishWithListSuccess(paths);
  }

  @Test
  public void uriHandler_WhenASingleFileIsPicked_ShouldInvokeGetDataMethod() {
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    delegate.uriHandler(mockIntent);

    verify(mockIntent).getData();
  }

  @Test
  public void uriHandler_WhenASingleFileIsPicked_ShouldReturnAUri() {
    ArrayList<Uri> expectedResult = new ArrayList<>();
    expectedResult.add(mockUri);

    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    ArrayList<Uri> actualResult = delegate.uriHandler(mockIntent);

    Assert.assertEquals(expectedResult, actualResult);
  }

  @Test
  public void uriHandler_WhenMultipleFilesArePicked_ShouldReturnSameNumberOfUris() {
    ArrayList<Uri> uris = setMockUris(numberOfPickedFiles, mockUri);
    mockClipData(numberOfPickedFiles);

    ArrayList<Uri> expectedResult = new ArrayList<>();
    expectedResult.addAll(uris);

    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    ArrayList<Uri> actualResult = delegate.uriHandler(mockIntent);

    Assert.assertEquals(expectedResult, actualResult);
    Assert.assertEquals(numberOfPickedFiles, actualResult.stream().count());
  }

  @Test
  public void uriHandler_WhenMultipleFilesArePicked_ShouldInvokeSeveralMethodsOfClipData() {
    mockClipData(numberOfPickedFiles);

    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    delegate.uriHandler(mockIntent);

    verify(mockClipData).getItemCount();
    verify(mockClipData, times(numberOfPickedFiles)).getItemAt(anyInt());
  }

  @Test
  public void getMimeTypes_WhenMultipleMimeTypesAreReceived_ShouldReturnThemAsArray() {
    mockClipData(numberOfPickedFiles);
    ArrayList<Object> fakeAcceptedTypes = prepareMimeTypes(true);
    String[] expectedResult = new String[] {textMimeType.get(0), pngMimeType.get(0)};

    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    String[] actualResult = delegate.getMimeTypes(fakeAcceptedTypes);

    Assert.assertArrayEquals(expectedResult, actualResult);
  }

  @Test
  public void getMimeTypes_WhenNoMimeTypesAreReceived_ShouldReturnAnEmptyArray() {
    mockClipData(numberOfPickedFiles);

    ArrayList<Object> fakeAcceptedTypes = prepareMimeTypes(false);

    String[] expectedResult = new String[] {};

    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, null, false, textMimeType);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    String[] actualResult = delegate.getMimeTypes(fakeAcceptedTypes);

    Assert.assertArrayEquals(expectedResult, actualResult);
  }

  @Test
  public void launchOpenFile_WhenItIsSuccessfully_ShouldInvokeStartWithSpecificArguments() {
    mockClipData(numberOfPickedFiles);
    ArrayList<Object> fakeAcceptedTypes = prepareMimeTypes(true);

    spyFileSelectorDelegate.openFileIntent = mockIntent;
    spyFileSelectorDelegate.launchOpenFile(false, fakeAcceptedTypes);

    verify(mockActivity, times(1)).startActivityForResult(mockIntent, REQUEST_CODE_OPEN_FILE);
  }

  @Test
  public void launchOpenFile_WhenAcceptedTypeGroupsIsNull_ShouldNotInvokeGetMimeTypesMethod() {
    spyFileSelectorDelegate.launchOpenFile(false, null);

    verify(spyFileSelectorDelegate, never()).getMimeTypes(any(ArrayList.class));
  }

  @Test
  public void launchOpenFile_WhenAcceptedTypeGroupsIsEmpty_ShouldNotInvokeGetMimeTypesMethod() {
    spyFileSelectorDelegate.launchOpenFile(false, new ArrayList());

    verify(spyFileSelectorDelegate, never()).getMimeTypes(any(ArrayList.class));
  }

  @Test
  public void
      launchOpenFile_WhenAllArgumentsAreNotEmpty_ShouldSetSeveralPropertiesOfIntentWithSpecificValues() {
    ArrayList<Object> fakeAcceptedTypes = prepareMimeTypes(true);

    spyFileSelectorDelegate.openFileIntent = mockIntent;
    spyFileSelectorDelegate.launchOpenFile(false, fakeAcceptedTypes);
    String[] mimeTypes = new String[] {textMimeType.get(0), pngMimeType.get(0)};

    verify(mockIntent, times(1)).setAction(Intent.ACTION_GET_CONTENT);
    verify(mockIntent, times(1)).addCategory(Intent.CATEGORY_OPENABLE);
    verify(mockIntent, times(1)).putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false);
    verify(mockIntent, times(1)).setType("*/*");
    verify(spyFileSelectorDelegate, times(1)).getMimeTypes(fakeAcceptedTypes);
    verify(mockIntent, times(1)).putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes);
  }

  @Test
  public void launchOpenFile_WhenMimeTypesAreEmpty_ShouldNotInvokePutExtraForExtraMimeTypes() {
    spyFileSelectorDelegate.openFileIntent = mockIntent;
    mockClipData(numberOfPickedFiles);
    ArrayList<Object> fakeAcceptedTypes = prepareMimeTypes(false);
    String[] mimeTypes = new String[] {textMimeType.get(0), pngMimeType.get(0)};

    spyFileSelectorDelegate.launchOpenFile(false, fakeAcceptedTypes);

    verify(mockIntent, never()).putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes);
  }

  @Test
  public void launchOpenFile_WhenMimeTypesAreNotEmpty_ShouldInvokePutExtraForExtraMimeTypes() {
    spyFileSelectorDelegate.openFileIntent = mockIntent;
    mockClipData(numberOfPickedFiles);
    ArrayList<Object> fakeAcceptedTypes = prepareMimeTypes(true);
    String[] mimeTypes = new String[] {textMimeType.get(0), pngMimeType.get(0)};

    spyFileSelectorDelegate.launchOpenFile(false, fakeAcceptedTypes);

    verify(mockIntent, times(1)).putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes);
  }

  private FileSelectorDelegate createDelegate() {
    return new FileSelectorDelegate(mockActivity, null, null);
  }

  private FileSelectorDelegate createDelegateWithPendingResultAndMethodCall(MethodCall call) {
    return new FileSelectorDelegate(mockActivity, mockResult, call);
  }

  private void verifyFinishedWithAlreadyActiveError() {
    verify(mockResult).error("already_active", "File selector is already active", null);
  }

  private void mockClipData(int uriCount) {
    when(mockItem.getUri()).thenReturn(mockUri);
    when(mockClipData.getItemCount()).thenReturn(uriCount);
    for (int i = 0; i < uriCount; i++) {
      when(mockClipData.getItemAt(i)).thenReturn(mockItem);
    }
    when(mockIntent.getClipData()).thenReturn(mockClipData);
  }

  private ArrayList<Object> prepareMimeTypes(boolean areMimeTypesPresent) {
    ArrayList<Object> acceptedTypes = new ArrayList<>();
    HashMap<String, ArrayList<String>> xTypeGroupsFirst = new HashMap<String, ArrayList<String>>();
    HashMap<String, ArrayList<String>> xTypeGroupsSecond = new HashMap<>();

    if (areMimeTypesPresent) {
      xTypeGroupsFirst.put("mimeTypes", textMimeType);
      xTypeGroupsSecond.put("mimeTypes", pngMimeType);
    }

    acceptedTypes.add(xTypeGroupsFirst);
    acceptedTypes.add(xTypeGroupsSecond);
    return acceptedTypes;
  }
}
