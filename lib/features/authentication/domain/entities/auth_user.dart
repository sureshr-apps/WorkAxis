import 'package:equatable/equatable.dart';

/// Represents an authenticated Firebase / identity user.
class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  @override
  List<Object?> get props => [uid, phoneNumber, email, displayName, photoUrl];
}
