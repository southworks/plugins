package io.flutter.plugins.file_selector;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.spy;
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
  int bufferSize = 1024;
  final byte[] fakeByte = new byte[bufferSize];

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
      copyFileToInternalStorage_whenExecutedSuccessfully_shouldReturnAbsolutePathOfAddedFolder() {
    String expectedResult = folder.getRoot() + "\\" + fileName;
    final String actualResult = PathUtils.copyFileToInternalStorage(mockUri, mockActivity);

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
  public void getSavePathUri_whenExternalStorageUri_ReturnsExternalStorageFileUri()
      throws IOException {
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

  private void mockFiles() throws IOException {
    folder.newFile("myFile1.txt");
    folder.newFile("myFile2.txt");

    when(mockActivity.getFilesDir()).thenReturn(folder.getRoot());
  }
}
