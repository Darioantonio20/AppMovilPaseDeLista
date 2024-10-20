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
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                _deleteInstitution(institution.id!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instituciones'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
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
                          decoration: InputDecoration(labelText: 'Nombre de la Institución'),
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
                        child: Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
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
          return ListTile(
            title: Text(institutions[index].name),
            subtitle: Text('Turno: ${institutions[index].turno}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation(institutions[index]);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GradeGroupScreen(institution: institutions[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
