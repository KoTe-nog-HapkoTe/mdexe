import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SelectFile extends StatefulWidget {
  @override
  _SelectFileState createState() => _SelectFileState();
}

class _SelectFileState extends State<SelectFile> {
  late List<File> _files;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      final String downloadDirectory = '${directory.path}/Download';
      final Directory downloadDir = Directory(downloadDirectory);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      setState(() {
        _files = downloadDir
            .listSync()
            .where((entity) =>
                entity is File && entity.path.endsWith('.txt'))
            .map((entity) => File(entity.path))
            .toList();
      });

      // Проверяем, существует ли файл origin.txt, и если нет, создаем его
      final String originFilePath = '${directory.path}/origin.txt';
      final File originFile = File(originFilePath);
      if (!await originFile.exists()) {
        await originFile.writeAsString('* INPUT MD');
      }
    }
  }

  void _onFileSelected(File file) {
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'file': file},
    );
  }

  void _openOriginFile() async {
    final Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      final String originFilePath = '${directory.path}/origin.txt';
      final File originFile = File(originFilePath);
      if (await originFile.exists()) {
        _onFileSelected(originFile);
      }
    }
  }

    void _deleteFiles(File file) async {
    final String fileName = file.path.split('/').last;
    final String filePathWithoutExtension =
        file.path.substring(0, file.path.length - 4); // Убираем ".txt" из пути
    final String htmlFilePath = '$filePathWithoutExtension.html';

    // Удаляем .txt и .html файлы
    await file.delete();
    final File htmlFile = File(htmlFilePath);
    if (await htmlFile.exists()) {
      await htmlFile.delete();
    }

    // Перезагружаем список файлов
    _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select File'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _openOriginFile,
          ),
        ],
      ),
            body: _files == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return ListTile(
                  title: Text(file.path.split('/').last),
                  // trailing: PopupMenuButton(
                  //   itemBuilder: (context) => [
                  //     PopupMenuItem(
                  //       value: 'delete',
                  //       child: Text('Delete .txt and .html files'),
                  //     ),
                  //     PopupMenuItem(
                  //       value: 'placeholder',
                  //       child: Text('Placeholder'),
                  //     ),
                  //   ],
                  //   onSelected: (String value) {
                  //     if (value == 'delete') {
                  //       _deleteFiles(file);
                  //     }
                  //     // Handle other menu items here if needed
                  //   },
                  // ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteFiles(file);
                    },
                  ),
                  onTap: () => _onFileSelected(file),
                );
              },
            ),
    );
  }
}