import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

// ─── Zone A: Onboarding & Authentication Screens (6 Views) ───

class SplashOnboardingScreen extends StatelessWidget {
  const SplashOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.gainGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gainGreen.withOpacity(0.2), width: 2),
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: AppColors.gainGreen,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'TradeMentor',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Indian Real-Time Stock Monitoring & Rule-Based AI Trading Assistant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security, color: AppColors.gainGreen, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Practice paper trading with zero risk and access AI advisory models offline.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        final provider = Provider.of<MarketProvider>(context, listen: false);
                        provider.setScreen('LOGIN');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gainGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final provider = Provider.of<MarketProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password'), backgroundColor: AppColors.lossRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    final error = await provider.login(email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      provider.setScreen('RISK_QUIZ');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.lossRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => provider.setScreen('SPLASH'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.textPrimary),
                    onPressed: () => showServerConfigDialog(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome Back',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to access real-time NSE stock simulation and rule execution.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => provider.setScreen('FORGOT'),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.gainGreen),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gainGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    final err = await provider.googleLogin();
                    if (!context.mounted) return;
                    setState(() => _isLoading = false);
                    if (err == null) {
                      provider.setScreen('RISK_QUIZ');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.lossRed));
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                  label: const Text('Continue with Google', style: TextStyle(color: Colors.white, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton.icon(
                  onPressed: () {
                    provider.setLoggedIn(true);
                    provider.setScreen('RISK_QUIZ');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged in via Offline Demo Mode (Mock Database)'),
                        backgroundColor: Colors.blueAccent,
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_off, color: AppColors.gainGreen),
                  label: const Text(
                    'Use Offline Demo Mode (No Server Required)',
                    style: TextStyle(color: AppColors.gainGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => provider.setScreen('REGISTER'),
                    child: const Text(
                      'Register Now',
                      style: TextStyle(color: AppColors.gainGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleRegister() async {
    final provider = Provider.of<MarketProvider>(context, listen: false);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.lossRed),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: AppColors.lossRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    final error = await provider.register(name, email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      provider.setScreen('RISK_QUIZ');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.lossRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => provider.setScreen('LOGIN'),
              ),
              const SizedBox(height: 20),
              Text(
                'Create Account',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join TradeMentor to create custom alert triggers and paper trade.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password (min. 6 characters)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gainGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    final err = await provider.googleLogin();
                    if (!context.mounted) return;
                    setState(() => _isLoading = false);
                    if (err == null) {
                      provider.setScreen('RISK_QUIZ');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.lossRed, duration: const Duration(seconds: 5)));
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                  label: const Text('Continue with Google', style: TextStyle(color: Colors.white, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => provider.setScreen('LOGIN'),
                    child: const Text(
                      'Log In',
                      style: TextStyle(color: AppColors.gainGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  void _handleSendOtp() {
    final provider = Provider.of<MarketProvider>(context, listen: false);
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email'), backgroundColor: AppColors.lossRed),
      );
      return;
    }
    // Simulate OTP
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread, color: AppColors.gainGreen),
            SizedBox(width: 8),
            Text('Simulated SMS/Email'),
          ],
        ),
        content: const Text(
          'Your simulated password reset verification OTP is: \n\n'
          '🔑 4821\n\n'
          'Use this code on the next page to reset password.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.setScreen('RESET');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gainGreen),
            child: const Text('Enter Code', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => provider.setScreen('LOGIN'),
              ),
              const SizedBox(height: 20),
              Text(
                'Forgot Password',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Provide your email address to receive a simulated 4-digit verification code.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gainGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Send OTP Verification',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleReset() {
    final provider = Provider.of<MarketProvider>(context, listen: false);
    if (_otpController.text.trim() != '4821') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP code. Try "4821".'), backgroundColor: AppColors.lossRed),
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password'), backgroundColor: AppColors.lossRed),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.gainGreen),
    );
    provider.setScreen('LOGIN');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () {
                  final provider = Provider.of<MarketProvider>(context, listen: false);
                  provider.setScreen('FORGOT');
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Reset Password',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the 4-digit code (4821) and your new credentials to update password.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification OTP (4-digit)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gainGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirm Reset Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RiskQuizScreen extends StatefulWidget {
  const RiskQuizScreen({super.key});

  @override
  State<RiskQuizScreen> createState() => _RiskQuizScreenState();
}

class _RiskQuizScreenState extends State<RiskQuizScreen> {
  int _q1Selected = -1; // 0, 1, 2
  int _q2Selected = -1; // 0, 1, 2
  int _q3Selected = -1; // 0, 1, 2

  final List<String> _q1Options = [
    'Preserve Capital & Earn Fixed Returns',
    'Balance Capital Growth with Income Stability',
    'Maximize Long-Term Gains Aggressively'
  ];

  final List<String> _q2Options = [
    'Panic and liquidate all simulated holdings immediately',
    'Hold positions and wait for recovery',
    'View it as a discount and buy the dip'
  ];

  final List<String> _q3Options = [
    'Short term (< 1 Year)',
    'Medium term (1-5 Years)',
    'Long term (5+ Years)'
  ];

  void _calculateRiskAndFinish() {
    if (_q1Selected == -1 || _q2Selected == -1 || _q3Selected == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all 3 questions to evaluate your profile'), backgroundColor: AppColors.lossRed),
      );
      return;
    }

    // Simple heuristic calculation
    final score = _q1Selected + _q2Selected + _q3Selected;
    String profile = 'moderate';
    if (score <= 2) {
      profile = 'low'; // Conservative
    } else if (score >= 5) {
      profile = 'high'; // Aggressive
    }

    final provider = Provider.of<MarketProvider>(context, listen: false);
    provider.setRiskProfile(profile);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppColors.gainGreen),
            SizedBox(width: 8),
            Text('Quiz Completed!'),
          ],
        ),
        content: Text(
          'TradeMentor AI has calculated your risk profile:\n\n'
          '📊 **${profile.toUpperCase()} RISK TOLERANCE**\n\n'
          'The AI Trading Assistant will default its stock allocation models and technical scanner suggestions based on this profile.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.setScreen('DASHBOARD');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gainGreen),
            child: const Text('Enter Platform', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Onboarding Quiz',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Answer these 3 simple questions so TradeMentor AI can optimize your risk model.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildQuestionCard(
                      number: 'Q1',
                      title: 'What is your primary investment goal?',
                      options: _q1Options,
                      selectedIndex: _q1Selected,
                      onSelect: (val) => setState(() => _q1Selected = val),
                    ),
                    const SizedBox(height: 18),
                    _buildQuestionCard(
                      number: 'Q2',
                      title: 'How do you react if your portfolio drops by 15%?',
                      options: _q2Options,
                      selectedIndex: _q2Selected,
                      onSelect: (val) => setState(() => _q2Selected = val),
                    ),
                    const SizedBox(height: 18),
                    _buildQuestionCard(
                      number: 'Q3',
                      title: 'What is your planned investment horizon?',
                      options: _q3Options,
                      selectedIndex: _q3Selected,
                      onSelect: (val) => setState(() => _q3Selected = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _calculateRiskAndFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gainGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Analyze My Risk Profile',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required String number,
    required String title,
    required List<String> options,
    required int selectedIndex,
    required Function(int) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gainGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gainGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: List.generate(
              options.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedIndex == index
                            ? AppColors.gainGreen
                            : Colors.white.withOpacity(0.08),
                      ),
                      color: selectedIndex == index
                          ? AppColors.gainGreen.withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedIndex == index
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selectedIndex == index
                              ? AppColors.gainGreen
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            options[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedIndex == index
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
