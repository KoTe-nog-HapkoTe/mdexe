import 'package:flutter/material.dart';

class TablePage extends StatefulWidget {
  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  final TextEditingController _columnsController = TextEditingController();
  final TextEditingController _rowsController = TextEditingController();

  void _createTable() {
    final int columns = int.tryParse(_columnsController.text) ?? 0;
    final int rows = int.tryParse(_rowsController.text) ?? 0;

    if (columns > 0 && rows > 0 && columns <= 6 && rows <= 6) {
      Navigator.pop(context, [columns, rows]);
    } else {
      // Показать сообщение об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid numbers for columns and rows.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Table'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _columnsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Number of columns'),
            ),
            TextField(
              controller: _rowsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Number of rows'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createTable,
              child: Text('Create Table'),
            ),
          ],
        ),
      ),
    );
  }
}
