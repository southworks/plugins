package io.flutter.plugins.file_selector;

import android.app.Activity;
import android.content.ContentResolver;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.io.IOException;
import java.io.InputStream;
import java.nio.Buffer;
import java.util.Objects;

import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.when;

public class PathUtilsTest {
    static TemporaryFolder folder;
    static final String fileName = "FileName";
    int bufferSize = 1024;
    final byte[] fakeByte = new byte[bufferSize];

    @Mock Activity mockActivity;
    @Mock Uri mockUri;
    @Mock Cursor mockCursor;
    @Mock ContentResolver mockContentResolver;
    @Mock InputStream mockInputStream;
    @Mock Buffer mockBuffer;

    @Before
    public void setUp() throws IOException {
        MockitoAnnotations.openMocks(this);

        folder = new TemporaryFolder();
        folder.create();

        when(mockCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)).thenReturn(0);
        when(mockContentResolver.query(mockUri, new String[]{
                OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE
        }, null, null, null)).thenReturn(mockCursor);
        when(mockActivity.getContentResolver()).thenReturn(mockContentResolver);
        when(mockInputStream.read(fakeByte)).thenReturn(-1);
        when(mockContentResolver.openInputStream(mockUri)).thenReturn(mockInputStream);
        when(mockCursor.moveToFirst()).thenReturn(true);
        when(mockCursor.getString(0)).thenReturn(fileName);

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
        folder.delete();
    }

    @Test
    public void getFileName_shouldReturnTheFileName() {
        final String actualResult = PathUtils.getFileName(mockUri, mockActivity);

        Assert.assertEquals(fileName, actualResult);
    }

    @Test
    public void copyFileToInternalStorage_shouldReturnAbsolutePathOfAddedFolder() throws Exception {
        String expectedResult = folder.getRoot() + "\\" + fileName;
        final String actualResult = PathUtils.copyFileToInternalStorage(mockUri, mockActivity, "");

        Assert.assertEquals(expectedResult, actualResult);
    }

    @Test
    public void clearCache_shouldRemoveAllFilesFromFolder() {
        int initialFilesCount = Objects.requireNonNull(folder.getRoot().listFiles()).length;
        PathUtils.clearCache(mockActivity, "");
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