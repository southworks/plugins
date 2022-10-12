package io.flutter.plugins.file_selector;

import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.ContentResolver;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;
import java.io.IOException;
import java.io.InputStream;
import java.nio.Buffer;
import java.util.Objects;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;

public class PathUtilsTest {
  static TemporaryFolder folder;
  static final String fileName = "FileName";
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
    final String actualResult = pathUtils.getFileName(mockUri, mockActivity);

    Assert.assertEquals(fileName, actualResult);
  }

  @Test
  public void
      copyFileToInternalStorage_whenCacheFolderNameIsNotPassed_shouldInvokeCopyFileToInternalStorageWithEmptyString() {
    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      spyPathUtils.copyFileToInternalStorage(mockUri, mockActivity);

      mockedPathUtils.verify(
          () -> PathUtils.copyFileToInternalStorage(mockUri, mockActivity, ""), times(1));
    }
  }

  @Test
  public void
      copyFileToInternalStorage_whenExecutedSuccessfully_shouldReturnAbsolutePathOfAddedFolder() {
    String expectedResult = folder.getRoot() + "\\" + fileName;
    final String actualResult = pathUtils.copyFileToInternalStorage(mockUri, mockActivity);

    Assert.assertEquals(expectedResult, actualResult);
  }

  @Test
  public void clearCache_whenCacheFolderNameIsNotPassed_shouldInvokeClearCacheWithEmptyString() {
    try (MockedStatic<PathUtils> mockedPathUtils = Mockito.mockStatic(PathUtils.class)) {
      spyPathUtils.clearCache(mockActivity);

      mockedPathUtils.verify(() -> PathUtils.clearCache(mockActivity, ""), times(1));
    }
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
