import 'package:flutter/material.dart';
import '../models/institution_model.dart';
import '../services/database_service.dart';
import 'grade_group_screen.dart';

class InstitutionsScreen extends StatefulWidget {
  @override
  _InstitutionsScreenState createState() => _InstitutionsScreenState();
}

class _InstitutionsScreenState extends State<InstitutionsScreen> {
  List<Institution> institutions = [];
  final TextEditingController _nameController = TextEditingController();
  String _selectedTurno = 'Matutino';

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  void _loadInstitutions() async {
    final data = await DatabaseService().getInstitutions();
    setState(() {
      institutions = data;
    });
  }

  void _addInstitution() async {
    final institution = Institution(
      name: _nameController.text,
      turno: _selectedTurno,
    );
    await DatabaseService().addInstitution(institution);
    _nameController.clear();
    _loadInstitutions();
  }

  void _deleteInstitution(int institutionId) async {
    await DatabaseService().deleteInstitution(institutionId);
    _loadInstitutions();
  }

  void _showDeleteConfirmation(Institution institution) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Está seguro de que desea eliminar la institución ${institution.name}?'),
          actions: [
            TextButton(
              child: Text(
                'Cancelar',
                style: TextStyle(fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 84, 112, 179),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Eliminar',
                style: TextStyle(fontSize: 17),
                ),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 177, 19, 19),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();  // Cerrar el diálogo antes de la animación
                _deleteInstitutionWithAnimation(institution.id!);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteInstitutionWithAnimation(int institutionId) {
    // Animación para eliminar una institución
    setState(() {
      institutions.removeWhere((institution) => institution.id == institutionId);
    });

    Future.delayed(Duration(milliseconds: 300), () async {
      await DatabaseService().deleteInstitution(institutionId);
      _loadInstitutions(); // Recargar la lista
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instituciones'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            color: const Color.fromARGB(255, 77, 191, 128),
            iconSize: 33,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Agregar Institución'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nameController,
                          cursorColor: const Color.fromARGB(255, 84, 112, 179),
                          decoration: InputDecoration(
                            labelText: 'Nombre de la Institución',
                            labelStyle: TextStyle(color: const Color.fromARGB(255, 84, 112, 179)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: const Color.fromARGB(255, 84, 112, 179)),
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedTurno,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTurno = newValue!;
                            });
                          },
                          items: ['Matutino', 'Vespertino'].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                         style: ElevatedButton.styleFrom(
                          foregroundColor: const Color.fromARGB(255, 177, 19, 19),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 17),
                         ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 84, 112, 179),
                          textStyle: TextStyle(fontSize: 17),
                        ),
                        child: Text('Guardar'),
                        onPressed: () {
                          _addInstitution();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: institutions.length,
        itemBuilder: (context, index) {
          Institution institution = institutions[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: ListTile(
             leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: CircleAvatar(
                child: Icon(Icons.school_sharp,
                  color: const Color.fromARGB(255, 84, 112, 179), size: 30),
                backgroundColor: const Color.fromARGB(255, 237, 235, 235),
              ),
            ),
              contentPadding: EdgeInsets.all(16.0),
              title: Text(
                institution.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text(
                'Turno: ${institution.turno}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                iconSize: 35,
                color: Colors.red,
                onPressed: () {
                  _showDeleteConfirmation(institution);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GradeGroupScreen(institution: institution),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
