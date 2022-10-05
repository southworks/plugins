
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

/// Options for Dialog window
class SelectionOptions {

  /// Creates a new [SelectionOptions] instace with the specified values.
  /// It defaults [allowMultiple] to false, [selectFolders] to false and no [allowedTypes]
  SelectionOptions({
    this.allowMultiple = false,
    this.selectFolders = false,
    this.allowedTypes = const <XTypeGroup?>[],
  });

  /// Indicates whether the user is able to select multiple items at the same time or not.
  bool allowMultiple;

  /// Indicates whether the user is able to select folders or not.
  bool selectFolders;

  /// A list of file types that can be selected.
  List<XTypeGroup?> allowedTypes;
}
