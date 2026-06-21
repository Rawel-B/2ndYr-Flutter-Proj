import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:tp70/entities/absence.dart';
import 'package:tp70/entities/classe.dart';
import 'package:tp70/entities/matiere.dart';
import 'package:tp70/entities/student.dart';

Future<List<Classe>> getAllClasses() async {
  Response response =
      await http.get(Uri.parse("http://10.0.2.2:8080/class/all"));
  List<dynamic> jsonResponse = jsonDecode(response.body);

  // Assuming each item in the jsonResponse can be converted to a Classe
  List<Classe> classes =
      jsonResponse.map((json) => Classe.fromJson(json)).toList();

  return classes;
}

Future<List<Matiere>> getAllMatieres() async {
  Response response =
      await http.get(Uri.parse("http://10.0.2.2:8080/matiere/all"));
  List<dynamic> jsonResponse = jsonDecode(response.body);

  // Assuming each item in the jsonResponse can be converted to a Classe
  List<Matiere> matieres =
      jsonResponse.map((json) => Matiere.fromJson(json)).toList();

  return matieres;
}

// absence

Future addAbsence(Absence absence) async {
  Response response =
      await http.post(Uri.parse("http://10.0.2.2:8080/absence/add"),
          headers: {"Content-type": "Application/json"},
          body: jsonEncode(<String, dynamic>{
            "etudiant": {"id": absence.etudiant?.id},
            "matiere": {"matiereId": absence.matiere?.matiereId},
            "absenceNb": absence.absenceNb,
            "date": absence.date
          }));

  return response.body;
}

Future updateAbsence(Absence absence) async {
  Response response =
      await http.put(Uri.parse("http://10.0.2.2:8080/absence/update"),
          headers: {"Content-type": "Application/json"},
          body: jsonEncode(<String, dynamic>{
            "absenceId": absence.absenceId,
            "absenceNb": absence.absenceNb,
            "etudiant": {"id": absence.etudiant?.id},
            "matiere": {"matiereId": absence.matiere?.matiereId},
            "date": absence.date
          }));

  return response.body;
}

Future deleteAbsence(int? id) {
  return http
      .delete(Uri.parse("http://10.0.2.2:8080/absence/delete?id=${id}"));
}

Future addMatiere(Matiere matiere, int classId) async {
  Response response = await http.post(
      Uri.parse("http://10.0.2.2:8080/matiere/add/$classId"),
      headers: {"Content-type": "Application/json"},
      body: jsonEncode(<String, dynamic>{
        "matiereName": matiere.matiereName,
        "matiereCoef": matiere.matiereCoef
      }));

  return response.body;
}

Future updateMatiere(Matiere matiere) async {
  Response response =
      await http.put(Uri.parse("http://10.0.2.2:8080/matiere/update"),
          headers: {"Content-type": "Application/json"},
          body: jsonEncode(<String, dynamic>{
            "matiereId": matiere.matiereId,
            "matiereName": matiere.matiereName,
            "matiereCoef": matiere.matiereCoef
          }));

  return response.body;
}

Future deleteMatiere(int id) {
  return http.delete(Uri.parse("http://10.0.2.2:8080/matiere/delete?id=${id}"));
}

Future deleteClass(int id) {
  return http.delete(Uri.parse("http://10.0.2.2:8080/class/delete?id=${id}"));
}

Future addClass(Classe classe) async {
  Response response = await http.post(
      Uri.parse("http://10.0.2.2:8080/class/add"),
      headers: {"Content-type": "Application/json"},
      body: jsonEncode(<String, dynamic>{
        "nomClass": classe.nomClass,
        "nbreEtud": classe.nbreEtud
      }));

  return response.body;
}

Future updateClasse(Classe classe) async {
  Response response =
      await http.put(Uri.parse("http://10.0.2.2:8080/class/update"),
          headers: {"Content-type": "Application/json"},
          body: jsonEncode(<String, dynamic>{
            "codClass": classe.codClass,
            "nomClass": classe.nomClass,
            "nbreEtud": classe.nbreEtud
          }));

  return response.body;
}
