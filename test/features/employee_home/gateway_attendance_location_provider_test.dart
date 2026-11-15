import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/employee_home/domain/models/device_location.dart';
import 'package:workaxis/features/employee_home/domain/models/location_peek.dart';
import 'package:workaxis/features/employee_home/domain/services/device_location_gateway.dart';
import 'package:workaxis/features/employee_home/domain/services/gateway_attendance_location_provider.dart';

class _FakeGateway implements DeviceLocationGateway {
  bool serviceEnabled = true;
  LocationPermissionState current = LocationPermissionState.granted;
  LocationPermissionState afterRequest = LocationPermissionState.granted;
  Object? fixError;
  int requests = 0;
  Duration? lastTimeout;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionState> checkPermission() async => current;

  @override
  Future<LocationPermissionState> requestPermission() async {
    requests++;
    return afterRequest;
  }

  @override
  Future<DeviceLocation> currentFix({required Duration timeout}) async {
    lastTimeout = timeout;
    final error = fixError;
    if (error != null) throw error;
    return const DeviceLocation(
      latitude: 12.97,
      longitude: 77.59,
      accuracyMeters: 8.5,
    );
  }
}

Future<LocationFailure> _failure(GatewayAttendanceLocationProvider p) async {
  try {
    await p.currentLocation();
  } on LocationException catch (e) {
    expect(e.userMessage, isNotEmpty);
    return e.failure;
  }
  fail('expected a LocationException');
}

void main() {
  late _FakeGateway gateway;
  late GatewayAttendanceLocationProvider provider;
  setUp(() {
    gateway = _FakeGateway();
    provider = GatewayAttendanceLocationProvider(
      gateway,
      timeout: const Duration(seconds: 3),
    );
  });

  test(
    'returns the fix with its accuracy when permission is granted',
    () async {
      final fix = await provider.currentLocation();
      expect(fix.latitude, 12.97);
      expect(fix.accuracyMeters, 8.5);
      expect(gateway.requests, 0);
      expect(gateway.lastTimeout, const Duration(seconds: 3));
    },
  );

  group('peekLocation never prompts', () {
    test('reports permissionNeeded without requesting', () async {
      gateway.current = LocationPermissionState.denied;
      final peek = await provider.peekLocation();
      expect(peek.readiness, LocationReadiness.permissionNeeded);
      expect(peek.fix, isNull);
      expect(gateway.requests, 0);
    });

    test('reports permissionBlocked and serviceDisabled', () async {
      gateway.current = LocationPermissionState.deniedForever;
      expect(
        (await provider.peekLocation()).readiness,
        LocationReadiness.permissionBlocked,
      );
      gateway.serviceEnabled = false;
      expect(
        (await provider.peekLocation()).readiness,
        LocationReadiness.serviceDisabled,
      );
      expect(gateway.requests, 0);
    });

    test('returns the fix when already granted', () async {
      final peek = await provider.peekLocation();
      expect(peek.readiness, LocationReadiness.ready);
      expect(peek.fix?.latitude, 12.97);
    });

    test('a failing fix is unavailable, not an exception', () async {
      gateway.fixError = TimeoutException('slow');
      expect(
        (await provider.peekLocation()).readiness,
        LocationReadiness.unavailable,
      );
    });
  });

  test('requests permission once when denied, then proceeds', () async {
    gateway.current = LocationPermissionState.denied;
    await provider.currentLocation();
    expect(gateway.requests, 1);
  });

  test('a declined prompt is a permissionDenied failure', () async {
    gateway.current = LocationPermissionState.denied;
    gateway.afterRequest = LocationPermissionState.denied;
    expect(await _failure(provider), LocationFailure.permissionDenied);
  });

  test('blocked permission is not re-requested', () async {
    gateway.current = LocationPermissionState.deniedForever;
    expect(await _failure(provider), LocationFailure.permissionDeniedForever);
    expect(gateway.requests, 0);
  });

  test('permission blocked by the prompt result is deniedForever', () async {
    gateway.current = LocationPermissionState.denied;
    gateway.afterRequest = LocationPermissionState.deniedForever;
    expect(await _failure(provider), LocationFailure.permissionDeniedForever);
  });

  test('location services off is reported before asking permission', () async {
    gateway.serviceEnabled = false;
    gateway.current = LocationPermissionState.denied;
    expect(await _failure(provider), LocationFailure.serviceDisabled);
    expect(gateway.requests, 0);
  });

  test('timeouts map to a timeout failure', () async {
    gateway.fixError = TimeoutException('slow');
    expect(await _failure(provider), LocationFailure.timeout);
  });

  test('unexpected plugin errors never leak their details', () async {
    gateway.fixError = StateError('secret platform detail');
    try {
      await provider.currentLocation();
      fail('expected failure');
    } on LocationException catch (e) {
      expect(e.failure, LocationFailure.unavailable);
      expect(e.userMessage, isNot(contains('secret')));
    }
  });
}
