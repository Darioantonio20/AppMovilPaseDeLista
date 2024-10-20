import 'package:flutter/material.dart';
import '../models/institution_model.dart';
import '../services/database_service.dart';
import 'students_screen.dart';

class GradeGroupScreen extends StatefulWidget {
  final Institution institution;

  GradeGroupScreen({required this.institution});

  @override
  _GradeGroupScreenState createState() => _GradeGroupScreenState();
}

class _GradeGroupScreenState extends State<GradeGroupScreen> {
  List<GradeGroup> gradeGroups = [];
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGradeGroups();
  }

  void _loadGradeGroups() async {
    final data = await DatabaseService().getGradeGroupsByInstitution(widget.institution.id!);
    setState(() {
      gradeGroups = data;
    });
  }

  void _addGradeGroup() async {
    final gradeGroup = GradeGroup(
      grade: _gradeController.text,
      group: _groupController.text,
      institutionId: widget.institution.id!,
    );
    await DatabaseService().addGradeGroup(gradeGroup);
    _gradeController.clear();
    _groupController.clear();
    _loadGradeGroups();
  }

  void _deleteGradeGroup(int gradeGroupId) async {
    await DatabaseService().deleteGradeGroup(gradeGroupId);
    _loadGradeGroups();
  }

  void _showDeleteConfirmation(GradeGroup gradeGroup) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Está seguro de que desea eliminar el grado ${gradeGroup.grade} y grupo ${gradeGroup.group}?'),
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
                _deleteGradeGroup(gradeGroup.id!);
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
        title: Text('Grados y Grupos de ${widget.institution.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Agregar Grado y Grupo'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _gradeController,
                          decoration: InputDecoration(labelText: 'Grado'),
                        ),
                        TextField(
                          controller: _groupController,
                          decoration: InputDecoration(labelText: 'Grupo'),
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
                          _addGradeGroup();
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
        itemCount: gradeGroups.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('${gradeGroups[index].grade} - ${gradeGroups[index].group}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation(gradeGroups[index]);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentsScreen(gradeGroup: gradeGroups[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
