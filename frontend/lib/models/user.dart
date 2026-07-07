// user.dart — modelo de dados do usuário
class User {
  final int id;
  final String email;
  final bool emailVerified;
  final DateTime criadoEm;

  User({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.criadoEm,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        emailVerified: json['email_verified'] as bool,
        criadoEm: DateTime.parse(json['criado_em'] as String),
      );
}
