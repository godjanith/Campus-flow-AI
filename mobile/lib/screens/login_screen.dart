import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  bool _isLoading = false;
  bool _isRegister = false;
  bool _obscurePassword = true;
  String? _error;
  String? _infoBanner;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'student@presidencyuniversity.in';
    _passController.text = 'student123';
  }

  void _fillStudentDemo() {
    HapticFeedback.selectionClick();
    setState(() {
      _isRegister = false;
      _emailController.text = 'student@presidencyuniversity.in';
      _passController.text = 'student123';
      _nameController.text = 'Campus Operations Member';
      _regNoController.text = 'PU-STUDENT';
      _error = null;
      _infoBanner = 'Student credentials loaded. Tap Sign In or Instant Access.';
    });
  }

  void _fillAdminDemo() {
    HapticFeedback.selectionClick();
    setState(() {
      _isRegister = false;
      _emailController.text = 'admin@presidencyuniversity.in';
      _passController.text = 'adminpassword123';
      _error = null;
      _infoBanner = 'Facility Administrator credentials loaded.';
    });
  }

  Future<void> _proceedToApp(Map<String, dynamic> userData) async {
    final provider = context.read<AppProvider>();
    await provider.setUser(userData);
    await provider.loadTickets();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _loginInstantDemo() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Campus Operations Member';
      final email = _emailController.text.trim().isNotEmpty && _emailController.text.contains('@')
          ? _emailController.text.trim()
          : 'student@presidencyuniversity.in';
      final regNo = _regNoController.text.trim().isNotEmpty
          ? _regNoController.text.trim()
          : 'PU-STUDENT';

      final userData = await ApiService.demoLogin(
        name: name,
        email: email,
        regNo: regNo,
      );
      await _proceedToApp(userData);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    var email = _emailController.text.trim();
    final pass = _passController.text;
    final name = _nameController.text.trim();
    final regNo = _regNoController.text.trim();

    // Auto-fix missing '@' if user typed domain directly
    if (email.isNotEmpty && !email.contains('@')) {
      if (email.contains('.')) {
        final dotIdx = email.indexOf('.');
        final prefix = dotIdx > 5 ? email.substring(0, 5) : email.substring(0, dotIdx);
        final rest = dotIdx > 5 ? email.substring(5) : email.substring(dotIdx);
        email = '$prefix@$rest';
        _emailController.text = email;
      } else {
        email = '$email@presidencyuniversity.in';
        _emailController.text = email;
      }
    }

    // Validation
    if (_isRegister && name.isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Please enter a valid email (e.g. name@presidencyuniversity.in)');
      return;
    }

    if (pass.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }

    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters long');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _infoBanner = null;
    });

    try {
      Map<String, dynamic> userData;
      if (_isRegister) {
        userData = await ApiService.register(
          name: name,
          email: email,
          password: pass,
          regNo: regNo.isNotEmpty ? regNo : '20252MCA0318',
        );
      } else {
        userData = await ApiService.login(email, pass);
      }
      await _proceedToApp(userData);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      // If network/server unreachable, offer auto-login fallback so user is NEVER blocked!
      if (msg.contains('Server unreachable') ||
          msg.contains('Connection refused') ||
          msg.contains('Network connection error') ||
          msg.contains('SocketException') ||
          msg.contains('ClientException')) {
        setState(() {
          _infoBanner = 'Backend offline. Launching resilient local session...';
        });
        await Future.delayed(const Duration(milliseconds: 700));
        final fallbackUser = await ApiService.demoLogin(
          name: name.isNotEmpty ? name : 'Campus Operations Member',
          email: email,
          regNo: regNo.isNotEmpty ? regNo : 'PU-CAMPUS-OPS',
        );
        await _proceedToApp(fallbackUser);
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crispIvory,
      body: Column(
        children: [
          // ── Official Royal Navy Header Banner with Gold Trim ────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primaryRoyalNavy,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.secondaryRoyalGold,
                  width: 3.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A0F294A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.purePorcelain.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.secondaryRoyalGold.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: AppTheme.secondaryRoyalGold,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CampusFlow AI',
                        style: GoogleFonts.merriweather(
                          color: AppTheme.purePorcelain,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Presidency University Official Portal',
                        style: GoogleFonts.inter(
                          color: AppTheme.secondaryRoyalGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.purePorcelain.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.secondaryRoyalGold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'v2.4 Pro',
                        style: GoogleFonts.inter(
                          color: AppTheme.purePorcelain,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Body Content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Institutional Emblem Badge
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppTheme.purePorcelain,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.secondaryRoyalGold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.school_rounded,
                            size: 36,
                            color: AppTheme.primaryRoyalNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'FACILITY & SAFETY DESK',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppTheme.secondaryRoyalGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRegister ? 'Student Registration' : 'Institutional Sign In',
                        style: GoogleFonts.merriweather(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Authorized access for students, staff, and facility dispatchers',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pure Porcelain Card Surface
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.purePorcelain,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Segment Switcher (Sign In vs Register)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _isRegister = false;
                                        _error = null;
                                      }),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: !_isRegister ? AppTheme.purePorcelain : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: !_isRegister
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.08),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Portal Sign In',
                                          style: GoogleFonts.inter(
                                            fontWeight: !_isRegister ? FontWeight.w700 : FontWeight.w500,
                                            color: !_isRegister ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _isRegister = true;
                                        _error = null;
                                      }),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _isRegister ? AppTheme.purePorcelain : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: _isRegister
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.08),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'New Registration',
                                          style: GoogleFonts.inter(
                                            fontWeight: _isRegister ? FontWeight.w700 : FontWeight.w500,
                                            color: _isRegister ? AppTheme.primaryRoyalNavy : AppTheme.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Info / Status Banner
                            if (_infoBanner != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.mediumBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.mediumText.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: AppTheme.mediumText, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _infoBanner!,
                                        style: GoogleFonts.inter(
                                          color: AppTheme.mediumText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Error Banner
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.criticalBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.criticalText.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(Icons.error_outline_rounded, color: AppTheme.criticalText, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: GoogleFonts.inter(
                                          color: AppTheme.criticalText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Register Fields
                            if (_isRegister) ...[
                              TextField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'Full Legal Name *',
                                  hintText: 'e.g. Student / Member Name',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryRoyalNavy),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _regNoController,
                                textCapitalization: TextCapitalization.characters,
                                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'Student Registration Number *',
                                  hintText: 'e.g. 20252MCA0101',
                                  prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primaryRoyalNavy),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Email Field
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Institutional Email Address *',
                                hintText: 'student@presidencyuniversity.in',
                                prefixIcon: Icon(Icons.mail_outline_rounded, color: AppTheme.primaryRoyalNavy),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Password Field
                            TextField(
                              controller: _passController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                hintText: 'Minimum 6 characters',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryRoyalNavy),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRoyalNavy,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                    )
                                  : Text(
                                      _isRegister ? 'Register Institutional Account' : 'Authenticate & Enter',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.purePorcelain,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 14),

                            // Instant Demo Access Button
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _loginInstantDemo,
                              icon: const Icon(Icons.flash_on_rounded, size: 18, color: AppTheme.secondaryRoyalGold),
                              label: Text(
                                'Instant Demo Access (Offline Resilient)',
                                style: GoogleFonts.inter(
                                  color: AppTheme.primaryRoyalNavy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.cardBorder, width: 1.2),
                                backgroundColor: AppTheme.surfaceLight,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Quick Fill Autofill Chips
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AppTheme.cardBorder)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'OFFICIAL DEMO PRESETS',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: AppTheme.cardBorder)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _fillStudentDemo,
                                    icon: const Icon(Icons.school_outlined, size: 16, color: AppTheme.primaryRoyalNavy),
                                    label: Text(
                                      'Student Demo',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      backgroundColor: AppTheme.purePorcelain,
                                      side: const BorderSide(color: AppTheme.cardBorder),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _fillAdminDemo,
                                    icon: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppTheme.secondaryRoyalGold),
                                    label: Text(
                                      'Admin Demo',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      backgroundColor: AppTheme.purePorcelain,
                                      side: const BorderSide(color: AppTheme.cardBorder),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer Security & Accreditation Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.security_rounded, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Presidency University Infrastructure & Facilities Desk',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Secured via Mernova Multi-Agent AI Core',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
