// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_GET_DIRECTORY_PATH;
import static io.flutter.plugins.file_selector.FileSelectorPlugin.METHOD_OPEN_FILE;
import static io.flutter.plugins.file_selector.TestHelpers.buildMethodCall;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashMap;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

public class FileSelectorPluginTest {
  final HashMap<String, ArrayList<String>> xTypeGroups = new HashMap<>();
  final ArrayList<String> mimeTypes = new ArrayList<String>();
  final HashMap<String, Boolean> multiple = new HashMap<>();

  @Mock io.flutter.plugin.common.PluginRegistry.Registrar mockRegistrar;
  @Mock ActivityPluginBinding mockActivityBinding;
  @Mock FlutterPluginBinding mockPluginBinding;
  @Mock Activity mockActivity;
  @Mock Application mockApplication;
  @Mock FileSelectorDelegate mockFileSelectorDelegate;
  @Mock MethodChannel.Result mockResult;
  @Mock PathUtils mockPathUtils;
  @Mock ActivityStateHelper mockActivityStateHelper;
  FileSelectorPlugin plugin;

  @Before
  public void setUp() {
    MockitoAnnotations.openMocks(this);

    doNothing().when(mockFileSelectorDelegate).clearCache();
    when(mockRegistrar.context()).thenReturn(mockApplication);
    when(mockActivityBinding.getActivity()).thenReturn(mockActivity);
    when(mockPluginBinding.getApplicationContext()).thenReturn(mockApplication);

    plugin = new FileSelectorPlugin(mockFileSelectorDelegate, mockActivity);
  }

  @After
  public void tearDown() {
    reset(mockRegistrar);
    reset(mockActivity);
    reset(mockPluginBinding);
    reset(mockPathUtils);
    reset(mockResult);
    reset(mockActivityBinding);
    reset(mockFileSelectorDelegate);
    reset(mockApplication);
  }

  @Test
  public void onMethodCall_WhenActivityIsNull_FinishesWithForegroundActivityRequiredError() {
    MethodCall call = buildMethodCall(METHOD_GET_DIRECTORY_PATH);
    FileSelectorPlugin fileSelectorPluginWithNullActivity =
        new FileSelectorPlugin(mockFileSelectorDelegate, null);
    fileSelectorPluginWithNullActivity.onMethodCall(call, mockResult);
    verify(mockResult)
        .error("no_activity", "file_selector plugin requires a foreground activity.", null);
    verifyNoInteractions(mockFileSelectorDelegate);
  }

  @Test
  public void onMethodCall_WhenCalledWithUnknownMethod_ThrowsException() {
    String method = "unknown_test_method";

    IllegalArgumentException exception =
        assertThrows(
            IllegalArgumentException.class,
            () -> plugin.onMethodCall(new MethodCall(method, null), mockResult));
    assertEquals("Unknown method " + method, exception.getMessage());
    verifyNoInteractions(mockResult);
  }

  @Test
  public void
      onMethodCall_GetDirectoryPath_WhenCalledWithoutInitialDirectory_InvokesRootSourceFolder() {
    MethodCall call = buildMethodCall(METHOD_GET_DIRECTORY_PATH, null, null, false, null);
    plugin.onMethodCall(call, mockResult);

    verifyNoInteractions(mockResult);
  }

  @Test
  public void onMethodCall_GetDirectoryPath_WhenCalledWithInitialDirectory_InvokesSourceFolder() {
    MethodCall call = buildMethodCall(METHOD_GET_DIRECTORY_PATH, "Documents", null, false, null);
    plugin.onMethodCall(call, mockResult);

    verify(mockFileSelectorDelegate).getDirectoryPath(eq(call), any());
    verifyNoInteractions(mockResult);
  }

  @Test
  public void onDetachedFromActivity_ShouldReleaseActivityState() {
    plugin.delegate = mockFileSelectorDelegate;

    final BinaryMessenger mockBinaryMessenger = mock(BinaryMessenger.class);
    when(mockPluginBinding.getBinaryMessenger()).thenReturn(mockBinaryMessenger);

    final HiddenLifecycleReference mockLifecycleReference = mock(HiddenLifecycleReference.class);
    when(mockActivityBinding.getLifecycle()).thenReturn(mockLifecycleReference);

    final Lifecycle mockLifecycle = mock(Lifecycle.class);
    when(mockLifecycleReference.getLifecycle()).thenReturn(mockLifecycle);

    plugin.onAttachedToEngine(mockPluginBinding);
    plugin.onAttachedToActivity(mockActivityBinding);
    assertNotNull(plugin.getActivityState());

    plugin.onDetachedFromActivity();
    assertNull(plugin.getActivityState());
  }

  @Test
  public void onMethodCall_OpenFile_ShouldBeCalledWithCorrespondingArguments() {
    final ArrayList<HashMap> arguments = prepareArguments();
    MethodCall call = buildMethodCall(METHOD_OPEN_FILE, null, null, false, arguments);
    plugin.onMethodCall(call, mockResult);

    verify(mockFileSelectorDelegate).openFile(eq(call), any());
    verifyNoInteractions(mockResult);
  }

  @Test
  public void tearDown_ShouldClearState() {
    plugin.activityState = mockActivityStateHelper;
    plugin.delegate = mockFileSelectorDelegate;
    doNothing().when(mockFileSelectorDelegate).clearCache();
    doNothing().when(mockActivityStateHelper).release();
    plugin.tearDown();

    verify(mockActivityStateHelper, times(1)).release();
    verify(mockFileSelectorDelegate, times(1)).clearCache();
    Assert.assertNull(plugin.activityState);
  }

  @NonNull
  private ArrayList<HashMap> prepareArguments() {
    final ArrayList<HashMap> arguments = new ArrayList<HashMap>();
    mimeTypes.add("text");
    xTypeGroups.put("mimeTypes", mimeTypes);
    multiple.put("multiple", false);
    arguments.add(xTypeGroups);
    arguments.add(multiple);

    return arguments;
  }
}
