import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tp70/entities/classe.dart';
import 'package:tp70/entities/matiere.dart';
import 'package:tp70/entities/student.dart';
import 'package:tp70/services/classeservice.dart';
import 'package:tp70/services/studentservice.dart';

class MatiereDialog extends StatefulWidget {
  final Function()? notifyParent;
  Matiere? matiere;

  MatiereDialog({super.key, @required this.notifyParent, this.matiere});
  @override
  State<MatiereDialog> createState() => _MatierDialogState();
}

class _MatierDialogState extends State<MatiereDialog> {
  TextEditingController nameMat = TextEditingController();
  TextEditingController coefMat = TextEditingController();
  Classe? selectedClass;
  List<Classe> classes = [];

  String title = "Ajouter Matiere";
  bool modif = false;

  late int idMatiere;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAllClasses().then((result) {
      // Check if the result is a List<Classe> before assigning
      setState(() {
        classes = result;
      });
    });

    print("hiii");
    if (widget.matiere != null) {
      modif = true;
      title = "Modifier matiere";
      nameMat.text = (widget.matiere!.matiereName).toString();
      coefMat.text = (widget.matiere!.matiereCoef).toString();
      idMatiere = widget.matiere!.matiereId!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(title),
            TextFormField(
              controller: nameMat,
              validator: (String? value) {
                if (value!.isEmpty) {
                  return "Champs est obligatoire";
                }
                return null;
              },
              decoration: const InputDecoration(labelText: "nom"),
            ),
            TextFormField(
              controller: coefMat,
              decoration: const InputDecoration(labelText: "coef"),
            ),
            DropdownButtonFormField<Classe>(
              value: selectedClass,
              onChanged: (Classe? value) {
                setState(() {
                  selectedClass = value;
                });
              },
              items: classes.map((Classe classe) {
                return DropdownMenuItem<Classe>(
                  value: classe,
                  child: Text(classe.nomClass),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: "Classe"),
            ),
            ElevatedButton(
                onPressed: () async {
                  if (modif == false) {
                    await addMatiere(
                        Matiere(nameMat.text, double.parse(coefMat.text)),selectedClass!.codClass!);
                    widget.notifyParent!();
                  } else {
                    await updateMatiere(Matiere(
                        nameMat.text, double.parse(coefMat.text), idMatiere));
                    widget.notifyParent!();
                  }
                  Navigator.pop(context);
                },
                child: const Text("Ajouter"))
          ],
        ),
      ),
    );
  }
}
