// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_GET_DIRECTORY_PATH;
import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_OPEN_FILE;
import static io.flutter.plugins.file_selector.TestHelpers.buildMethodCall;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.Arrays;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;

public class FileSelectorDelegateTest {
  final ArrayList<String> mimeTypes = new ArrayList<String>(Arrays.asList("text"));
  String fakeFolder = "fakeFolder";
  String fakePath = "fakePath";

  @Mock Activity mockActivity;
  @Mock MethodChannel.Result mockResult;
  @Mock Intent mockIntent;
  @Mock Uri mockUri;
  @Mock PathUtils mockPathUtils;
  @Spy FileSelectorDelegate spyFileSelectorDelegate;

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
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, false, mimeTypes);
    spyFileSelectorDelegate = spy(new FileSelectorDelegate(mockActivity));

    doAnswer(
            (invocation) -> {
              return null;
            })
        .when(spyFileSelectorDelegate)
        .launchOpenFile(false, mimeTypes);

    spyFileSelectorDelegate.openFile(call, mockResult);

    verify(spyFileSelectorDelegate).launchOpenFile(false, mimeTypes);
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
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, false, mimeTypes);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);
    delegate.cacheFolder = fakeFolder;

    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      delegate.handleOpenFileResult(Activity.RESULT_OK, mockIntent);

      mockedPathUtils.verify(
          () -> PathUtils.copyFileToInternalStorage(mockUri, mockActivity, fakeFolder), times(1));
    }
  }

  @Test
  public void
      handleOpenFileResult_WhenResultCodeIsNotOk_NotInvokesCopyFileToInternalStorageFromPathUtils() {
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, false, mimeTypes);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);
    delegate.cacheFolder = fakeFolder;

    delegate.handleOpenFileResult(Activity.RESULT_CANCELED, mockIntent);

    verifyNoMoreInteractions(mockPathUtils);
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
}
