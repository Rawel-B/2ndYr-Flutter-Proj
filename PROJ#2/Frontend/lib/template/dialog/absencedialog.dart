import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tp70/entities/absence.dart';
import 'package:tp70/entities/classe.dart';
import 'package:tp70/entities/matiere.dart';
import 'package:tp70/entities/student.dart';
import 'package:tp70/services/classeservice.dart';
import 'package:tp70/services/studentservice.dart';

class AbsenceDialog extends StatefulWidget {
  final Function()? notifyParent;
  final Function()? getAllAbsence;
  Absence? absence;
  List<Matiere>? matieres;
  bool? modif = false;

  AbsenceDialog(
      {super.key,
      @required this.notifyParent,
      this.getAllAbsence,
      this.matieres,
      this.absence,
      this.modif});
  @override
  State<AbsenceDialog> createState() => AbsenceDialogState();
}

class AbsenceDialogState extends State<AbsenceDialog> {
  TextEditingController nbhAbsence = TextEditingController();
  TextEditingController dateAbsence = TextEditingController();

  List<Matiere>? matieres;
  Matiere? selectedMatiere;

  Absence? absence;

  String title = "Ajouter Absence";
  DateTime selectedDate = DateTime.now();

  Student? get selectedStudent => widget.absence?.etudiant;

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        String formattedDateTime =
        DateFormat("yyyy-MM-ddTHH:mm:ss").format(pickedDateTime);

        setState(() {
          dateAbsence.text = formattedDateTime;
          selectedDate = pickedDateTime;
        });
      }
    }
  }


  late int? idAbsence;

  @override
  void initState() {
    matieres = widget.matieres;
    absence = widget.absence;
    print("matiere from dialogabsent: ${matieres.toString()}");
    // TODO: implement initState
    super.initState();

    if (widget.absence != null) {
      title = "Modifier Absence";
      nbhAbsence.text = (widget.absence?.absenceNb).toString();
      dateAbsence.text = (widget.absence?.date).toString();
      idAbsence = widget.absence?.absenceId;
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
              controller: nbhAbsence,
              validator: (String? value) {
                if (value!.isEmpty) {
                  return "Champs est obligatoire";
                }
                return null;
              },
              decoration: const InputDecoration(labelText: "nombre heure"),
            ),
            TextFormField(
              controller: dateAbsence,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Date"),
              onTap: () {
                _selectDate(context);
              },
            ),
            DropdownButtonFormField<Matiere>(
              value: selectedMatiere,
              onChanged: (Matiere? value) {
                setState(() {
                  selectedMatiere = value;
                });
              },
              items: matieres?.map((Matiere matiere) {
                return DropdownMenuItem<Matiere>(
                  value: matiere,
                  child: Text(matiere.matiereName),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: "Matiere"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (widget.modif == false) {
                  print("inserting");
                  await addAbsence(Absence(
                      double.parse(nbhAbsence.text),
                      dateAbsence.text,
                      selectedStudent,
                      selectedMatiere,
                      null))
                      .then((value) => {
                    // get new added absence
                    widget.getAllAbsence!(),
                    widget.notifyParent!()
                  });
                } else {
                  print("updating");
                  await updateAbsence(Absence(
                      double.parse(nbhAbsence.text),
                      dateAbsence.text,
                      absence?.etudiant,
                      selectedMatiere,
                      absence?.absenceId))
                      .then((value) => {
                    // get new added absence
                    widget.getAllAbsence!(),
                    widget.notifyParent!()
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Ajouter"),
            )
          ],
        ),
      ),
    );
  }
}