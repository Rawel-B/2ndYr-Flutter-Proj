import 'dart:ffi';

class Matiere {
  int? matiereId;
  String matiereName;
  double matiereCoef;

  Matiere(this.matiereName, this.matiereCoef, [this.matiereId]);

  // Factory method to create a Classe object from JSON
  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      json['matiereName'],
      json['matiereCoef'],
      json['matiereId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matiereName': matiereName,
      'matiereCoef': matiereCoef,
      'matiereId': matiereId,
    };
  }

  @override
  String toString() {
    return matiereName;
  }
}
