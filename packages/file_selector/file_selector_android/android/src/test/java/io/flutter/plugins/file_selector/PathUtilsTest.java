// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import static io.flutter.plugins.file_selector.TestHelpers.setMockUris;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.ContentResolver;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import java.io.IOException;
import java.io.InputStream;
import java.nio.Buffer;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Objects;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.shadows.ShadowEnvironment;

@RunWith(RobolectricTestRunner.class)
public class PathUtilsTest {
  static TemporaryFolder folder;
  static final String fileName = "FileName";
  static final String externalDirectoryName = "ExternalDir";
  static final String folderName = "FolderName";
  int bufferSize = 1024;
  final byte[] fakeByte = new byte[bufferSize];

  PathUtils pathUtils;

  @Mock Activity mockActivity;
  @Mock Uri mockUri;
  @Mock Cursor mockCursor;
  @Mock ContentResolver mockContentResolver;
  @Mock InputStream mockInputStream;
  @Mock Buffer mockBuffer;
  @Spy PathUtils spyPathUtils;

  @Before
  public void setUp() throws IOException {
    MockitoAnnotations.openMocks(this);
    spyPathUtils = spy(new PathUtils());

    folder = new TemporaryFolder();
    folder.create();

    when(mockCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)).thenReturn(0);
    when(mockContentResolver.query(
            mockUri,
            new String[] {OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE},
            null,
            null,
            null))
        .thenReturn(mockCursor);
    when(mockActivity.getContentResolver()).thenReturn(mockContentResolver);
    when(mockInputStream.read(fakeByte)).thenReturn(-1);
    when(mockContentResolver.openInputStream(mockUri)).thenReturn(mockInputStream);
    when(mockCursor.moveToFirst()).thenReturn(true);
    when(mockCursor.getString(0)).thenReturn(fileName);
    ShadowEnvironment.setExternalStorageDirectory(Paths.get(externalDirectoryName));

    mockFiles();

    pathUtils = new PathUtils();
  }

  @After
  public void tearDown() {
    reset(mockUri);
    reset(mockActivity);
    reset(mockCursor);
    reset(mockContentResolver);
    reset(mockInputStream);
    reset(mockBuffer);
    reset(spyPathUtils);
    folder.delete();
  }

  @Test
  public void getFileName_shouldReturnTheFileName() {
    final String actualResult =
        PathUtils.getFileName(
            mockUri,
            mockActivity,
            new String[] {OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE});

    Assert.assertEquals(fileName, actualResult);
  }

  @Test
  public void
      copyFilesToInternalStorage_whenCacheFolderNameIsNotPassed_shouldInvokeCopyFileToInternalStorageWithEmptyString() {
    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      //new String[] {OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE}
      spyPathUtils.copyFilesToInternalStorage(setMockUris(1, mockUri), mockActivity);

      mockedPathUtils.verify(
          () -> PathUtils.copyFilesToInternalStorage(setMockUris(1, mockUri), mockActivity, ""),
          times(1));
    }
  }

  @Test
  public void
      copyFilesToInternalStorage_whenMoreThanOneUriIsReceived_shouldReturnSameNumberOfAbsolutePaths() {
    int numberOfPickedFiles = 3;

    ArrayList<Uri> fakeUris = setMockUris(numberOfPickedFiles, mockUri);
    ArrayList<String> expectedResult = new ArrayList<>();
    String absolutPath = folder.getRoot() + "/" + folderName + "/" + fileName;
    expectedResult.add(absolutPath);
    expectedResult.add(absolutPath);
    expectedResult.add(absolutPath);

    ArrayList<String> actualResult =
        PathUtils.copyFilesToInternalStorage(fakeUris, mockActivity, folderName);

    Assert.assertEquals(expectedResult, actualResult);
    Assert.assertEquals(expectedResult.size(), actualResult.size());
  }

  @Test
  public void
      copyFilesToInternalStorage_whenExecutedSuccessfully_shouldReturnAbsolutePathOfAddedFolder() {
    ArrayList<String> expectedResult =
        new ArrayList<>(
            Collections.singletonList(folder.getRoot() + "/" + folderName + "/" + fileName));
    final ArrayList<String> actualResult =
        PathUtils.copyFilesToInternalStorage(setMockUris(1, mockUri), mockActivity, folderName);

    Assert.assertEquals(expectedResult, actualResult);
  }

  @Test
  public void getSavePathUri_whenDownloadsUri_ReturnsDownloadFolderFileUri() {
    Uri uri = Uri.parse("content://com.android.providers.downloads.documents/document/745");
    when(mockContentResolver.query(
            uri, new String[] {MediaStore.MediaColumns.DISPLAY_NAME}, null, null, null))
        .thenReturn(mockCursor);
    String expected = PathUtils.getSavePathUri(uri, mockActivity);

    Assert.assertEquals(expected, externalDirectoryName + "/Download/" + fileName);
  }

  @Test
  public void getSavePathUri_whenExternalStorageUri_ReturnsExternalStorageFileUri() {
    try (MockedStatic<PathUtils> mocked =
        Mockito.mockStatic(PathUtils.class, Mockito.CALLS_REAL_METHODS)) {
      String externalDir = "TestDir";

      Uri uri =
          Uri.parse(
              "content://com.android.externalstorage.documents/document/primary:"
                  + externalDir
                  + "/123");
      mocked.when(() -> PathUtils.fileExists(anyString())).thenReturn(true);

      when(mockContentResolver.query(
              uri, new String[] {MediaStore.MediaColumns.DISPLAY_NAME}, null, null, null))
          .thenReturn(mockCursor);

      String expected = PathUtils.getSavePathUri(uri, mockActivity);
      Assert.assertEquals(expected, externalDirectoryName + "/" + externalDir + "/" + fileName);
    }
  }

  @Test
  public void getSavePathUri_whenMediaUri_ReturnsMediaFolderFileUri() {
    Uri uri = Uri.parse("content://com.android.providers.media.documents/document/image:31");
    String dir = "content://media/external/images/media";
    when(mockContentResolver.query(
            Uri.parse(dir), new String[] {"_data"}, "_id=?", new String[] {"31"}, null))
        .thenReturn(mockCursor);
    String expected = PathUtils.getSavePathUri(uri, mockActivity);

    Assert.assertEquals(expected, dir + "/" + fileName);
  }

  @Test
  public void clearCache_whenExecutedSuccessfully_shouldRemoveAllFilesFromFolder() {
    int initialFilesCount = Objects.requireNonNull(folder.getRoot().listFiles()).length;
    pathUtils.clearCache(mockActivity);
    int currentFilesCount = Objects.requireNonNull(folder.getRoot().listFiles()).length;

    Assert.assertNotEquals(currentFilesCount, initialFilesCount);
    Assert.assertTrue(initialFilesCount > 0);
    Assert.assertEquals(currentFilesCount, 0);
  }

  private void mockFiles() throws IOException {
    folder.newFile("myFile1.txt");
    folder.newFile("myFile2.txt");

    when(mockActivity.getFilesDir()).thenReturn(folder.getRoot());
  }
}
