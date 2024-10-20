import 'package:flutter/material.dart';
import 'institutions_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pase de Lista',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InstitutionsScreen(), // Redirige a la pantalla de instituciones
      debugShowCheckedModeBanner: false,
    );
  }
}
