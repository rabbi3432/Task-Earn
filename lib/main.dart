import 'package:flutter/material.dart';

void main() => runApp(const TaskEarnApp());

class TaskEarnApp extends StatelessWidget {
  const TaskEarnApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Task Earn',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: const LoginPage(),
  );
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.task_alt, size: 76),
        const SizedBox(height: 16),
        const Text('Task Earn', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Complete tasks • Track earnings'),
        const SizedBox(height: 32),
        const TextField(decoration: InputDecoration(labelText: 'Phone or email', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Shell())),
          child: const Text('Login'),
        )),
        TextButton(onPressed: () {}, child: const Text('Create account')),
      ]),
    )),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  final pages = const [HomePage(), TasksPage(), WalletPage(), ProfilePage()];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: pages[index],
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Task Earn')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Available balance'),
        const Text('৳0.00', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.verified_user_outlined), label: const Text('Verify account')),
      ]))),
      const SizedBox(height: 12),
      const ListTile(leading: Icon(Icons.assignment), title: Text('Available tasks'), subtitle: Text('Tasks will appear here after backend setup')),
      const ListTile(leading: Icon(Icons.campaign), title: Text('Advertisement area'), subtitle: Text('Start.io integration will be added after App ID setup')),
    ]),
  );
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tasks')),
    body: const Center(child: Text('No tasks available yet')),
  );
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wallet')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Card(child: ListTile(title: Text('Balance'), subtitle: Text('৳0.00'))),
      const FilledButton(onPressed: null, child: Text('Withdraw')),
      const Padding(padding: EdgeInsets.only(top: 12), child: Text('Withdrawal will be enabled after secure backend setup.')),
    ]),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: const ListView(children: [
      ListTile(leading: Icon(Icons.person), title: Text('User profile')),
      ListTile(leading: Icon(Icons.verified), title: Text('Verification status'), subtitle: Text('Not verified')),
      ListTile(leading: Icon(Icons.history), title: Text('Transaction history')),
      ListTile(leading: Icon(Icons.support_agent), title: Text('Support')),
    ]),
  );
}
