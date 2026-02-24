class User {
  final String id;
  final String username;
  final String email;
  final String avatar;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatar,
  });

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
    };
  }
}
