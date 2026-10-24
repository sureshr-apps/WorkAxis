import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_container.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/authentication/presentation/screens/widgets/sign_in_header.dart';
import 'package:workaxis/features/authentication/presentation/screens/widgets/sign_in_hero_panel.dart';

/// Sign-In screen matching the approved Operations Enterprise M3 design.
/// On desktop (>= 840dp), features an executive two-panel layout with
/// the [SignInHeroPanel] showcasing brand topology on the left.
/// On tablet and smartphone, renders a clean, focused, elevated authentication card.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() => _validationError = null);

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _validationError = 'Please enter both your identifier and password.';
      });
      return;
    }

    final authController = context.read<AuthController>();
    final success = await authController.signIn(
      identifier: identifier,
      password: password,
    );

    if (success && mounted) {
      context.go(AppRoutes.verifyAccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isDesktop = context.isExpanded;
    final isCompact = context.isCompact;

    final formCard = _buildFormCard(context, authController, isDesktop);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Row(
          children: [
            // Left: Enterprise Brand & Telemetry Showcase
            const Expanded(
              flex: 5,
              child: SignInHeroPanel(),
            ),

            // Right: Authentication Workspace
            Expanded(
              flex: 6,
              child: Container(
                color: const Color(0xFFF9FAFD),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: AppSpacing.xxl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: formCard,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Smartphone & Tablet Layout
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEF3FB),
              Color(0xFFF8F9FC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? AppSpacing.lg : AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              child: isCompact
                  ? formCard
                  : ResponsiveContainer(
                      maxWidth: AppBreakpoints.maxFormCardWidth,
                      child: formCard,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    AuthController authController,
    bool isDesktop,
  ) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SignInHeader(),
        const SizedBox(height: AppSpacing.xl),

        // Error banners (validation error or backend failure)
        if (_validationError != null) ...[
          ErrorBanner(
            message: _validationError!,
            onDismiss: () => setState(() => _validationError = null),
          ),
          const SizedBox(height: AppSpacing.md),
        ] else if (authController.errorMessage != null) ...[
          ErrorBanner(
            message: authController.errorMessage!,
            onDismiss: authController.clearError,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Identifier input
        AppTextField(
          controller: _identifierController,
          label: 'Username, email, or phone number',
          hintText: 'e.g. j.doe or +1 (555) 000-0000',
          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
          textInputAction: TextInputAction.next,
          enabled: !authController.isLoading,
          onSubmitted: (_) => _handleSignIn(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Password input using canonical template
        AppPasswordField(
          controller: _passwordController,
          enabled: !authController.isLoading,
          onSubmitted: (_) => _handleSignIn(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Submit button
        AppButton.primary(
          text: 'Sign In',
          isLoading: authController.isLoading,
          onPressed: _handleSignIn,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Supporting administrator note
        Center(
          child: Text(
            'Forgot your password? Contact your administrator.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Quick Demo Accounts Fill for ease of role inspection
        _buildDemoAccountsQuickFill(),

        const SizedBox(height: AppSpacing.lg),

        // Security Footnote
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 13,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 5),
            Text(
              'End-to-end encrypted session',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outlineSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0D2659),
            offset: Offset(0, 10),
            blurRadius: 28,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: content,
    );
  }

  Widget _buildDemoAccountsQuickFill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'QUICK-FILL TEST ACCOUNTS',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildDemoChip('Platform Owner', 'owner', 'Password123!'),
              _buildDemoChip('Org Admin', 'orgadmin', 'Password123!'),
              _buildDemoChip('Branch Mgr', 'manager_multi', 'Password123!'),
              _buildDemoChip('Employee', 'employee', 'Password123!'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoChip(String roleLabel, String username, String password) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _identifierController.text = username;
            _passwordController.text = password;
            _validationError = null;
          });
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roleLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
