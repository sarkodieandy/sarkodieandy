import 'package:file_picker/file_picker.dart';

class MediaService {
  MediaService();

  // Pick image from library
  Future<PlatformFile?> pickImageFromLibrary() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      return result.files[0];
    }
    return null;
  }

  // Pick video from library
  Future<PlatformFile?> pickVideoFromLibrary() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      return result.files[0];
    }
    return null;
  }
}
