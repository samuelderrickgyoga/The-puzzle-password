import 'package:flutter/material.dart';
import 'dart:async';
import 'package:local_auth/local_auth.dart'; // For fingerprint authentication
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For storing the secret number hash
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), _checkFirstTimeUser);
  }

  void _checkFirstTimeUser() async {
    const storage = FlutterSecureStorage();
    String? secretNumberHash = await storage.read(key: 'secretNumberHash');
    if (secretNumberHash == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SetupScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NumberPuzzleScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Puzzle Lock management',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int? _selectedSecretNumber;

  void _selectSecretNumber(int number) {
    setState(() {
      _selectedSecretNumber = number;
    });
  }

  void _confirmSecretNumber() async {
    if (_selectedSecretNumber != null) {
      const storage = FlutterSecureStorage();
      String secretHash = sha256.convert(utf8.encode(_selectedSecretNumber.toString())).toString();
      await storage.write(key: 'secretNumberHash', value: secretHash);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NumberPuzzleScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Select Your Secret Number:', style: TextStyle(fontSize: 24)),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
            itemCount: 15,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _selectSecretNumber(index + 1),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _selectedSecretNumber == index + 1 ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: _confirmSecretNumber,
            child: const Text("Confirm Secret Number"),
          ),
        ],
      ),
    );
  }
}

class NumberPuzzleScreen extends StatefulWidget {
  const NumberPuzzleScreen({super.key});

  @override
  _NumberPuzzleScreenState createState() => _NumberPuzzleScreenState();
}

class _NumberPuzzleScreenState extends State<NumberPuzzleScreen> {
  final List<int> _numbers = List.generate(15, (i) => i + 1)..add(0); // 1-15 and empty space
  bool _isTimerRunning = false;
  Timer? _timer;
  int _remainingTime = 300; // 5 minutes in seconds
  bool _isCooldown = false;
  final int _cooldownTime = 30; // 30 seconds cooldown
  final LocalAuthentication auth = LocalAuthentication();
  final storage = const FlutterSecureStorage();
  int? _secretNumber;

  @override
  void initState() {
    super.initState();
    _loadSecretNumber();
    _shuffleNumbers();
  }

  void _loadSecretNumber() async {
    String? secretNumberHash = await storage.read(key: 'secretNumberHash');
    if (secretNumberHash != null) {
      // In a real-world scenario, we'd never store the number directly, but for simulation:
      for (int i = 1; i <= 15; i++) {
        if (sha256.convert(utf8.encode(i.toString())).toString() == secretNumberHash) {
          _secretNumber = i;
          break;
        }
      }
    }
  }

  void _shuffleNumbers() {
    _numbers.shuffle(); // Randomly shuffle numbers
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _isTimerRunning = false;
          _triggerCooldown(); // Start cooldown when time runs out
        }
      });
    });
  }

  void _triggerCooldown() {
    setState(() {
      _isCooldown = true;
    });
    Timer(Duration(seconds: _cooldownTime), () {
      setState(() {
        _isCooldown = false;
        _remainingTime = 300; // Reset puzzle time after cooldown
        _shuffleNumbers(); // Reshuffle for a fresh attempt
      });
    });
  }

  bool _isSolved() {
    for (int i = 0; i < 15; i++) {
      if (_numbers[i] != i + 1) return false;
    }
    return true;
  }

  void _handleTileTap(int index) {
    setState(() {
      if (!_isTimerRunning) {
        _startTimer(); // Start timer when user begins arranging
      }
      // Logic to slide the numbers with the free space near
      if (_isSolved() && _numbers.indexOf(_secretNumber!) == 15) {
        // Puzzle solved and secret number moved to the final position
        print("System Unlocked!");
      }
    });
  }

  Future<void> _authenticateWithPassword() async {
    String? savedPassword = await storage.read(key: 'userPassword');
    if (savedPassword != null) {
      // Handle password input and validation here
    }
  }

  Future<void> _authenticateWithFingerprint() async {
    bool authenticated = await auth.authenticate(
      localizedReason: 'Authenticate to unlock',
      options: const AuthenticationOptions(
        biometricOnly: true,
      ),
    );
    if (authenticated) {
      print("Fingerprint Auth Successful");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          // The puzzle box and other UI elements go here...
        ],
      ),
    );
  }
}
