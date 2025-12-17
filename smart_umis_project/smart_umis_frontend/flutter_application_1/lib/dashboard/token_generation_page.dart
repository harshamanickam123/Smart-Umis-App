import 'package:flutter/material.dart';
import 'dart:async';

class TokenGenerationPage extends StatefulWidget {
  const TokenGenerationPage({super.key});

  @override
  State<TokenGenerationPage> createState() => _TokenGenerationPageState();
}

class ActiveToken {
  final int tokenNumber;
  final DateTime createdAt;
  Timer? timer;
  int remainingSeconds;

  ActiveToken({
    required this.tokenNumber,
    required this.createdAt,
    this.timer,
    this.remainingSeconds = 60,
  });
}

class _TokenGenerationPageState extends State<TokenGenerationPage> {
  static int _nextTokenNumber = 1;
  static final List<int> _usedTokens = [];
  static final List<ActiveToken> _activeTokens = [];

  int? myCurrentToken;
  Timer? myTokenTimer;
  int myRemainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    // Clean up expired tokens on init
    _cleanupExpiredTokens();
  }

  void _cleanupExpiredTokens() {
    final now = DateTime.now();
    _activeTokens.removeWhere((token) {
      final elapsed = now.difference(token.createdAt).inSeconds;
      if (elapsed >= 60) {
        token.timer?.cancel();
        return true;
      }
      return false;
    });
  }

  void generateToken() {
    if (myCurrentToken != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You already have an active token. Please wait or confirm usage.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      myCurrentToken = _nextTokenNumber;
      _nextTokenNumber++;
      myRemainingSeconds = 60;
    });

    // Create active token entry
    final activeToken = ActiveToken(
      tokenNumber: myCurrentToken!,
      createdAt: DateTime.now(),
      remainingSeconds: 60,
    );
    _activeTokens.add(activeToken);

    // Start countdown timer
    myTokenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        myRemainingSeconds--;
        activeToken.remainingSeconds = myRemainingSeconds;
      });

      if (myRemainingSeconds <= 0) {
        timer.cancel();
        showTokenConfirmationDialog();
      }
    });
  }

  void showTokenConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Token Confirmation'),
          content: Text('Did you use Token #$myCurrentToken?'),
          actions: [
            TextButton(
              onPressed: () {
                // Token was not used, remove from active tokens
                _activeTokens
                    .removeWhere((t) => t.tokenNumber == myCurrentToken);
                setState(() {
                  myCurrentToken = null;
                  myRemainingSeconds = 60;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Token expired and removed.'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('NO, Not Used'),
            ),
            TextButton(
              onPressed: () {
                // Token was used, mark as used
                _activeTokens
                    .removeWhere((t) => t.tokenNumber == myCurrentToken);
                setState(() {
                  _usedTokens.add(myCurrentToken!);
                  myCurrentToken = null;
                  myRemainingSeconds = 60;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Token marked as used. Ready for next token.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('YES, Used'),
            ),
          ],
        );
      },
    );
  }

  void cancelToken() {
    myTokenTimer?.cancel();
    _activeTokens.removeWhere((t) => t.tokenNumber == myCurrentToken);
    setState(() {
      myCurrentToken = null;
      myRemainingSeconds = 60;
    });
  }

  @override
  void dispose() {
    myTokenTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _cleanupExpiredTokens();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Generation'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.generating_tokens,
                      size: 60,
                      color: Colors.green[700],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Generate Access Token',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Multiple users can generate tokens simultaneously',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // My Current Token Display
            if (myCurrentToken != null)
              Card(
                elevation: 6,
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.green[700]!, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      const Text(
                        'Your Token',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '#$myCurrentToken',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Expires in: $myRemainingSeconds seconds',
                            style: TextStyle(
                              fontSize: 16,
                              color: myRemainingSeconds <= 10
                                  ? Colors.red[700]
                                  : Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: myRemainingSeconds / 60,
                        backgroundColor: Colors.grey[300],
                        color: myRemainingSeconds <= 10
                            ? Colors.red
                            : Colors.green[700],
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Generate Button
            ElevatedButton.icon(
              onPressed: myCurrentToken != null ? null : generateToken,
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: const Text(
                'Generate New Token',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),

            const SizedBox(height: 10),

            // Cancel Button
            if (myCurrentToken != null)
              OutlinedButton.icon(
                onPressed: cancelToken,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text(
                  'Cancel My Token',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[700]!, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // All Active Tokens Display
            if (_activeTokens.isNotEmpty)
              Card(
                elevation: 4,
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.blue[700]),
                          const SizedBox(width: 10),
                          const Text(
                            'Currently Active Tokens',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ..._activeTokens.map((token) {
                        final isMyToken = token.tokenNumber == myCurrentToken;
                        final elapsed = DateTime.now()
                            .difference(token.createdAt)
                            .inSeconds;
                        final remaining = 60 - elapsed;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isMyToken ? Colors.green[100] : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isMyToken
                                  ? Colors.green[700]!
                                  : Colors.blue[300]!,
                              width: isMyToken ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isMyToken
                                    ? Colors.green[700]
                                    : Colors.blue[700],
                                child: Text(
                                  '#${token.tokenNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Token #${token.tokenNumber}${isMyToken ? " (You)" : ""}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: remaining / 60,
                                      backgroundColor: Colors.grey[300],
                                      color: remaining <= 10
                                          ? Colors.red
                                          : Colors.blue,
                                      minHeight: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${remaining}s',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: remaining <= 10
                                      ? Colors.red[700]
                                      : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Statistics Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Next Token',
                          _nextTokenNumber.toString(),
                          Icons.upcoming,
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Active Now',
                          _activeTokens.length.toString(),
                          Icons.people,
                          Colors.orange,
                        ),
                        _buildStatItem(
                          'Total Used',
                          _usedTokens.length.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Used Tokens History
            if (_usedTokens.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Used Tokens History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _usedTokens.map((token) {
                          return Chip(
                            label: Text('#$token'),
                            backgroundColor: Colors.green[100],
                            avatar: const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Colors.green,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
