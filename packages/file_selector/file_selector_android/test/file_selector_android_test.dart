import 'package:file_selector_android/file_selector_android.dart';
import 'package:file_selector_android/src/messages.g.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'file_selector_android_test.mocks.dart';

@GenerateMocks(<Type>[FileSelectorApi])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FileSelectorAndroid plugin;
  late MockFileSelectorApi mockApi;

  setUp(() {
    mockApi = MockFileSelectorApi();

    plugin = FileSelectorAndroid(mockApi);
  });

  test('registers instance', () async {
    FileSelectorAndroid.registerWith();
    expect(FileSelectorPlatform.instance, isA<FileSelectorAndroid>());
  });

  group('#openFile', () {
    setUp(() {
      when(mockApi.startFileExplorer(any, any, any, any))
          .thenAnswer((_) => Future<List<String?>>.value(<String?>['foo']));
    });

    test('simple call works', () async {
      final XFile? file = await plugin.openFile();

      expect(file!.path, 'foo');
      final VerificationResult result =
          verify(mockApi.startFileExplorer(FileSelectorMethod.OPEN_FILE, captureAny, null, null));
    });
  });
}
