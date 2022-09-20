import 'package:win32/win32.dart';
import 'dart_place.dart';

/// Exposes custom places.
class CustomPlace {
  /// CustomPlace constructor.
  CustomPlace(this.item, this.place);

  /// An IShellItem.
  IShellItem item;

  /// A Place.
  Place place;
}

/// An abstract of FileDialog, that allows user to interact with the file system.
abstract class FileDialog {
  /// Sets the title of the dialog.
  String title = '';

  /// Sets the text of the label next to the file name edit box.
  String fileNameLabel = '';

  /// Sets the file name that appears in the File name edit box when that dialog
  /// box is opened.
  String fileName = '';

  /// Sets the default extension to be added to file names.
  ///
  /// This string should not include a leading period. For example, "jpg" is
  /// correct, while ".jpg" is not. if this field is set, the dialog will update
  /// the default extension automatically when the user chooses a new file type.
  String? defaultExtension;

  /// Sets a filter for the file types shown.
  ///
  /// When using the Open dialog, the file types declared here are used to
  /// filter the view. When using the Save dialog, these values determine which
  /// file name extension is appended to the file name.
  ///
  /// The first value is the "friendly" name which is shown to the user (e.g.
  /// `JPEG Files`); the second value is a filter, which may be a semicolon-
  /// separated list (for example `*.jpg;*.jpeg`).
  Map<String, String> filterSpecification = <String, String>{};

  /// Which entry in the [filterSpecification] is shown by default. Typically
  /// this is the first entry shown.
  int? defaultFilterIndex;

  /// Hide all of the standard namespace locations (such as Favorites,
  /// Libraries, Computer, and Network) shown in the navigation pane.
  bool hidePinnedPlaces = false;

  /// Ensures that returned items are file system items.
  /// True by default.
  bool forceFileSystemItems = true;

  /// The item returned must exist. This is a default value for the Open dialog.
  bool fileMustExist = false;

  /// Don't change the current working directory.
  bool isDirectoryFixed = false;

  /// Set hWnd of dialog
  int hWndOwner = NULL;

  /// Clears the current filter specification, this way a new filter can be added.
  void clearFilterSpecification() {
    filterSpecification = <String, String>{};
  }
}
