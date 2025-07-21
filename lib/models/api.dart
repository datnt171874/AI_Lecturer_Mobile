import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<User> fetchUser() async {
  final response = await http.get(
    Uri.parse('https://localhost:8080/api/register'),
    // Send authorization headers to the backend.
    headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
  );
  final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

  return User.fromJson(responseJson);
}

class User {
  final String username;
  final String fullName;
  final String email;
  final String password;
  final String role;

  const User({
    required this.username,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'userName': final username,
        'fullName': final fullName,
        'email': final email,
        'password': final password,
        'role': final role,
      } =>
        User(
          username: username as String,
          fullName: fullName as String,
          email: email as String,
          password: password as String,
          role: role as String,
        ),
      _ => throw const FormatException('Failed to get data.'),
    };
  }
}
