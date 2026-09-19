import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      home: const AuthScreen(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ============================================================
  // REGISTER USER
  // ============================================================

  Future<void> registerUser() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('Please fill all fields', isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

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

        setState(() {
          isSignIn = true;
        });
      } else {
        showMessage(
          data['message']?.toString() ?? 'Registration failed',
          isError: true,
        );
      }
    } catch (error) {
      showMessage(
        'Unable to connect to the backend server.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // LOGIN USER
  // ============================================================

  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage(
        'Please enter email and password',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

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

        if (user is Map<String, dynamic>) {
          userName = user['name']?.toString() ?? 'User';
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FinSightDashboard(
              userName: userName,
            ),
          ),
        );
      } else {
        showMessage(
          data['message']?.toString() ?? 'Login failed',
          isError: true,
        );
      }
    } catch (error) {
      showMessage(
        'Unable to connect to the backend server.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void submit() {
    if (isSignIn) {
      loginUser();
    } else {
      registerUser();
    }
  }

  InputDecoration inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
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
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.account_balance_wallet,
                  size: 35,
                );
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'FinSight',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
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
                          setState(() {
                            isSignIn = true;
                          });
                          clearFields();
                        },
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            isSignIn = false;
                          });
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

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            isSignIn ? 'Sign In' : 'Register',
                          ),
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
                    setState(() {
                      isSignIn = !isSignIn;
                    });
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
// FINANCIAL DATA MODEL
// ============================================================

class FinancialData {
  final String portfolioCategory;
  final String type;
  final String name;
  final double amount;

  FinancialData({
    required this.portfolioCategory,
    required this.type,
    required this.name,
    required this.amount,
  });
}

// ============================================================
// FINSIGHT DASHBOARD
// ============================================================

class FinSightDashboard extends StatefulWidget {
  final String userName;

  const FinSightDashboard({
    super.key,
    required this.userName,
  });

  @override
  State<FinSightDashboard> createState() => _FinSightDashboardState();
}

class _FinSightDashboardState extends State<FinSightDashboard> {
  final List<FinancialData> investments = [];

  // ============================================================
  // TOTAL PORTFOLIO
  // ============================================================

  double get totalInvestment {
    return investments.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  // ============================================================
  // NORMALIZE TYPE
  // ============================================================

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

  // ============================================================
  // FILTER DATA BY TYPE
  // ============================================================

  List<FinancialData> get mutualFunds {
    return investments
        .where(
          (item) => normalizeType(item.type) == 'Mutual Fund',
        )
        .toList();
  }

  List<FinancialData> get pfInvestments {
    return investments
        .where(
          (item) => normalizeType(item.type) == 'PF',
        )
        .toList();
  }

  List<FinancialData> get sipInvestments {
    return investments
        .where(
          (item) => normalizeType(item.type) == 'SIP',
        )
        .toList();
  }

  List<FinancialData> get financialGoals {
    return investments
        .where(
          (item) => normalizeType(item.type) == 'Financial Goal',
        )
        .toList();
  }

  List<FinancialData> get otherInvestments {
    return investments
        .where(
          (item) => normalizeType(item.type) == 'Other',
        )
        .toList();
  }

  // ============================================================
  // MUTUAL FUND PORTFOLIO CATEGORY
  // ============================================================

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
    return data.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

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
  // ADD DATA MANUALLY
  // ============================================================

  Future<void> openAddDataDialog() async {
    final FinancialData? result = await showDialog<FinancialData>(
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
  // IMPORT EXCEL
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

        // First row = headings
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

          if (name.isEmpty || amount == null) {
            continue;
          }

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
  // DELETE DATA
  // ============================================================

  void deleteInvestment(FinancialData item) {
    setState(() {
      investments.remove(item);
    });

    showMessage('${item.name} deleted.');
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void logout() {
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'FinSight Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            Text(
              'Hello, ${widget.userName} 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Your Financial Investment Overview',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // TOTAL PORTFOLIO
            // ====================================================

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
                            '₹${totalInvestment.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${investments.length} Total Records',
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

            // ====================================================
            // FINANCIAL SUMMARY
            // ====================================================

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
                  title: 'Other',
                  amount: listTotal(otherInvestments),
                  count: otherInvestments.length,
                  icon: Icons.diamond,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ====================================================
            // MUTUAL FUNDS
            // ====================================================

            financialSection(
              title: 'Mutual Funds',
              icon: Icons.show_chart,
              count: mutualFunds.length,
              child: mutualFunds.isEmpty
                  ? emptyMessage(
                      'No Mutual Fund data added yet.',
                    )
                  : Column(
                      children: [
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
                    ),
            ),

            const SizedBox(height: 18),

            // ====================================================
            // PF
            // ====================================================

            financialSection(
              title: 'Provident Funds (PF)',
              icon: Icons.account_balance,
              count: pfInvestments.length,
              child: recordsList(
                pfInvestments,
                Icons.account_balance,
                'No PF data added yet.',
              ),
            ),

            const SizedBox(height: 18),

            // ====================================================
            // SIP
            // ====================================================

            financialSection(
              title: 'SIP Investments',
              icon: Icons.trending_up,
              count: sipInvestments.length,
              child: recordsList(
                sipInvestments,
                Icons.trending_up,
                'No SIP data added yet.',
              ),
            ),

            const SizedBox(height: 18),

            // ====================================================
            // GOALS
            // ====================================================

            financialSection(
              title: 'Financial Goals',
              icon: Icons.flag,
              count: financialGoals.length,
              child: recordsList(
                financialGoals,
                Icons.flag,
                'No Financial Goals added yet.',
              ),
            ),

            const SizedBox(height: 18),

            // ====================================================
            // OTHER INVESTMENTS
            // ====================================================

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
  }) {
    return SizedBox(
      width: 210,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count Records',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FINANCIAL SECTION
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
        leading: CircleAvatar(
          child: Icon(icon),
        ),
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
  // MUTUAL FUND PORTFOLIO CARD
  // ============================================================

  Widget mutualFundPortfolioCard(
    String category,
    IconData icon,
  ) {
    final List<FinancialData> data =
        mutualFundsByCategory(category);

    final double total =
        mutualFundCategoryTotal(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
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
          .map(
            (item) => investmentTile(item, icon),
          )
          .toList(),
    );
  }

  // ============================================================
  // EMPTY MESSAGE
  // ============================================================

  Widget emptyMessage(String text) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
          ),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(item.name),
        subtitle: Text(
          '${item.portfolioCategory} • ${item.type}',
        ),
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
              onPressed: () {
                deleteInvestment(item);
              },
            ),
          ],
        ),
      ),
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

  void saveInvestment() {
    if (nameController.text.trim().isEmpty ||
        amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields.'),
        ),
      );
      return;
    }

    String amountText = amountController.text
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();

    final double? amount =
        double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a valid amount.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      FinancialData(
        portfolioCategory: selectedPortfolio,
        type: selectedType,
        name: nameController.text.trim(),
        amount: amount,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Financial Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // DATA TYPE

            DropdownButtonFormField<String>(
              value: selectedType,
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
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedType = value;
                  });
                }
              },
            ),

            const SizedBox(height: 15),

            // PORTFOLIO CATEGORY

            DropdownButtonFormField<String>(
              value: selectedPortfolio,
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
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedPortfolio = value;
                  });
                }
              },
            ),

            const SizedBox(height: 15),

            // NAME

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // AMOUNT

            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: selectedType == 'Financial Goal'
                    ? 'Target Amount'
                    : 'Amount',
                prefixIcon:
                    const Icon(Icons.currency_rupee),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
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