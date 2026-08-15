import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/data/repositories/access_repository_impl.dart';
import 'package:workaxis/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:workaxis/features/authentication/data/repositories/auth_repository_impl.dart';

void main() {
  late InMemoryAuthDataSource authDataSource;
  late AuthRepositoryImpl authRepository;
  late InMemoryAccessDataSource accessDataSource;
  late AccessRepositoryImpl accessRepository;

  setUp(() {
    authDataSource = InMemoryAuthDataSource();
    authRepository = AuthRepositoryImpl(remoteDataSource: authDataSource);
    accessDataSource = InMemoryAccessDataSource();
    accessRepository = AccessRepositoryImpl(remoteDataSource: accessDataSource);
  });

  Widget createTestWidget() {
    return WorkAxisApp(
      authRepository: authRepository,
      accessRepository: accessRepository,
    );
  }

  group('WorkAxis Responsive Authentication & Flow Widget Tests', () {
    testWidgets('renders Welcome page on phone portrait (360x800)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WorkAxis'), findsOneWidget);
      expect(find.text('Sign in with Phone'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets(
        'renders Welcome page on tablet landscape (1280x800) with split branding panel',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Streamlined Workforce Management for Multi-Branch Operations'),
        findsOneWidget,
      );
      expect(find.text('Sign in with Phone Number'), findsOneWidget);
    });

    testWidgets(
        'navigates from Welcome to Phone Entry and requests OTP via SMS',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Sign in with Phone
      await tester.tap(find.text('Sign in with Phone'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in with phone number'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);

      // Enter phone number
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, '5551234567');
      await tester.pumpAndSettle();

      // Tap Send OTP via SMS
      await tester.tap(find.widgetWithText(AppButton, 'Send OTP via SMS'));
      await tester.pumpAndSettle();

      // Should transition to OTP verification
      expect(find.text('Enter 6-digit code'), findsOneWidget);
      expect(find.textContaining('+1 (***) ***-4567'), findsOneWidget);
      expect(find.textContaining('via SMS'), findsOneWidget);
    });

    testWidgets('selects WhatsApp channel and sends OTP via WhatsApp',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to Phone Entry
      await tester.tap(find.text('Sign in with Phone'));
      await tester.pumpAndSettle();

      // Tap WhatsApp segment
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Send OTP via WhatsApp'),
          findsOneWidget);

      await tester.enterText(find.byType(TextField), '5551234567');
      await tester.tap(find.widgetWithText(AppButton, 'Send OTP via WhatsApp'));
      await tester.pumpAndSettle();

      expect(find.textContaining('+1 (***) ***-4567'), findsOneWidget);
      expect(find.textContaining('via WhatsApp'), findsOneWidget);
      expect(find.text('Send via SMS instead'), findsOneWidget);
    });

    testWidgets('opens country code picker and selects country',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to Phone Entry
      await tester.tap(find.text('Sign in with Phone'));
      await tester.pumpAndSettle();

      // Default country code is +1
      expect(find.text('+1'), findsOneWidget);

      // Tap on the country code picker
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      // Verify bottom sheet opened
      expect(find.text('Select Country / Region'), findsOneWidget);
      expect(find.text('United Kingdom'), findsOneWidget);

      // Select United Kingdom
      await tester.tap(find.text('United Kingdom'));
      await tester.pumpAndSettle();

      // Verify selected country dial code is now +44
      expect(find.text('+44'), findsOneWidget);
    });

    testWidgets(
        'completes OTP verification and lands on Organization Selection for multi-org user',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to Phone Entry
      await tester.tap(find.text('Sign in with Phone'));
      await tester.pumpAndSettle();

      // Enter Alex Morgan phone number (+15551234567)
      await tester.enterText(find.byType(TextField), '5551234567');
      await tester.tap(find.widgetWithText(AppButton, 'Send OTP via SMS'));
      await tester.pumpAndSettle();

      // Enter 6 digit OTP: 123456
      final otpFields = find.byType(TextField);
      expect(otpFields, findsNWidgets(6));

      for (var i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), '${i + 1}');
      }
      await tester.pumpAndSettle();

      // Auto-submit navigates to verifying access then lands on Organization Selection
      expect(find.text('Select Organization'), findsOneWidget);
      expect(find.text('Central Valley Produce'), findsOneWidget);
      expect(find.text('GreenHarvest Distribution'), findsOneWidget);
    });
  });
}
