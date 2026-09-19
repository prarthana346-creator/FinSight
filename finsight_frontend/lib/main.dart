import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(const FinSightApp());
}

// ============================================================
// FINSIGHT APP
// ============================================================

class FinSightApp extends StatelessWidget {
  const FinSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinSight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const SessionGate(),
    );
  }
}

// ============================================================
// SESSION GATE
// ============================================================

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('logged_in_user_id') ?? '';
    final userName = prefs.getString('logged_in_user_name') ?? 'User';

    if (!mounted) return;

    if (userId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinSightDashboard(
            userName: userName,
            userId: userId,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ============================================================
// AUTHENTICATION SCREEN
// ============================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = true;
  bool obscurePassword = true;
  bool isLoading = false;
  bool savePassword = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final String baseUrl = 'http://localhost:5000/api/auth';

  void clearFields() {
    nameController.clear();
    emailController.clear();
    mobileController.clear();
    passwordController.clear();
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');

    if (!mounted) return;

    if (savedEmail != null && savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
    }

    if (savedPassword != null && savedPassword.isNotEmpty) {
      passwordController.text = savedPassword;
      setState(() {
        savePassword = true;
      });
    }
  }

  Future<void> registerUser() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('Please fill all fields', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'mobile': mobileController.text.trim(),
          'password': passwordController.text,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        showMessage(
          data['message']?.toString() ?? 'Registration successful!',
        );
        clearFields();
        setState(() => isSignIn = true);
      } else {
        showMessage(
          data['message']?.toString() ?? 'Registration failed',
          isError: true,
        );
      }
    } catch (_) {
      showMessage(
        'Unable to connect to the backend server.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage(
        'Please enter email and password',
        isError: true,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = data['user'];
        String userName = 'User';
        String userId = '';

        if (user is Map<String, dynamic>) {
          userName = user['name']?.toString() ?? 'User';
          userId = user['_id']?.toString() ??
              user['id']?.toString() ??
              '';
        }

        if (userId.isEmpty) {
          showMessage(
            'User ID was not returned by the server.',
            isError: true,
          );
          return;
        }

        final prefs = await SharedPreferences.getInstance();

        // Keep the user logged in after an app/browser refresh.
        await prefs.setString('logged_in_user_id', userId);
        await prefs.setString('logged_in_user_name', userName);

        if (savePassword) {
          await prefs.setString(
            'saved_email',
            emailController.text.trim(),
          );
          await prefs.setString(
            'saved_password',
            passwordController.text,
          );
        } else {
          await prefs.remove('saved_email');
          await prefs.remove('saved_password');
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FinSightDashboard(
              userName: userName,
              userId: userId,
            ),
          ),
        );
      } else {
        showMessage(
          data['message']?.toString() ?? 'Login failed',
          isError: true,
        );
      }
    } catch (_) {
      showMessage(
        'Unable to connect to the backend server.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void submit() {
    if (isSignIn) {
      loginUser();
    } else {
      registerUser();
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadSavedLogin();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/finsight_logo.png',
              height: 40,
              width: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_balance_wallet, size: 35),
            ),
            const SizedBox(width: 10),
            const Text(
              'FinSight',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 65,
                ),
                const SizedBox(height: 15),
                Text(
                  isSignIn ? 'Welcome Back!' : 'Create Your Account',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => isSignIn = true);
                          clearFields();
                        },
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => isSignIn = false);
                          clearFields();
                        },
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                if (!isSignIn) ...[
                  TextField(
                    controller: nameController,
                    decoration: inputDecoration(
                      'Full Name',
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration(
                    'Email Address',
                    Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                if (!isSignIn) ...[
                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: inputDecoration(
                      'Mobile Number',
                      Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: inputDecoration(
                    'Password',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                if (isSignIn)
                  Row(
                    children: [
                      Checkbox(
                        value: savePassword,
                        onChanged: (value) {
                          setState(() {
                            savePassword = value ?? false;
                          });
                        },
                      ),
                      const Text('Save password'),
                    ],
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(isSignIn ? 'Sign In' : 'Register'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: clearFields,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() => isSignIn = !isSignIn);
                    clearFields();
                  },
                  child: Text(
                    isSignIn
                        ? "Don't have an account? Sign Up"
                        : 'Already have an account? Sign In',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class FinancialData {
  final String portfolioCategory;
  final String type;
  final String name;
  final double amount;
  final String notes;

  // Financial Goal fields.
  final double currentSavings;
  final String targetDate;
  final double monthlyContribution;
  final String status;

  FinancialData({
    required this.portfolioCategory,
    required this.type,
    required this.name,
    required this.amount,
    this.notes = '',
    this.currentSavings = 0.0,
    this.targetDate = '',
    this.monthlyContribution = 0.0,
    this.status = 'To Do',
  });

  bool get isFinancialGoal =>
      type.trim().toLowerCase() == 'financial goal';

  double get goalProgress {
    if (!isFinancialGoal || amount <= 0) return 0.0;

    final progress = currentSavings / amount;

    if (progress < 0) return 0.0;
    if (progress > 1) return 1.0;

    return progress;
  }

  double get goalPercentage => goalProgress * 100;

  double get remainingAmount {
    final remaining = amount - currentSavings;
    return remaining < 0 ? 0.0 : remaining;
  }
}

class GoldRecord {
  final DateTime date;
  final double pricePerGram;
  final double grams;
  final double amountInvested;

  GoldRecord({
    required this.date,
    required this.pricePerGram,
    required this.grams,
    required this.amountInvested,
  });

  double get currentValue => grams * pricePerGram;
}

class DepositRecord {
  final String type;
  final String bank;
  final String accountNumber;
  final double principal;
  final double monthlyDeposit;
  final double interestRate;
  final String startDate;
  final String maturityDate;
  final double maturityAmount;

  DepositRecord({
    required this.type,
    required this.bank,
    required this.accountNumber,
    required this.principal,
    required this.monthlyDeposit,
    required this.interestRate,
    required this.startDate,
    required this.maturityDate,
    required this.maturityAmount,
  });

  double get portfolioValue =>
      maturityAmount > 0 ? maturityAmount : principal;
}

class InsuranceRecord {
  final String company;
  final String policyNumber;
  final String policyType;
  final double premium;
  final String frequency;
  final String startDate;
  final String maturityDate;
  final double sumAssured;

  InsuranceRecord({
    required this.company,
    required this.policyNumber,
    required this.policyType,
    required this.premium,
    required this.frequency,
    required this.startDate,
    required this.maturityDate,
    required this.sumAssured,
  });
}

class FutureGoalNote {
  final String title;
  final String note;
  final DateTime createdAt;

  FutureGoalNote({
    required this.title,
    required this.note,
    required this.createdAt,
  });
}

// ============================================================
// DASHBOARD
// ============================================================

class FinSightDashboard extends StatefulWidget {
  final String userName;
  final String userId;

  const FinSightDashboard({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<FinSightDashboard> createState() => _FinSightDashboardState();
}

class _FinSightDashboardState extends State<FinSightDashboard> {
  final List<FinancialData> investments = [];
  final List<GoldRecord> goldRecords = [];
  final List<DepositRecord> deposits = [];
  final List<InsuranceRecord> insurancePolicies = [];
  final List<FutureGoalNote> futureGoalNotes = [];

  bool isPortfolioLoading = true;
  bool isPortfolioSaving = false;

  final String portfolioBaseUrl =
      'http://localhost:5000/api/portfolio';

  @override
  void initState() {
    super.initState();
    loadPortfolio();
  }

  Future<void> loadPortfolio() async {
    try {
      final response = await http.get(
        Uri.parse('$portfolioBaseUrl/${widget.userId}'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load portfolio');
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final portfolio = data['portfolio'];

      if (portfolio is! Map<String, dynamic>) {
        if (mounted) {
          setState(() => isPortfolioLoading = false);
        }
        return;
      }

      final List<FinancialData> loadedInvestments = [];
      final investmentData = portfolio['investments'];

      if (investmentData is List) {
        for (final item in investmentData) {
          if (item is Map<String, dynamic>) {
            loadedInvestments.add(
              FinancialData(
                portfolioCategory:
                    item['portfolioCategory']?.toString() ?? 'General',
                type: item['type']?.toString() ?? 'Other',
                name: item['name']?.toString() ?? '',
                amount: _toDouble(item['amount']),
                notes: item['notes']?.toString() ?? '',
                currentSavings: _toDouble(item['currentSavings']),
                targetDate: item['targetDate']?.toString() ?? '',
                monthlyContribution:
                    _toDouble(item['monthlyContribution']),
                status: item['status']?.toString() ?? 'To Do',
              ),
            );
          }
        }
      }

      final List<GoldRecord> loadedGold = [];
      final goldData = portfolio['goldRecords'];

      if (goldData is List) {
        for (final item in goldData) {
          if (item is Map<String, dynamic>) {
            loadedGold.add(
              GoldRecord(
                date: DateTime.tryParse(
                      item['date']?.toString() ?? '',
                    ) ??
                    DateTime.now(),
                pricePerGram: _toDouble(item['pricePerGram']),
                grams: _toDouble(item['grams']),
                amountInvested: _toDouble(item['amountInvested']),
              ),
            );
          }
        }
      }

      final List<DepositRecord> loadedDeposits = [];
      final depositData = portfolio['deposits'];

      if (depositData is List) {
        for (final item in depositData) {
          if (item is Map<String, dynamic>) {
            loadedDeposits.add(
              DepositRecord(
                type: item['type']?.toString() ?? '',
                bank: item['bank']?.toString() ?? '',
                accountNumber:
                    item['accountNumber']?.toString() ?? '',
                principal: _toDouble(item['principal']),
                monthlyDeposit: _toDouble(item['monthlyDeposit']),
                interestRate: _toDouble(item['interestRate']),
                startDate: item['startDate']?.toString() ?? '',
                maturityDate: item['maturityDate']?.toString() ?? '',
                maturityAmount: _toDouble(item['maturityAmount']),
              ),
            );
          }
        }
      }

      final List<InsuranceRecord> loadedInsurance = [];
      final insuranceData = portfolio['insurancePolicies'];

      if (insuranceData is List) {
        for (final item in insuranceData) {
          if (item is Map<String, dynamic>) {
            loadedInsurance.add(
              InsuranceRecord(
                company: item['company']?.toString() ?? '',
                policyNumber: item['policyNumber']?.toString() ?? '',
                policyType: item['policyType']?.toString() ?? '',
                premium: _toDouble(item['premium']),
                frequency: item['frequency']?.toString() ?? '',
                startDate: item['startDate']?.toString() ?? '',
                maturityDate: item['maturityDate']?.toString() ?? '',
                sumAssured: _toDouble(item['sumAssured']),
              ),
            );
          }
        }
      }

      final List<FutureGoalNote> loadedNotes = [];
      final notesData = portfolio['futureGoalNotes'];

      if (notesData is List) {
        for (final item in notesData) {
          if (item is Map<String, dynamic>) {
            loadedNotes.add(
              FutureGoalNote(
                title: item['title']?.toString() ?? '',
                note: item['note']?.toString() ?? '',
                createdAt: DateTime.tryParse(
                      item['createdAt']?.toString() ?? '',
                    ) ??
                    DateTime.now(),
              ),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        investments
          ..clear()
          ..addAll(loadedInvestments);
        goldRecords
          ..clear()
          ..addAll(loadedGold);
        deposits
          ..clear()
          ..addAll(loadedDeposits);
        insurancePolicies
          ..clear()
          ..addAll(loadedInsurance);
        futureGoalNotes
          ..clear()
          ..addAll(loadedNotes);
        isPortfolioLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => isPortfolioLoading = false);
      showMessage(
        'Could not load saved portfolio: $error',
        isError: true,
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> savePortfolio() async {
    if (isPortfolioSaving) return;

    setState(() => isPortfolioSaving = true);

    try {
      final body = {
        'investments': investments.map((item) => {
          'portfolioCategory': item.portfolioCategory,
          'type': item.type,
          'name': item.name,
          'amount': item.amount,
          'notes': item.notes,
          'currentSavings': item.currentSavings,
          'targetDate': item.targetDate,
          'monthlyContribution': item.monthlyContribution,
          'status': item.status,
        }).toList(),
        'goldRecords': goldRecords.map((item) => {
          'date': item.date.toIso8601String(),
          'pricePerGram': item.pricePerGram,
          'grams': item.grams,
          'amountInvested': item.amountInvested,
        }).toList(),
        'deposits': deposits.map((item) => {
          'type': item.type,
          'bank': item.bank,
          'accountNumber': item.accountNumber,
          'principal': item.principal,
          'monthlyDeposit': item.monthlyDeposit,
          'interestRate': item.interestRate,
          'startDate': item.startDate,
          'maturityDate': item.maturityDate,
          'maturityAmount': item.maturityAmount,
        }).toList(),
        'insurancePolicies': insurancePolicies.map((item) => {
          'company': item.company,
          'policyNumber': item.policyNumber,
          'policyType': item.policyType,
          'premium': item.premium,
          'frequency': item.frequency,
          'startDate': item.startDate,
          'maturityDate': item.maturityDate,
          'sumAssured': item.sumAssured,
        }).toList(),
        'futureGoalNotes': futureGoalNotes.map((item) => {
          'title': item.title,
          'note': item.note,
          'createdAt': item.createdAt.toIso8601String(),
        }).toList(),
      };

      final response = await http.put(
        Uri.parse('$portfolioBaseUrl/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        showMessage('Portfolio saved permanently!');
      } else {
        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}

        showMessage(
          data['message']?.toString() ?? 'Failed to save portfolio.',
          isError: true,
        );
      }
    } catch (error) {
      showMessage(
        'Could not save portfolio: $error',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isPortfolioSaving = false);
    }
  }

  // ---------------- TOTALS ----------------

  double get totalInvestment {
    // Financial Goal target amounts are goals, not existing investments.
    return investments
        .where((item) => !item.isFinancialGoal)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalGoldValue {
    return goldRecords.fold(
      0.0,
      (sum, item) => sum + item.currentValue,
    );
  }

  double get totalDeposits {
    return deposits.fold(
      0.0,
      (sum, item) => sum + item.portfolioValue,
    );
  }

  double get totalPortfolioValue =>
      totalInvestment + totalGoldValue + totalDeposits;

  // Insurance is shown separately as protection, not added to
  // the investment portfolio total.

  // ---------------- TYPE HELPERS ----------------

  String normalizeType(String type) {
    final value = type.trim().toLowerCase();

    if (value.contains('mutual') || value == 'mf') {
      return 'Mutual Fund';
    }
    if (value.contains('sip')) {
      return 'SIP';
    }
    if (value.contains('pf') ||
        value.contains('epf') ||
        value.contains('ppf') ||
        value.contains('provident')) {
      return 'PF';
    }
    if (value.contains('goal')) {
      return 'Financial Goal';
    }

    return 'Other';
  }

  List<FinancialData> get mutualFunds => investments
      .where((item) => normalizeType(item.type) == 'Mutual Fund')
      .toList();

  List<FinancialData> get pfInvestments => investments
      .where((item) => normalizeType(item.type) == 'PF')
      .toList();

  List<FinancialData> get sipInvestments => investments
      .where((item) => normalizeType(item.type) == 'SIP')
      .toList();

  List<FinancialData> get financialGoals => investments
      .where((item) => normalizeType(item.type) == 'Financial Goal')
      .toList();

  List<FinancialData> get otherInvestments => investments
      .where((item) => normalizeType(item.type) == 'Other')
      .toList();

  List<FinancialData> mutualFundsByCategory(String category) {
    return mutualFunds
        .where(
          (item) =>
              item.portfolioCategory.trim().toUpperCase() ==
              category.toUpperCase(),
        )
        .toList();
  }

  double mutualFundCategoryTotal(String category) {
    return mutualFundsByCategory(category).fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  double listTotal(List<FinancialData> data) {
    return data.fold(0.0, (sum, item) => sum + item.amount);
  }

  // ---------------- MESSAGES ----------------

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ============================================================
  // ADD EXISTING FINANCIAL DATA
  // ============================================================

  Future<void> openAddDataDialog() async {
    final FinancialData? result =
        await showDialog<FinancialData>(
      context: context,
      builder: (context) => const AddFinancialDataDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        investments.add(result);
      });
      showMessage('Financial data added successfully!');
    }
  }

  // ============================================================
  // EXISTING MF/PF/SIP/GOAL EXCEL IMPORT
  // ============================================================

  Future<void> importExcelData() async {
    try {
      final List<PlatformFile> files =
          await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (files.isEmpty) return;

      final PlatformFile file = files.first;
      final Uint8List bytes = await file.readAsBytes();
      final Excel excel = Excel.decodeBytes(bytes);
      final List<FinancialData> importedInvestments = [];

      for (final String tableName in excel.tables.keys) {
        final Sheet? sheet = excel.tables[tableName];
        if (sheet == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 4) continue;

          final String portfolioCategory =
              row[0]?.value?.toString().trim() ?? '';
          final String type =
              row[1]?.value?.toString().trim() ?? '';
          final String name =
              row[2]?.value?.toString().trim() ?? '';

          String amountText =
              row[3]?.value?.toString().trim() ?? '';

          amountText = amountText
              .replaceAll('₹', '')
              .replaceAll(',', '')
              .replaceAll('INR', '')
              .trim();

          final double? amount =
              double.tryParse(amountText);

          if (name.isEmpty || amount == null) continue;

          importedInvestments.add(
            FinancialData(
              portfolioCategory: portfolioCategory.isEmpty
                  ? 'General'
                  : portfolioCategory,
              type: type.isEmpty ? 'Other' : type,
              name: name,
              amount: amount,
            ),
          );
        }
      }

      if (!mounted) return;

      if (importedInvestments.isEmpty) {
        showMessage(
          'No valid financial records found in the Excel file.',
          isError: true,
        );
        return;
      }

      setState(() {
        investments.addAll(importedInvestments);
      });

      showMessage(
        '${importedInvestments.length} records imported successfully!',
      );
    } catch (error) {
      showMessage(
        'Error importing Excel file: $error',
        isError: true,
      );
    }
  }

  // ============================================================
  // SEPARATE MF / SIP / PF EXCEL IMPORTS
  // ============================================================

  Future<void> importInvestmentTypeExcel(String requiredType) async {
    try {
      final files = await pickExcelFile();
      if (files == null) return;

      final Uint8List bytes = await files.first.readAsBytes();
      final Excel excel = Excel.decodeBytes(bytes);
      final List<FinancialData> imported = [];

      for (final tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName];
        if (sheet == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 4) continue;

          final portfolioCategory = cellText(row, 0);
          final type = cellText(row, 1);
          final name = cellText(row, 2);
          final amount = parseMoney(cellText(row, 3));

          final normalized = normalizeType(type);

          // The separate buttons only accept their own investment type.
          if (name.isEmpty || amount <= 0 || normalized != requiredType) {
            continue;
          }

          imported.add(
            FinancialData(
              portfolioCategory:
                  portfolioCategory.isEmpty ? 'General' : portfolioCategory,
              type: type.isEmpty ? requiredType : type,
              name: name,
              amount: amount,
            ),
          );
        }
      }

      if (imported.isEmpty) {
        showMessage(
          'No valid $requiredType records found in this Excel file.',
          isError: true,
        );
        return;
      }

      setState(() => investments.addAll(imported));
      showMessage('${imported.length} $requiredType records imported!');
    } catch (error) {
      showMessage(
        '$requiredType import error: $error',
        isError: true,
      );
    }
  }

  Future<void> importMFExcel() =>
      importInvestmentTypeExcel('Mutual Fund');

  Future<void> importSIPExcel() =>
      importInvestmentTypeExcel('SIP');

  Future<void> importPFExcel() =>
      importInvestmentTypeExcel('PF');

  // ============================================================
  // GENERIC FILE PICKER
  // ============================================================

  Future<List<PlatformFile>?> pickExcelFile() async {
    final List<PlatformFile> files =
        await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (files.isEmpty) return null;
    return files;
  }

  // ============================================================
  // FD EXCEL IMPORT
  //
  // Expected columns:
  // Bank | FD Number | Principal | Interest Rate |
  // Start Date | Maturity Date | Maturity Amount
  // ============================================================

  Future<void> importFDExcel() async {
    try {
      final files = await pickExcelFile();
      if (files == null) return;

      final Uint8List bytes = await files.first.readAsBytes();
      final Excel excel = Excel.decodeBytes(bytes);
      final List<DepositRecord> imported = [];

      for (final tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName];
        if (sheet == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 7) continue;

          final bank = cellText(row, 0);
          final number = cellText(row, 1);
          final principal = parseMoney(cellText(row, 2));
          final rate = parseMoney(cellText(row, 3));
          final start = cellText(row, 4);
          final maturity = cellText(row, 5);
          final maturityAmount = parseMoney(cellText(row, 6));

          if (bank.isEmpty || principal <= 0) continue;

          imported.add(
            DepositRecord(
              type: 'FD',
              bank: bank,
              accountNumber: number,
              principal: principal,
              monthlyDeposit: 0,
              interestRate: rate,
              startDate: start,
              maturityDate: maturity,
              maturityAmount: maturityAmount,
            ),
          );
        }
      }

      if (imported.isEmpty) {
        showMessage(
          'No valid FD records found. Check the Excel columns.',
          isError: true,
        );
        return;
      }

      setState(() => deposits.addAll(imported));

      showMessage('${imported.length} FD records imported!');
    } catch (error) {
      showMessage(
        'FD import error: $error',
        isError: true,
      );
    }
  }

  // ============================================================
  // RD EXCEL IMPORT
  //
  // Expected columns:
  // Bank | RD Number | Monthly Deposit | Interest Rate |
  // Start Date | Maturity Date | Maturity Amount
  // ============================================================

  Future<void> importRDExcel() async {
    try {
      final files = await pickExcelFile();
      if (files == null) return;

      final Uint8List bytes = await files.first.readAsBytes();
      final Excel excel = Excel.decodeBytes(bytes);
      final List<DepositRecord> imported = [];

      for (final tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName];
        if (sheet == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 7) continue;

          final bank = cellText(row, 0);
          final number = cellText(row, 1);
          final monthly = parseMoney(cellText(row, 2));
          final rate = parseMoney(cellText(row, 3));
          final start = cellText(row, 4);
          final maturity = cellText(row, 5);
          final maturityAmount = parseMoney(cellText(row, 6));

          if (bank.isEmpty || monthly <= 0) continue;

          imported.add(
            DepositRecord(
              type: 'RD',
              bank: bank,
              accountNumber: number,
              principal: 0,
              monthlyDeposit: monthly,
              interestRate: rate,
              startDate: start,
              maturityDate: maturity,
              maturityAmount: maturityAmount,
            ),
          );
        }
      }

      if (imported.isEmpty) {
        showMessage(
          'No valid RD records found. Check the Excel columns.',
          isError: true,
        );
        return;
      }

      setState(() => deposits.addAll(imported));

      showMessage('${imported.length} RD records imported!');
    } catch (error) {
      showMessage(
        'RD import error: $error',
        isError: true,
      );
    }
  }

  // ============================================================
  // INSURANCE EXCEL IMPORT
  //
  // Expected columns:
  // Company | Policy Number | Policy Type | Premium |
  // Frequency | Start Date | Maturity Date | Sum Assured
  // ============================================================

  Future<void> importInsuranceExcel() async {
    try {
      final files = await pickExcelFile();
      if (files == null) return;

      final Uint8List bytes = await files.first.readAsBytes();
      final Excel excel = Excel.decodeBytes(bytes);
      final List<InsuranceRecord> imported = [];

      for (final tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName];
        if (sheet == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 8) continue;

          final company = cellText(row, 0);
          final policyNumber = cellText(row, 1);
          final policyType = cellText(row, 2);
          final premium = parseMoney(cellText(row, 3));
          final frequency = cellText(row, 4);
          final start = cellText(row, 5);
          final maturity = cellText(row, 6);
          final sumAssured = parseMoney(cellText(row, 7));

          if (company.isEmpty || policyNumber.isEmpty) continue;

          imported.add(
            InsuranceRecord(
              company: company,
              policyNumber: policyNumber,
              policyType: policyType,
              premium: premium,
              frequency: frequency,
              startDate: start,
              maturityDate: maturity,
              sumAssured: sumAssured,
            ),
          );
        }
      }

      if (imported.isEmpty) {
        showMessage(
          'No valid insurance records found. Check the Excel columns.',
          isError: true,
        );
        return;
      }

      setState(() => insurancePolicies.addAll(imported));

      showMessage('${imported.length} insurance policies imported!');
    } catch (error) {
      showMessage(
        'Insurance import error: $error',
        isError: true,
      );
    }
  }

  String cellText(List<Data?> row, int index) {
    if (index >= row.length) return '';
    return row[index]?.value?.toString().trim() ?? '';
  }

  double parseMoney(String text) {
    return double.tryParse(
          text
              .replaceAll('₹', '')
              .replaceAll(',', '')
              .replaceAll('%', '')
              .replaceAll('INR', '')
              .trim(),
        ) ??
        0;
  }

  // ============================================================
  // GOLD
  // ============================================================

  Future<void> openAddGoldDialog() async {
    final GoldRecord? result =
        await showDialog<GoldRecord>(
      context: context,
      builder: (_) => const AddGoldDialog(),
    );

    if (result != null) {
      setState(() => goldRecords.add(result));
      showMessage('Gold record added successfully!');
    }
  }

  Future<void> openGoldCalculator() async {
    await showDialog(
      context: context,
      builder: (_) => GoldCalculatorDialog(
        deposits: deposits.where((d) => d.type == 'FD').toList(),
      ),
    );
  }
  // ============================================================
// GOAL TRACKER
// ============================================================

Widget goalTrackerCard() {
  final goals = financialGoals;

  final int totalGoals = goals.length;

  final int toDoCount = goals
      .where((goal) => goal.status == 'To Do')
      .length;

  final int inProgressCount = goals
      .where((goal) => goal.status == 'In Progress')
      .length;

  final int workDoneCount = goals
      .where((goal) => goal.status == 'Work Done')
      .length;

  final double totalTarget = goals.fold(
    0.0,
    (sum, goal) => sum + goal.amount,
  );

  final double totalSaved = goals.fold(
    0.0,
    (sum, goal) => sum + goal.currentSavings,
  );

  final double totalRemaining =
      (totalTarget - totalSaved) < 0
          ? 0.0
          : totalTarget - totalSaved;

  final double overallProgress =
      totalTarget > 0
          ? (totalSaved / totalTarget).clamp(0.0, 1.0)
          : 0.0;

  return Card(
    elevation: 3,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ====================================================
          // TITLE
          // ====================================================

          Row(
            children: [
              const Icon(
                Icons.track_changes,
                size: 28,
              ),

              const SizedBox(width: 10),

              const Text(
                'Goal Tracker',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ====================================================
          // STATUS SUMMARY
          // ====================================================

          Row(
            children: [

              Expanded(
                child: goalTrackerStat(
                  title: 'Total Goals',
                  value: '$totalGoals',
                  icon: Icons.flag,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: goalTrackerStat(
                  title: 'To Do',
                  value: '$toDoCount',
                  icon: Icons.assignment_outlined,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: goalTrackerStat(
                  title: 'In Progress',
                  value: '$inProgressCount',
                  icon: Icons.timelapse,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: goalTrackerStat(
                  title: 'Work Done',
                  value: '$workDoneCount',
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ====================================================
          // OVERALL PROGRESS
          // ====================================================

          const Text(
            'Overall Progress',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: overallProgress,
            minHeight: 12,
          ),

          const SizedBox(height: 8),

          Text(
            '${(overallProgress * 100).toStringAsFixed(1)}% completed',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 10),

          // ====================================================
          // MONEY SUMMARY
          // ====================================================

          goalTrackerMoneyRow(
            'Total Target',
            totalTarget,
          ),

          goalTrackerMoneyRow(
            'Total Saved',
            totalSaved,
          ),

          goalTrackerMoneyRow(
            'Remaining',
            totalRemaining,
          ),
        ],
      ),
    ),
  );
}


// ============================================================
// GOAL TRACKER STAT BOX
// ============================================================

Widget goalTrackerStat({
  required String title,
  required String value,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 4,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context)
            .colorScheme
            .outlineVariant,
      ),
    ),
    child: Column(
      children: [

        Icon(
          icon,
          size: 24,
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}


// ============================================================
// GOAL TRACKER MONEY ROW
// ============================================================

Widget goalTrackerMoneyRow(
  String title,
  double amount,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 6,
    ),
    child: Row(
      children: [

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),

        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // FINANCIAL GOAL ACTIONS
  // ============================================================

  Future<void> openFinancialGoalDialog({
    FinancialData? existing,
  }) async {
    final FinancialData? result =
        await showDialog<FinancialData>(
      context: context,
      builder: (_) => FinancialGoalDialog(
        existing: existing,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      if (existing != null) {
        final index = investments.indexOf(existing);
        if (index >= 0) {
          investments[index] = result;
        }
      } else {
        investments.add(result);
      }
    });

    await savePortfolio();

    if (!mounted) return;

    showMessage(
      existing == null
          ? 'Financial goal saved!'
          : 'Financial goal updated!',
    );
  }

  Future<void> deleteFinancialGoal(
    FinancialData goal,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Financial Goal'),
          content: Text(
            'Are you sure you want to delete "${goal.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() {
      investments.remove(goal);
    });

    await savePortfolio();

    if (!mounted) return;

    showMessage('Financial goal deleted.');
  }

  Widget financialGoalTile(FinancialData goal) {
    DateTime? parsedDate;

    if (goal.targetDate.trim().isNotEmpty) {
      parsedDate = DateTime.tryParse(goal.targetDate);
    }

    String formattedDate = 'Not selected';

    if (parsedDate != null) {
      formattedDate =
          '${parsedDate.day.toString().padLeft(2, '0')}/'
          '${parsedDate.month.toString().padLeft(2, '0')}/'
          '${parsedDate.year}';
    }

    IconData statusIcon;

    switch (goal.status) {
      case 'Work Done':
        statusIcon = Icons.check_circle;
        break;
      case 'In Progress':
        statusIcon = Icons.timelapse;
        break;
      case 'To Do':
      default:
        statusIcon = Icons.assignment_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(Icons.flag),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        avatar: Icon(
                          statusIcon,
                          size: 18,
                        ),
                        label: Text(goal.status),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => openFinancialGoalDialog(
                    existing: goal,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => deleteFinancialGoal(goal),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Target Amount: ₹${goal.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Current Savings: '
              '₹${goal.currentSavings.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Remaining: '
              '₹${goal.remainingAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Monthly Contribution: '
              '₹${goal.monthlyContribution.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            Text('Target Date: $formattedDate'),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: goal.goalProgress,
              minHeight: 10,
            ),
            const SizedBox(height: 6),
            Text(
              '${goal.goalPercentage.toStringAsFixed(1)}% completed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (goal.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(goal.notes),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FUTURE GOALS / NOTEPAD
  // ============================================================

  Future<void> openFutureGoalNoteDialog({FutureGoalNote? existing}) async {
    final FutureGoalNote? result =
        await showDialog<FutureGoalNote>(
      context: context,
      builder: (_) => FutureGoalNoteDialog(existing: existing),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (existing != null) {
        final index = futureGoalNotes.indexOf(existing);
        if (index >= 0) {
          futureGoalNotes[index] = result;
        }
      } else {
        futureGoalNotes.add(result);
      }
    });

    // Save immediately so the future goal/note survives refresh.
    await savePortfolio();

    showMessage(
      existing == null
          ? 'Future goal note added!'
          : 'Future goal note updated!',
    );
  }

  Future<void> deleteFutureGoalNote(FutureGoalNote note) async {
    setState(() => futureGoalNotes.remove(note));
    await savePortfolio();
    showMessage('Future goal note deleted.');
  }

  // ============================================================
  // DELETE METHODS
  // ============================================================

  void deleteInvestment(FinancialData item) {
    setState(() => investments.remove(item));
    showMessage('${item.name} deleted.');
  }

  void deleteGold(GoldRecord item) {
    setState(() => goldRecords.remove(item));
    showMessage('Gold record deleted.');
  }

  void deleteDeposit(DepositRecord item) {
    setState(() => deposits.remove(item));
    showMessage('${item.type} deleted.');
  }

  void deleteInsurance(InsuranceRecord item) {
    setState(() => insurancePolicies.remove(item));
    showMessage('Insurance policy deleted.');
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    await prefs.remove('logged_in_user_name');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final fdRecords =
        deposits.where((item) => item.type == 'FD').toList();
    final rdRecords =
        deposits.where((item) => item.type == 'RD').toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'FinSight Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Save Permanently',
            icon: isPortfolioSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: isPortfolioSaving ? null : savePortfolio,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'importExcel',
            onPressed: importExcelData,
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Excel'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'addFinancialData',
            onPressed: openAddDataDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Data'),
          ),
        ],
      ),
      body: isPortfolioLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${widget.userName} 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Your Complete Financial Overview',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // TOTAL PORTFOLIO
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 45,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Portfolio Value',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '₹${totalPortfolioValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${investments.length + goldRecords.length + deposits.length} Asset Records',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Financial Summary',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                summaryCard(
                  title: 'Mutual Funds',
                  amount: listTotal(mutualFunds),
                  count: mutualFunds.length,
                  icon: Icons.show_chart,
                ),
                summaryCard(
                  title: 'PF',
                  amount: listTotal(pfInvestments),
                  count: pfInvestments.length,
                  icon: Icons.account_balance,
                ),
                summaryCard(
                  title: 'SIPs',
                  amount: listTotal(sipInvestments),
                  count: sipInvestments.length,
                  icon: Icons.trending_up,
                ),
                summaryCard(
                  title: 'Goals',
                  amount: listTotal(financialGoals),
                  count: financialGoals.length,
                  icon: Icons.flag,
                ),
                summaryCard(
                  title: 'Gold',
                  amount: totalGoldValue,
                  count: goldRecords.length,
                  icon: Icons.circle,
                ),
                summaryCard(
                  title: 'FD + RD',
                  amount: totalDeposits,
                  count: deposits.length,
                  icon: Icons.savings,
                ),
                summaryCard(
                  title: 'Insurance',
                  amount: 0,
                  count: insurancePolicies.length,
                  icon: Icons.security,
                  suffix: 'Protection',
                ),
                summaryCard(
                  title: 'Other',
                  amount: listTotal(otherInvestments),
                  count: otherInvestments.length,
                  icon: Icons.diamond,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // MUTUAL FUNDS
            financialSection(
              title: 'Mutual Funds',
              icon: Icons.show_chart,
              count: mutualFunds.length,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: importMFExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import Mutual Fund Excel'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (mutualFunds.isEmpty)
                    emptyMessage('No Mutual Fund data added yet.')
                  else ...[
                    mutualFundPortfolioCard(
                      'TPR',
                      Icons.trending_up,
                    ),
                    mutualFundPortfolioCard(
                      'PPR',
                      Icons.account_balance,
                    ),
                    mutualFundPortfolioCard(
                      'PR',
                      Icons.pie_chart,
                    ),
                    mutualFundPortfolioCard(
                      'TPRW',
                      Icons.auto_graph,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // GOLD
            financialSection(
              title: 'Gold',
              icon: Icons.circle,
              count: goldRecords.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: openAddGoldDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Gold Price / Holding'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: openGoldCalculator,
                          icon: const Icon(Icons.calculate),
                          label: const Text('Gold Calculator'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (goldRecords.isEmpty)
                    emptyMessage(
                      'No gold records added yet.',
                    )
                  else ...[
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.currency_rupee),
                        ),
                        title: const Text(
                          'Current Gold Value',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${goldRecords.fold<double>(0, (s, g) => s + g.grams).toStringAsFixed(2)} grams',
                        ),
                        trailing: Text(
                          '₹${totalGoldValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    ...goldRecords.map(goldTile),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // FD
            financialSection(
              title: 'Fixed Deposits (FD)',
              icon: Icons.account_balance,
              count: fdRecords.length,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: importFDExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import FD Excel'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (fdRecords.isEmpty)
                    emptyMessage('No FD records imported yet.')
                  else
                    ...fdRecords.map(depositTile),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // RD
            financialSection(
              title: 'Recurring Deposits (RD)',
              icon: Icons.savings,
              count: rdRecords.length,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: importRDExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import RD Excel'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (rdRecords.isEmpty)
                    emptyMessage('No RD records imported yet.')
                  else
                    ...rdRecords.map(depositTile),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // PF
            financialSection(
              title: 'Provident Funds (PF)',
              icon: Icons.account_balance,
              count: pfInvestments.length,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: importPFExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import PF Excel'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  recordsList(
                    pfInvestments,
                    Icons.account_balance,
                    'No PF data added yet.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // SIP
            financialSection(
              title: 'SIP Investments',
              icon: Icons.trending_up,
              count: sipInvestments.length,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: importSIPExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import SIP Excel'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  recordsList(
                    sipInvestments,
                    Icons.trending_up,
                    'No SIP data added yet.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // FINANCIAL GOALS
            financialSection(
              title: 'Financial Goals',
              icon: Icons.flag,
              count: financialGoals.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => openFinancialGoalDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Financial Goal'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (financialGoals.isNotEmpty)
                    goalTrackerCard(),
                  if (financialGoals.isEmpty)
                    emptyMessage(
                      'No Financial Goals added yet.',
                    )
                  else
                    ...financialGoals.map(financialGoalTile),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // FUTURE GOALS / NOTEPAD
            financialSection(
              title: 'Future Goals / Notepad',
              icon: Icons.edit_note,
              count: futureGoalNotes.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => openFutureGoalNoteDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Future Goal / Note'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (futureGoalNotes.isEmpty)
                    emptyMessage(
                      'Jot down your future plans, goals or ideas here.',
                    )
                  else
                    ...futureGoalNotes.map(futureGoalNoteTile),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // INSURANCE
            financialSection(
              title: 'Life Insurance',
              icon: Icons.security,
              count: insurancePolicies.length,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: importInsuranceExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text(
                        'Import Life Insurance Excel',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (insurancePolicies.isEmpty)
                    emptyMessage(
                      'No insurance policies imported yet.',
                    )
                  else
                    ...insurancePolicies.map(insuranceTile),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // OTHER
            financialSection(
              title: 'Other Investments',
              icon: Icons.diamond,
              count: otherInvestments.length,
              child: recordsList(
                otherInvestments,
                Icons.diamond,
                'No Other Investments added yet.',
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget summaryCard({
    required String title,
    required double amount,
    required int count,
    required IconData icon,
    String? suffix,
  }) {
    return SizedBox(
      width: 210,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 5),
              if (suffix != null)
                Text(
                  suffix,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                )
              else
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                '$count Records',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget financialSection({
    required String title,
    required IconData icon,
    required int count,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        subtitle: Text('$count Records'),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: child,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MF CATEGORY CARD
  // ============================================================

  Widget mutualFundPortfolioCard(
    String category,
    IconData icon,
  ) {
    final data = mutualFundsByCategory(category);
    final total = mutualFundCategoryTotal(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          category,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '₹${total.toStringAsFixed(2)} • ${data.length} Funds',
        ),
        children: [
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'No Mutual Funds in this category.',
              ),
            )
          else
            ...data.map(
              (item) => investmentTile(
                item,
                Icons.account_balance_wallet,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // RECORD LIST
  // ============================================================

  Widget recordsList(
    List<FinancialData> data,
    IconData icon,
    String emptyText,
  ) {
    if (data.isEmpty) {
      return emptyMessage(emptyText);
    }

    return Column(
      children: data
          .map((item) => investmentTile(item, icon))
          .toList(),
    );
  }

  Widget emptyMessage(String text) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  // ============================================================
  // INVESTMENT TILE
  // ============================================================

  Widget investmentTile(
    FinancialData item,
    IconData icon,
  ) {
    if (item.isFinancialGoal) {
      final progressPercent = item.goalProgress * 100;

      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Icon(icon)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => deleteInvestment(item),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Target Amount: ₹${item.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Current Savings: ₹${item.currentSavings.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Monthly Contribution: ₹${item.monthlyContribution.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 4),
              Text(
                item.targetDate.trim().isEmpty
                    ? 'Target Date: Not set'
                    : 'Target Date: ${item.targetDate}',
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: item.goalProgress),
              const SizedBox(height: 5),
              Text(
                'Progress: ${progressPercent.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (item.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${item.notes}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(item.name),
        subtitle: Text(
          item.notes.trim().isEmpty
              ? '${item.portfolioCategory} • ${item.type}'
              : '${item.portfolioCategory} • ${item.type}\n${item.notes}',
        ),
        isThreeLine: item.notes.trim().isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () => deleteInvestment(item),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GOLD TILE
  // ============================================================

  Widget goldTile(GoldRecord item) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.circle),
        ),
        title: Text(
          '${item.grams.toStringAsFixed(2)} grams',
        ),
        subtitle: Text(
          '${formatDate(item.date)} • ₹${item.pricePerGram.toStringAsFixed(2)}/g',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.currentValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () => deleteGold(item),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FD/RD TILE
  // ============================================================

  Widget depositTile(DepositRecord item) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(item.type),
        ),
        title: Text(item.bank),
        subtitle: Text(
          '${item.accountNumber.isEmpty ? 'No account number' : item.accountNumber}'
          ' • ${item.interestRate.toStringAsFixed(2)}%'
          '\nMaturity: ${item.maturityDate}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.portfolioValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () => deleteDeposit(item),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INSURANCE TILE
  // ============================================================

  Widget insuranceTile(InsuranceRecord item) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.security),
        ),
        title: Text(item.company),
        subtitle: Text(
          '${item.policyType} • ${item.policyNumber}'
          '\nPremium: ₹${item.premium.toStringAsFixed(2)} ${item.frequency}'
          '\nMaturity: ${item.maturityDate}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.sumAssured.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () => deleteInsurance(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget futureGoalNoteTile(FutureGoalNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.edit_note),
        ),
        title: Text(
          note.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            note.note,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => openFutureGoalNoteDialog(existing: note),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: () => deleteFutureGoalNote(note),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ============================================================
// FINANCIAL GOAL DIALOG
// ============================================================

class FinancialGoalDialog extends StatefulWidget {
  final FinancialData? existing;

  const FinancialGoalDialog({
    super.key,
    this.existing,
  });

  @override
  State<FinancialGoalDialog> createState() =>
      _FinancialGoalDialogState();
}

class _FinancialGoalDialogState
    extends State<FinancialGoalDialog> {
  late final TextEditingController nameController;
  late final TextEditingController targetAmountController;
  late final TextEditingController currentSavingsController;
  late final TextEditingController monthlyContributionController;
  late final TextEditingController notesController;

  DateTime? selectedTargetDate;
  String selectedStatus = 'To Do';

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.existing?.name ?? '',
    );

    targetAmountController = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.amount.toString()
          : '',
    );

    currentSavingsController = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.currentSavings.toString()
          : '',
    );

    monthlyContributionController = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.monthlyContribution.toString()
          : '',
    );

    notesController = TextEditingController(
      text: widget.existing?.notes ?? '',
    );

    if (widget.existing != null &&
        widget.existing!.targetDate.trim().isNotEmpty) {
      selectedTargetDate = DateTime.tryParse(
        widget.existing!.targetDate,
      );
    }

    selectedStatus = widget.existing?.status ?? 'To Do';

    const allowedStatuses = [
      'To Do',
      'In Progress',
      'Work Done',
    ];

    if (!allowedStatuses.contains(selectedStatus)) {
      selectedStatus = 'To Do';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    targetAmountController.dispose();
    currentSavingsController.dispose();
    monthlyContributionController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> selectTargetDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    var initialDate = selectedTargetDate ?? firstDate;

    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 50),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedTargetDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void saveGoal() {
    final name = nameController.text.trim();

    final targetAmount = double.tryParse(
      targetAmountController.text.trim(),
    );

    final currentSavings = double.tryParse(
      currentSavingsController.text.trim(),
    );

    final monthlyContribution = double.tryParse(
      monthlyContributionController.text.trim(),
    );

    final notes = notesController.text.trim();

    if (name.isEmpty) {
      showError('Please enter a goal name.');
      return;
    }

    if (targetAmount == null || targetAmount <= 0) {
      showError('Please enter a valid target amount.');
      return;
    }

    if (currentSavings == null || currentSavings < 0) {
      showError('Current savings cannot be negative.');
      return;
    }

    if (currentSavings > targetAmount) {
      showError(
        'Current savings cannot be greater than target amount.',
      );
      return;
    }

    if (monthlyContribution == null || monthlyContribution < 0) {
      showError('Monthly contribution cannot be negative.');
      return;
    }

    if (selectedTargetDate == null) {
      showError('Please select a target date.');
      return;
    }

    Navigator.pop(
      context,
      FinancialData(
        portfolioCategory:
            widget.existing?.portfolioCategory ?? 'General',
        type: 'Financial Goal',
        name: name,
        amount: targetAmount,
        notes: notes,
        currentSavings: currentSavings,
        targetDate: selectedTargetDate!.toIso8601String(),
        monthlyContribution: monthlyContribution,
        status: selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Edit Financial Goal'
            : 'Add Financial Goal',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  hintText: 'Example: Buy a Car',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: targetAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: currentSavingsController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current Savings',
                  prefixIcon: Icon(Icons.savings),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: monthlyContributionController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monthly Contribution',
                  prefixIcon: Icon(Icons.calendar_month),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              InkWell(
                onTap: selectTargetDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Target Date',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    selectedTargetDate == null
                        ? 'Select target date'
                        : formatDate(selectedTargetDate!),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Goal Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'To Do',
                    child: Text('📝 To Do'),
                  ),
                  DropdownMenuItem(
                    value: 'In Progress',
                    child: Text('🔄 In Progress'),
                  ),
                  DropdownMenuItem(
                    value: 'Work Done',
                    child: Text('✅ Work Done'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add any additional details...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: saveGoal,
          icon: const Icon(Icons.save),
          label: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}

// ============================================================
// ADD FINANCIAL DATA DIALOG
// ============================================================

class AddFinancialDataDialog extends StatefulWidget {
  const AddFinancialDataDialog({super.key});

  @override
  State<AddFinancialDataDialog> createState() =>
      _AddFinancialDataDialogState();
}

class _AddFinancialDataDialogState
    extends State<AddFinancialDataDialog> {
  String selectedPortfolio = 'TPR';
  String selectedType = 'Mutual Fund';

  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController amountController =
      TextEditingController();
  final TextEditingController currentSavingsController =
      TextEditingController();
  final TextEditingController monthlyContributionController =
      TextEditingController();
  final TextEditingController targetDateController =
      TextEditingController();
  final TextEditingController notesController =
      TextEditingController();

  DateTime? selectedTargetDate;

  bool get isFinancialGoal => selectedType == 'Financial Goal';

  double _parseMoney(String value) {
    return double.tryParse(
          value.replaceAll('₹', '').replaceAll(',', '').trim(),
        ) ??
        0.0;
  }

  Future<void> pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedTargetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      selectedTargetDate = picked;
      targetDateController.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    });
  }

  void saveInvestment() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name.')),
      );
      return;
    }

    if (isFinancialGoal) {
      final targetAmount = _parseMoney(amountController.text);
      final currentSavings =
          _parseMoney(currentSavingsController.text);
      final monthlyContribution =
          _parseMoney(monthlyContributionController.text);

      if (targetAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid target amount.'),
          ),
        );
        return;
      }

      if (currentSavings < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current savings cannot be negative.'),
          ),
        );
        return;
      }

      if (monthlyContribution < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly contribution cannot be negative.'),
          ),
        );
        return;
      }

      Navigator.pop(
        context,
        FinancialData(
          portfolioCategory: selectedPortfolio,
          type: selectedType,
          name: name,
          amount: targetAmount,
          currentSavings: currentSavings,
          targetDate: targetDateController.text.trim(),
          monthlyContribution: monthlyContribution,
          notes: notesController.text.trim(),
        ),
      );
      return;
    }

    final amount = _parseMoney(amountController.text);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      FinancialData(
        portfolioCategory: selectedPortfolio,
        type: selectedType,
        name: name,
        amount: amount,
        notes: notesController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    currentSavingsController.dispose();
    monthlyContributionController.dispose();
    targetDateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isFinancialGoal
            ? 'Add Financial Goal'
            : 'Add Financial Data',
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Financial Data Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Mutual Fund',
                    child: Text('Mutual Fund'),
                  ),
                  DropdownMenuItem(
                    value: 'PF',
                    child: Text('PF / Provident Fund'),
                  ),
                  DropdownMenuItem(
                    value: 'SIP',
                    child: Text('SIP'),
                  ),
                  DropdownMenuItem(
                    value: 'Financial Goal',
                    child: Text('Financial Goal'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other Investment'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: selectedPortfolio,
                decoration: const InputDecoration(
                  labelText: 'Portfolio Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'TPR',
                    child: Text('TPR'),
                  ),
                  DropdownMenuItem(
                    value: 'PPR',
                    child: Text('PPR'),
                  ),
                  DropdownMenuItem(
                    value: 'PR',
                    child: Text('PR'),
                  ),
                  DropdownMenuItem(
                    value: 'TPRW',
                    child: Text('TPRW'),
                  ),
                  DropdownMenuItem(
                    value: 'General',
                    child: Text('General'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedPortfolio = value);
                  }
                },
              ),
              const SizedBox(height: 15),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText:
                      isFinancialGoal ? 'Goal Name' : 'Name',
                  hintText: isFinancialGoal
                      ? 'Example: Buy a Car'
                      : null,
                  prefixIcon: Icon(
                    isFinancialGoal
                        ? Icons.flag_outlined
                        : Icons.account_balance,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isFinancialGoal
                      ? 'Target Amount'
                      : 'Amount',
                  hintText: isFinancialGoal
                      ? 'Example: 1000000'
                      : null,
                  prefixIcon:
                      const Icon(Icons.currency_rupee),
                  border: const OutlineInputBorder(),
                ),
              ),

              if (isFinancialGoal) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: currentSavingsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Current Savings',
                    hintText: 'Example: 250000',
                    prefixIcon: Icon(Icons.savings_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: monthlyContributionController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Contribution',
                    hintText: 'Example: 25000',
                    prefixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: targetDateController,
                  readOnly: true,
                  onTap: pickTargetDate,
                  decoration: const InputDecoration(
                    labelText: 'Target Date',
                    hintText: 'Select target date',
                    prefixIcon: Icon(Icons.event),
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 15),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: isFinancialGoal
                      ? 'Notes (Optional)'
                      : 'Notes',
                  hintText: isFinancialGoal
                      ? 'Example: Need to increase savings after graduation.'
                      : 'Enter any additional details',
                  prefixIcon: const Icon(Icons.notes),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: saveInvestment,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================
// ADD GOLD DIALOG
// ============================================================

class AddGoldDialog extends StatefulWidget {
  const AddGoldDialog({super.key});

  @override
  State<AddGoldDialog> createState() => _AddGoldDialogState();
}

class _AddGoldDialogState extends State<AddGoldDialog> {
  DateTime selectedDate = DateTime.now();

  final priceController = TextEditingController();
  final gramsController = TextEditingController();

  double get calculatedAmount {
    final price = double.tryParse(
          priceController.text.replaceAll(',', ''),
        ) ??
        0;
    final grams = double.tryParse(
          gramsController.text.replaceAll(',', ''),
        ) ??
        0;
    return price * grams;
  }

  void save() {
    final price = double.tryParse(
          priceController.text.replaceAll(',', ''),
        ) ??
        0;
    final grams = double.tryParse(
          gramsController.text.replaceAll(',', ''),
        ) ??
        0;

    if (price <= 0 || grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid gold price and quantity.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      GoldRecord(
        date: selectedDate,
        pricePerGram: price,
        grams: grams,
        amountInvested: price * grams,
      ),
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Gold Holding'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Gold Price Date'),
              subtitle: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: selectedDate,
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Gold Price per Gram',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: gramsController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Gold Quantity (grams)',
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              child: ListTile(
                title: const Text('Investment Value'),
                trailing: Text(
                  '₹${calculatedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================
// GOLD CALCULATOR
// ============================================================

class GoldCalculatorDialog extends StatefulWidget {
  final List<DepositRecord> deposits;

  const GoldCalculatorDialog({
    super.key,
    required this.deposits,
  });

  @override
  State<GoldCalculatorDialog> createState() =>
      _GoldCalculatorDialogState();
}

class _GoldCalculatorDialogState
    extends State<GoldCalculatorDialog> {
  final priceController = TextEditingController();
  final targetGramsController = TextEditingController();
  final extraMoneyController = TextEditingController();

  String? selectedFD1;
  String? selectedFD2;

  List<DepositRecord> get fds => widget.deposits;

  double get fd1Amount {
    if (selectedFD1 == null) return 0;
    final fd = fds.firstWhere(
      (item) => item.accountNumber == selectedFD1,
      orElse: () => fds.first,
    );
    return fd.portfolioValue;
  }

  double get fd2Amount {
    if (selectedFD2 == null) return 0;
    final fd = fds.firstWhere(
      (item) => item.accountNumber == selectedFD2,
      orElse: () => fds.first,
    );
    return fd.portfolioValue;
  }

  double get price {
    return double.tryParse(
          priceController.text.replaceAll(',', ''),
        ) ??
        0;
  }

  double get targetGrams {
    return double.tryParse(
          targetGramsController.text.replaceAll(',', ''),
        ) ??
        0;
  }

  double get extraMoney {
    return double.tryParse(
          extraMoneyController.text.replaceAll(',', ''),
        ) ??
        0;
  }

  double get selectedFDMoney =>
      fd1Amount + fd2Amount;

  double get totalAvailable =>
      selectedFDMoney + extraMoney;

  double get purchasableGrams {
    if (price <= 0) return 0;
    return totalAvailable / price;
  }

  double get targetCost => targetGrams * price;

  double get additionalRequired {
    final difference = targetCost - totalAvailable;
    return difference > 0 ? difference : 0;
  }

  @override
  void dispose() {
    priceController.dispose();
    targetGramsController.dispose();
    extraMoneyController.dispose();
    super.dispose();
  }

  Widget numberField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gold Purchase Calculator'),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              numberField(
                priceController,
                'Gold Price per Gram',
                Icons.currency_rupee,
              ),
              const SizedBox(height: 12),
              numberField(
                targetGramsController,
                'Target Gold (grams)',
                Icons.scale,
              ),
              const SizedBox(height: 15),

              if (fds.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No FDs imported yet. You can still '
                      'use the calculator by entering extra money.',
                    ),
                  ),
                ),

              if (fds.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedFD1,
                  decoration: const InputDecoration(
                    labelText: 'Use FD 1',
                    border: OutlineInputBorder(),
                  ),
                  items: fds
                      .map(
                        (fd) => DropdownMenuItem<String>(
                          value: fd.accountNumber,
                          child: Text(
                            '${fd.bank} - '
                            '₹${fd.portfolioValue.toStringAsFixed(0)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedFD1 = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedFD2,
                  decoration: const InputDecoration(
                    labelText: 'Use FD 2',
                    border: OutlineInputBorder(),
                  ),
                  items: fds
                      .map(
                        (fd) => DropdownMenuItem<String>(
                          value: fd.accountNumber,
                          child: Text(
                            '${fd.bank} - '
                            '₹${fd.portfolioValue.toStringAsFixed(0)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedFD2 = value);
                  },
                ),
                const SizedBox(height: 12),
              ],

              numberField(
                extraMoneyController,
                'Additional Cash Available',
                Icons.currency_rupee,
              ),
              const SizedBox(height: 15),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      resultRow(
                        'FD 1 Amount',
                        fd1Amount,
                      ),
                      resultRow(
                        'FD 2 Amount',
                        fd2Amount,
                      ),
                      resultRow(
                        'Extra Cash',
                        extraMoney,
                      ),
                      const Divider(),
                      resultRow(
                        'Total Available',
                        totalAvailable,
                        bold: true,
                      ),
                      resultRow(
                        'Gold You Can Buy',
                        purchasableGrams,
                        suffix: ' g',
                        bold: true,
                      ),
                      resultRow(
                        'Target Gold Cost',
                        targetCost,
                        bold: true,
                      ),
                      resultRow(
                        'Additional Money Required',
                        additionalRequired,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget resultRow(
    String title,
    double value, {
    String suffix = '',
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            '₹${value.toStringAsFixed(2)}$suffix',
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FUTURE GOAL / NOTEPAD DIALOG
// ============================================================

class FutureGoalNoteDialog extends StatefulWidget {
  final FutureGoalNote? existing;

  const FutureGoalNoteDialog({
    super.key,
    this.existing,
  });

  @override
  State<FutureGoalNoteDialog> createState() =>
      _FutureGoalNoteDialogState();
}

class _FutureGoalNoteDialogState extends State<FutureGoalNoteDialog> {
  late final TextEditingController titleController;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    noteController = TextEditingController(
      text: widget.existing?.note ?? '',
    );
  }

  void saveNote() {
    final title = titleController.text.trim();
    final note = noteController.text.trim();

    if (title.isEmpty || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both a title and a note.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      FutureGoalNote(
        title: title,
        note: note,
        createdAt:
            widget.existing?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Edit Future Goal / Note'
            : 'Add Future Goal / Note',
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal / Note Title',
                  hintText: 'Example: Buy a car',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: noteController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Write your future plan',
                  hintText:
                      'Example: I want to buy a car in 2028...',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: saveNote,
          icon: const Icon(Icons.save),
          label: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}

