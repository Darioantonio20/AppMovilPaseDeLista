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
  final TextEditingController _subjectController = TextEditingController(); // Nuevo campo para materia

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
      subject: _subjectController.text, // Materia añadida
      institutionId: widget.institution.id!,
    );
    await DatabaseService().addGradeGroup(gradeGroup);
    _gradeController.clear();
    _groupController.clear();
    _subjectController.clear(); // Limpiar después de guardar
    _loadGradeGroups();
  }

  void _deleteGradeGroupWithAnimation(int gradeGroupId) {
    setState(() {
      gradeGroups.removeWhere((gradeGroup) => gradeGroup.id == gradeGroupId);
    });

    Future.delayed(Duration(milliseconds: 300), () async {
      await DatabaseService().deleteGradeGroup(gradeGroupId);
      _loadGradeGroups();
    });
  }

  void _showDeleteConfirmation(GradeGroup gradeGroup) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Está seguro de que desea eliminar el grupo ${gradeGroup.grade} - ${gradeGroup.group}?'),
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
                Navigator.of(context).pop();
                _deleteGradeGroupWithAnimation(gradeGroup.id!);
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
        title: Text('Grupos de ${widget.institution.name}'),
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
                    title: Text('Agregar Grado, Grupo y Materia'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _gradeController,
                          cursorColor: const Color.fromARGB(255, 84, 112, 179),
                          decoration: InputDecoration(
                            labelText: 'Grado',
                            labelStyle: TextStyle(color: const Color.fromARGB(255, 84, 112, 179)),
                            focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: const Color.fromARGB(255, 84, 112, 179)),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _groupController,
                          cursorColor: const Color.fromARGB(255, 84, 112, 179),
                          decoration: InputDecoration(
                            labelText: 'Grupo',
                            labelStyle: TextStyle(color: const Color.fromARGB(255, 84, 112, 179)),
                            focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: const Color.fromARGB(255, 84, 112, 179)),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _subjectController,
                          cursorColor: const Color.fromARGB(255, 84, 112, 179),
                          decoration: InputDecoration(labelText: 'Materia',
                            labelStyle: TextStyle(color: const Color.fromARGB(255, 84, 112, 179)),
                            focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: const Color.fromARGB(255, 84, 112, 179)),
                            ),
                          ), 
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
          GradeGroup gradeGroup = gradeGroups[index];
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
                child: Icon(Icons.groups,
                  color: const Color.fromARGB(255, 84, 112, 179), size: 30),
                backgroundColor: const Color.fromARGB(255, 237, 235, 235),
              ),
            ),
              contentPadding: EdgeInsets.all(16.0),
              title: Text(
                '${gradeGroup.grade} - ${gradeGroup.group} - ${gradeGroup.subject}', // Mostrar materia
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                iconSize: 35,
                color: Colors.red,
                onPressed: () {
                  _showDeleteConfirmation(gradeGroup);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentsScreen(gradeGroup: gradeGroup),
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
