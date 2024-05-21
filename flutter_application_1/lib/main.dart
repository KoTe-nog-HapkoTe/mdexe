import 'package:flutter/material.dart';
import 'package:flutter_application_1/home.dart';
import 'package:flutter_application_1/select_file.dart';
import 'package:flutter_application_1/table.dart';

void main() => runApp(MaterialApp(
  theme: ThemeData(
    primaryColor: Colors.deepOrangeAccent,
  ),
  initialRoute: '/selectFile', // Изначально запускаем SelectFile
  routes: {
    '/home': (context) => Home(), // Маршрут для Home
    '/selectFile': (context) => SelectFile(), // Маршрут для SelectFile
    '/table': (context) => TablePage(),
  },
));