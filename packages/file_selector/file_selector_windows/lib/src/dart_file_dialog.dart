import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'dart_folders.dart';
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
  /// A mapping of known folders to GUID references.
  final Map<WindowsKnownFolder, String> _knownFolderMappings =
      <WindowsKnownFolder, String>{
    WindowsKnownFolder.AdminTools: FOLDERID_AdminTools,
    WindowsKnownFolder.CDBurning: FOLDERID_CDBurning,
    WindowsKnownFolder.CommonAdminTools: FOLDERID_CommonAdminTools,
    WindowsKnownFolder.CommonPrograms: FOLDERID_CommonPrograms,
    WindowsKnownFolder.CommonStartMenu: FOLDERID_CommonStartMenu,
    WindowsKnownFolder.CommonStartup: FOLDERID_CommonStartup,
    WindowsKnownFolder.CommonTemplates: FOLDERID_CommonTemplates,
    WindowsKnownFolder.ComputerFolder: FOLDERID_ComputerFolder,
    WindowsKnownFolder.ConnectionsFolder: FOLDERID_ConnectionsFolder,
    WindowsKnownFolder.ControlPanelFolder: FOLDERID_ControlPanelFolder,
    WindowsKnownFolder.Cookies: FOLDERID_Cookies,
    WindowsKnownFolder.Desktop: FOLDERID_Desktop,
    WindowsKnownFolder.Documents: FOLDERID_Documents,
    WindowsKnownFolder.Downloads: FOLDERID_Downloads,
    WindowsKnownFolder.Favorites: FOLDERID_Favorites,
    WindowsKnownFolder.Fonts: FOLDERID_Fonts,
    WindowsKnownFolder.History: FOLDERID_History,
    WindowsKnownFolder.InternetCache: FOLDERID_InternetCache,
    WindowsKnownFolder.InternetFolder: FOLDERID_InternetFolder,
    WindowsKnownFolder.LocalAppData: FOLDERID_LocalAppData,
    WindowsKnownFolder.Music: FOLDERID_Music,
    WindowsKnownFolder.NetHood: FOLDERID_NetHood,
    WindowsKnownFolder.NetworkFolder: FOLDERID_NetworkFolder,
    WindowsKnownFolder.Pictures: FOLDERID_Pictures,
    WindowsKnownFolder.PrintHood: FOLDERID_PrintHood,
    WindowsKnownFolder.PrintersFolder: FOLDERID_PrintersFolder,
    WindowsKnownFolder.Profile: FOLDERID_Profile,
    WindowsKnownFolder.ProgramData: FOLDERID_ProgramData,
    WindowsKnownFolder.ProgramFiles: FOLDERID_ProgramFiles,
    WindowsKnownFolder.ProgramFilesCommon: FOLDERID_ProgramFilesCommon,
    WindowsKnownFolder.ProgramFilesCommonX64: FOLDERID_ProgramFilesCommonX64,
    WindowsKnownFolder.ProgramFilesCommonX86: FOLDERID_ProgramFilesCommonX86,
    WindowsKnownFolder.ProgramFilesX64: FOLDERID_ProgramFilesX64,
    WindowsKnownFolder.ProgramFilesX86: FOLDERID_ProgramFilesX86,
    WindowsKnownFolder.Programs: FOLDERID_Programs,
    WindowsKnownFolder.PublicDesktop: FOLDERID_PublicDesktop,
    WindowsKnownFolder.PublicDocuments: FOLDERID_PublicDocuments,
    WindowsKnownFolder.PublicMusic: FOLDERID_PublicMusic,
    WindowsKnownFolder.PublicPictures: FOLDERID_PublicPictures,
    WindowsKnownFolder.PublicVideos: FOLDERID_PublicVideos,
    WindowsKnownFolder.Recent: FOLDERID_Recent,
    WindowsKnownFolder.RecycleBinFolder: FOLDERID_RecycleBinFolder,
    WindowsKnownFolder.ResourceDir: FOLDERID_ResourceDir,
    WindowsKnownFolder.RoamingAppData: FOLDERID_RoamingAppData,
    WindowsKnownFolder.SendTo: FOLDERID_SendTo,
    WindowsKnownFolder.StartMenu: FOLDERID_StartMenu,
    WindowsKnownFolder.Startup: FOLDERID_Startup,
    WindowsKnownFolder.System: FOLDERID_System,
    WindowsKnownFolder.SystemX86: FOLDERID_SystemX86,
    WindowsKnownFolder.Templates: FOLDERID_Templates,
    WindowsKnownFolder.Videos: FOLDERID_Videos,
    WindowsKnownFolder.Windows: FOLDERID_Windows,
  };

  /// A list of custom places. Use [addPlace] to add an item to this list.
  final List<CustomPlace> customPlaces = <CustomPlace>[];

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

  /// Add a known folder to the 'Quick Access' list.
  void addPlace(WindowsKnownFolder folder, Place location) {
    int hResult = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    final String folderGUID = _knownFolderMappings[folder]!;
    final KnownFolderManager knownFolderManager =
        KnownFolderManager.createInstance();
    final Pointer<GUID> publicMusicFolder = calloc<GUID>()
      ..ref.setGUID(folderGUID);

    final Pointer<Pointer<COMObject>> ppkf = calloc<Pointer<COMObject>>();
    hResult = knownFolderManager.getFolder(publicMusicFolder, ppkf);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
    final IKnownFolder knownFolder = IKnownFolder(ppkf.cast());

    final Pointer<Pointer<NativeType>> psi = calloc<Pointer<NativeType>>();
    final Pointer<GUID> riid = convertToIID(IID_IShellItem);
    hResult = knownFolder.getShellItem(0, riid, psi);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
    final IShellItem shellItem = IShellItem(psi.cast());

    customPlaces.add(CustomPlace(shellItem, location));

    CoUninitialize();
  }
}
