import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart' as open;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _controller;
  late TextEditingController _textEditingController;
  String _originalFileText = "";
  String _editingText = "";

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
    _textEditingController = TextEditingController();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> saveMarkdownToFile(String text, String fileName) async {
    await _requestPermissions();

    final Directory? externalStorageDirectory = await getExternalStorageDirectory();
    if (externalStorageDirectory == null) {
      print('Error: External storage directory is not available.');
      return;
    }

    // Path for .txt files
    final String txtDownloadDirectory = '${externalStorageDirectory.path}/Download';
    final Directory txtDownloadDir = Directory(txtDownloadDirectory);
    if (!await txtDownloadDir.exists()) {
      await txtDownloadDir.create(recursive: true);
    }

    // Path for .html files
    final Directory htmlDownloadDirectory = Directory('/storage/emulated/0/Download');
    if (!await htmlDownloadDirectory.exists()) {
      await htmlDownloadDirectory.create(recursive: true);
    }

    // Save .txt file
    final String txtFilePath = '$txtDownloadDirectory/$fileName.txt';
    final File txtFile = File(txtFilePath);
    await txtFile.writeAsString(text);

    // Save .html file
    final String htmlFilePath = '${htmlDownloadDirectory.path}/$fileName.html';
    final File htmlFile = File(htmlFilePath);

    String htmlText = md.markdownToHtml(text, extensionSet: md.ExtensionSet.gitHubWeb);

    String styledHtmlText = """
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      padding: 8px;
      text-align: left;
    }
    </style>
    </head>
    <body>
    $htmlText
    </body>
    </html>
    """;

    await htmlFile.writeAsString(styledHtmlText);

    print('Text file saved at: $txtFilePath');
    print('HTML file saved at: $htmlFilePath');
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController fileNameController = TextEditingController();
        return AlertDialog(
          title: Text('Save File'),
          content: TextField(
            controller: fileNameController,
            decoration: InputDecoration(hintText: "Enter file name"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final fileName = fileNameController.text;
                if (fileName.isNotEmpty) {
                  await saveMarkdownToFile(_editingText, fileName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.save),
                title: Text('Save Files'),
                onTap: () {
                  Navigator.pop(context);
                  _showSaveDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share HTML'),
                onTap: () {
                  //_shareHtmlFile();
                  //OpenFile.open("https://www.youtube.com/watch?v=6tfBflFUO7s");
                  open.OpenFile.open('/storage/emulated/0/Download/input.html');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareHtmlFile() async {
    final Directory? directory = await getExternalStorageDirectory();
    if (directory == null) {
      print('Error: External storage directory is not available.');
      return;
    }

    final String downloadDirectory = '${directory.path}/Download';
    final String currentTime = DateTime.now().toString();
    final String htmlFileName = '${currentTime}.html';
    final String htmlFilePath = '$downloadDirectory/$htmlFileName';
  }

  void _formatSelectedText(String formatType) {
    final TextSelection selection = _textEditingController.selection;
    final String selectedText = _textEditingController.text.substring(selection.start, selection.end);
    String formattedText;

    switch (formatType) {
      case 'italic':
        formattedText = '*$selectedText*';
        break;
      case 'bold':
        formattedText = '**$selectedText**';
        break;
      case 'without':
        formattedText = '~~$selectedText~~';
        break;
      case 'h1':
        formattedText = '# $selectedText';
        break;
      case 'URL':
        formattedText = '[text](URL)';
        break;
      default:
        formattedText = selectedText;
    }

    setState(() {
      _textEditingController.text = _textEditingController.text.replaceRange(selection.start, selection.end, formattedText);
      _editingText = _textEditingController.text;
      _textEditingController.selection = TextSelection.collapsed(offset: selection.start + formattedText.length);
    });
  }

  void _insertTable(int columns, int rows) {
    final String tableMarkdown = _generateTableMarkdown(columns, rows);
    final TextSelection selection = _textEditingController.selection;
    final int cursorPos = selection.baseOffset;

    setState(() {
      _textEditingController.text = _textEditingController.text.replaceRange(cursorPos, cursorPos, tableMarkdown);
      _editingText = _textEditingController.text;
      _textEditingController.selection = TextSelection.collapsed(offset: cursorPos + tableMarkdown.length);
    });
  }

  String _generateTableMarkdown(int columns, int rows) {
    final StringBuffer tableBuffer = StringBuffer();

    // Header row
    tableBuffer.write('|');
    for (int i = 0; i < columns; i++) {
      tableBuffer.write(' Header $i |');
    }
    tableBuffer.write('\n');

    // Separator row
    tableBuffer.write('|');
    for (int i = 0; i < columns; i++) {
      tableBuffer.write(' --- |');
    }
    tableBuffer.write('\n');

    // Data rows
    for (int i = 0; i < rows; i++) {
      tableBuffer.write('|');
      for (int j = 0; j < columns; j++) {
        tableBuffer.write(' Data $i$j |');
      }
      tableBuffer.write('\n');
    }

    return tableBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final File file = arguments['file'];

    if (_originalFileText.isEmpty) {
      _originalFileText = file.readAsStringSync();
      _editingText = _originalFileText;
      _textEditingController.text = _editingText;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Markdown Editor",
          style: TextStyle(color: Colors.black),
        ),
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Tab(
              child: Text("Edit", style: TextStyle(color: Colors.black)),
            ),
            Tab(
              child: Text("Preview", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
        actions: [
          //------------------------------------------------------show menu
          // IconButton(
          //   icon: Icon(Icons.menu),
          //   onPressed: () {
          //     _showActionMenu(context);
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.navigate_before),
            onPressed: () {
              Navigator.pushNamed(context, '/selectFile');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.format_italic),
                  onPressed: () => _formatSelectedText('italic'),
                ),
                IconButton(
                  icon: Icon(Icons.format_bold),
                  onPressed: () => _formatSelectedText('bold'),
                ),
                IconButton(
                  icon: Icon(Icons.format_strikethrough),
                  onPressed: () => _formatSelectedText('without'),
                ),
                IconButton(
                  icon: Icon(Icons.format_size),
                  onPressed: () => _formatSelectedText('h1'),
                ),
                IconButton(
                  icon: Icon(Icons.link),
                  onPressed: () => _formatSelectedText('URL'),
                ),
                IconButton(
                  icon: Icon(Icons.table_chart),
                  onPressed: () async {
                    final result = await Navigator.pushNamed(context, '/table');
                    if (result != null && result is List<int>) {
                      _insertTable(result[0], result[1]);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: [
                Container(
                  margin: EdgeInsets.all(20),
                  child: TextField(
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "INPUT TEXT",
                    ),
                    onChanged: (String text) {
                      setState(() {
                        _editingText = text;
                      });
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(20),
                  child: Markdown(data: _editingText),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //_showActionMenu(context);
          _showSaveDialog(context);
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
