import 'package:flutter/material.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/data/repositories/access_repository_impl.dart';
import 'package:workaxis/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:workaxis/features/authentication/data/repositories/auth_repository_impl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authDataSource = InMemoryAuthDataSource();
  final authRepository = AuthRepositoryImpl(remoteDataSource: authDataSource);

  final accessDataSource = InMemoryAccessDataSource();
  final accessRepository =
      AccessRepositoryImpl(remoteDataSource: accessDataSource);

  runApp(
    WorkAxisApp(
      authRepository: authRepository,
      accessRepository: accessRepository,
    ),
  );
}
