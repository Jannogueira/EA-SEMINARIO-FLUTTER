import 'organization.dart';

class Task {
  final String id;
  final String titulo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final List<OrganizationUser> usuarios;
  final String estado;

  Task({
    required this.id,
    required this.titulo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.usuarios,
    this.estado = 'To do',
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final String id = (json['_id'] ?? json['id'] ?? '').toString();
    final String titulo = (json['titulo'] ?? json['title'] ?? 'Sin título')
        .toString();

    return Task(
      id: id,
      titulo: titulo,
      fechaInicio: _parseDate(json['fechaInicio'] ?? json['fecha_inicio']),
      fechaFin: _parseDate(json['fechaFin'] ?? json['fecha_fin']),
      usuarios:
          (json['usuarios'] as List<dynamic>?)
              ?.map((dynamic u) => OrganizationUser.fromJson(u))
              .toList() ??
          [],
      estado: json['estado'] ?? 'To do',
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('Fecha inválida en Task: $value');
  }
}
