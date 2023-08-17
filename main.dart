import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FilePickerApp(),
    );
  }
}

class FilePickerApp extends StatefulWidget {
  @override
  _FilePickerAppState createState() => _FilePickerAppState();
}

class _FilePickerAppState extends State<FilePickerApp> {
  String _filePath = "";

  Future<void> _pickFile() async {
    // Dosya dizinine erişim izni isteği
    PermissionStatus storageStatus = await Permission.storage.request();
    PermissionStatus photosStatus = await Permission.photos.request();

    if (Platform.isAndroid) {
    // Android için photos izni kontrolü
    PermissionStatus photosStatus = await Permission.photos.request();

    if (photosStatus.isGranted) {
      // İzin verildiğinde dosya seçme işlemi
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _filePath = result.files.single.path!;
        });

        await uploadZippedFileToFTP(File(_filePath));
      } else {
        // Kullanıcı dosya seçimini iptal etti.
      }
      } else if (photosStatus.isDenied || photosStatus.isPermanentlyDenied) {
        // Kullanıcı izni reddetti veya kalıcı olarak reddetti.
        // Burada bir bildirim veya açıklama gösterebilirsiniz.
      }
    } 
    else if (Platform.isIOS) {
      // iOS için storage izni kontrolü
      PermissionStatus storageStatus = await Permission.storage.request();

      if (storageStatus.isGranted) {
        // İzin verildiğinde dosya seçme işlemi
        FilePickerResult? result = await FilePicker.platform.pickFiles();

        if (result != null) {
          setState(() {
            _filePath = result.files.single.path!;
          });

          await uploadZippedFileToFTP(File(_filePath));
        } else {
          // Kullanıcı dosya seçimini iptal etti.
        }
      } else if (storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
        // Kullanıcı izni reddetti veya kalıcı olarak reddetti.
        // Burada bir bildirim veya açıklama gösterebilirsiniz.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("File Picker Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Text("Select File"),
            ),
            SizedBox(height: 20),
            Text("Selected File: $_filePath"),
          ],
        ),
      ),
    );
  }
}

Future<void> uploadZippedFileToFTP(File selectedFile) async {
  String username = "YOUR_USERNAME"; // FTP kullanıcı adı
  String password = r'YOUR_PA$$WORD'; // FTP şifresi

  // Sıkıştırılmış dosya oluştur
  final archive = Archive();
  final fileName = selectedFile.path.split('/').last;
  final fileContent = await selectedFile.readAsBytes();
  archive.addFile(ArchiveFile(fileName, fileContent.length, fileContent));

  // Sıkıştırılmış dosyayı bellekte oluştur
  final zipBytes = ZipEncoder().encode(archive);

  // Dosyanın FTP'ye yüklenmesi
  Dio dio = Dio();
  String serverUrl = "ftp.YOUR_SERVER_ADRESS.com:YOUR_PORT"; // FTP server URL

  FormData formData = FormData.fromMap({
    "file": MultipartFile.fromBytes(zipBytes!, filename: "$fileName.zip"),
  });

  try {
    Response response = await dio.post(
      serverUrl,
      data: formData,
      options: Options(
        method: 'POST',
        responseType: ResponseType.plain,
        headers: {
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
        },
      ),
    );

    print("Upload response: ${response.data}");
  } catch (error) {
    print("Upload error: $error");
  }
}
