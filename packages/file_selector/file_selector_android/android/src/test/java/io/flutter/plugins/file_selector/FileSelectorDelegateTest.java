// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_GET_DIRECTORY_PATH;
import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_GET_SAVE_PATH;
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
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;

public class FileSelectorDelegateTest {
  @Mock Activity mockActivity;
  @Mock MethodChannel.Result mockResult;
  @Mock Intent mockIntent;

  @Mock Uri mockUri;

  @Mock PathUtils mockPathUtils;
  @Spy FileSelectorDelegate spyFileSelectorDelegate;

  @Before
  public void setUp() {
    MockitoAnnotations.openMocks(this);

    //    spyFileSelectorDelegate.cacheFolder = fakeFolder;

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

  public void getSavePath_WhenItIsCalled_launchGetDirectoryPath_NullArguments() {
    MethodCall call = buildMethodCall(METHOD_GET_SAVE_PATH, null, null, null);
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
    MethodCall call = buildMethodCall(METHOD_GET_SAVE_PATH, "testDir", null, "testName");
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
    MethodCall call = buildMethodCall(METHOD_GET_SAVE_PATH, null, null, null);
    FileSelectorDelegate delegate = createDelegateWithPendingResultAndMethodCall(call);

    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      delegate.handleGetSavePathResult(Activity.RESULT_OK, mockIntent);

      mockedPathUtils.verify(() -> PathUtils.getSavePathUri(mockUri, mockActivity), times(1));
    }
  }

  private FileSelectorDelegate createDelegateWithPendingResultAndMethodCall(MethodCall call) {
    return new FileSelectorDelegate(mockActivity, mockResult, call);
  }

  private void verifyFinishedWithAlreadyActiveError() {
    verify(mockResult).error("already_active", "File selector is already active", null);
  }
}
