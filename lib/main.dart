import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'book_screens.dart';
import 'book_validation.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BookShelfApp());
}

class BookShelfApp extends StatelessWidget {
  const BookShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF315C4B);
    return MaterialApp(
      title: 'BookShelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          surface: const Color(0xFFF8F7F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7F2),
          foregroundColor: Color(0xFF20352C),
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD8DED8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD8DED8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE6E9E3)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to check sign-in status: ${snapshot.error}'),
              ),
            ),
          );
        }
        final user = snapshot.data;
        if (user != null) return BookListScreen(user: user);
        return const HomeScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _Brand(),
        actions: [
          TextButton(
            onPressed: () => _openAuth(context, register: false),
            child: const Text('Login'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonal(
              onPressed: () => _openAuth(context, register: true),
              child: const Text('Register'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFE8),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 42),
                  const SizedBox(height: 18),
                  Text(
                    'BookShelf',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF20352C),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A little home for every book you own and every story you want to read.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => _openAuth(context, register: true),
                    child: const Text('Get started'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Your reading, beautifully organized',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const _FeatureCard(
              icon: Icons.library_books_outlined,
              title: 'Track your books',
              description: 'Keep your personal bookshelf all in one place.',
            ),
            const _FeatureCard(
              icon: Icons.sort_rounded,
              title: 'Sort by status',
              description: 'See what to read, what you are reading, and what is finished.',
            ),
            const _FeatureCard(
              icon: Icons.star_outline_rounded,
              title: 'Rate your favorites',
              description: 'Mark favorites and add a rating or a note.',
            ),
          ],
        ),
      ),
    );
  }

  void _openAuth(BuildContext context, {required bool register}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(register: register),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.menu_book_rounded),
        SizedBox(width: 8),
        Text('BookShelf', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8EFE8),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.register});

  final bool register;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  String? _firebaseError;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final register = widget.register;
    return Scaffold(
      appBar: AppBar(title: Text(register ? 'Register' : 'Login')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode:
              _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                register ? 'Create your account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(register
                  ? 'Sign up to start building your bookshelf.'
                  : 'Log in to see your personal bookshelf.'),
              const SizedBox(height: 26),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: validateEmail,
                onChanged: (_) => _fieldChanged(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textInputAction:
                    register ? TextInputAction.next : TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => validatePassword(
                  value,
                  requireMinimumLength: register,
                ),
                onChanged: (_) => _fieldChanged(),
              ),
              if (register) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) =>
                      validatePasswordConfirmation(value, _passwordController.text),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(register ? 'Register' : 'Login'),
              ),
              if (_firebaseError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _firebaseError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _successMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF315C4B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _continueToBookshelf,
                  child: const Text('Continue to BookShelf'),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => AuthScreen(register: !register),
                  ),
                ),
                child: Text(register
                    ? 'Already have an account? Login'
                    : 'New to BookShelf? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fieldChanged() {
    if (_firebaseError != null || (_submitted && widget.register)) {
      setState(() => _firebaseError = null);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _firebaseError = null;
      _successMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final auth = FirebaseAuth.instance;
      if (widget.register) {
        await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        setState(() {
          _busy = false;
          _successMessage = 'Registration successful';
        });
      } else {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        _continueToBookshelf();
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _firebaseError = error.message ?? error.code;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _firebaseError = 'Unable to sign in: $error';
      });
    }
  }

  void _continueToBookshelf() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _firebaseError = 'The account is not signed in. Please log in again.';
      });
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => BookListScreen(user: user)),
      (route) => false,
    );
  }
}
