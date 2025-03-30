/*
 * MAIN CALCULATOR CLASS
 * 
 * @author Emmanuel Taylor
 * 
 * @description
 *    This is a simple calculator app that is designed to perform basic operations,
 *    and display some of Flutter's cool functionality
 * 
 * @packages
 *    flutter
 *    audioplayer
 *    math_expressions
 *    shared_preferences
 */

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = {
        'light': ThemeMode.light,
        'dark': ThemeMode.dark,
        'system': ThemeMode.system,
      }[themeString]!;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        prefs.setString('theme_mode', 'dark');
      } else {
        _themeMode = ThemeMode.light;
        prefs.setString('theme_mode', 'light');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: CalculatorHomePage(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const CalculatorHomePage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  CalculatorHomePageState createState() => CalculatorHomePageState();
}

class CalculatorHomePageState extends State<CalculatorHomePage> {
  String _expression = '';
  String _result = '';
  bool _justEvaluated = false;

  final List<String> buttons = [
    '7', '8', '9', '÷',
    '4', '5', '6', '×',
    '1', '2', '3', '-',
    'C', '0', '.', '+',
    '⌫', '(', ')', '=',
    '+/-', '', '', '',
  ];

  String _cleanDisplay(String expr) {
    return expr.replaceAll('--', '+').replaceAll('-(-', '+(');
  }

  void _buttonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
        _justEvaluated = false;
      } else if (value == '=') {
        try {
          final evaluated = _evaluate(_expression);
          if (evaluated != 'Invalid') {
            _result = evaluated;
            _justEvaluated = true;
          } else {
            _result = 'Invalid';
          }
        } catch (_) {
          _result = 'Error';
        }
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '.') {
        final parts = _expression.split(RegExp(r'[+\-×÷]'));
        final lastPart = parts.isNotEmpty ? parts.last : '';
        if (!lastPart.contains('.')) {
          if (_justEvaluated) {
            _expression = '0.';
            _result = '';
            _justEvaluated = false;
          } else {
            _expression += value;
          }
        }
      } else if (value == '+/-') {
        // Find last number and togge its sign.
        final match = RegExp(r'(\(?-?\d*\.?\d+\)?)$').firstMatch(_expression);
        if (match != null) {
          final lastNumber = match.group(0)!;
          final start = match.start;
          final end = match.end;

          // Don't allow toggling zero
          if (lastNumber.replaceAll(RegExp(r'[().]'), '') == '0') return;

          // Toggle: -(x) → x, x → -(x)
          final toggled = lastNumber.startsWith('-(') && lastNumber.endsWith(')')
              ? lastNumber.substring(2, lastNumber.length - 1)  // Remove wrapping
              : '-(${lastNumber.replaceAll('(', '').replaceAll(')', '')})'; // Clean wrap

          _expression = _expression.replaceRange(start, end, toggled);
        }
      } else {
        if (_justEvaluated) {
          if (RegExp(r'^\d$').hasMatch(value) || value == '.') {
            _expression = value;
            _result = '';
          } else if (['+', '-', '×', '÷', '(', ')'].contains(value)) {
            _expression = _result + value;
            _result = '';
          }
          _justEvaluated = false;
        } else {
          final parts = _expression.split(RegExp(r'[+\-×÷()]'));
          final last = parts.isNotEmpty ? parts.last : '';

          // Handle 0 separately.
          if (value == '0') {
            if (last == '0') return; // Prevent double 0.
          }

          // Handle invalid leading 0s like 03.
          if (last.startsWith('0') && !last.contains('.') && last.length == 1 && RegExp(r'^[1-9]$').hasMatch(value)) {
            _expression = _expression.substring(0, _expression.length - 1) + value;
          } else {
            _expression += value;
          }
        }
      }
    });
  }

  String _evaluate(String expr) {
    try {
      String finalExpr = expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('--', '+').replaceAll('-(-', '+(');
      ShuntingYardParser parser = ShuntingYardParser();
      Expression parsedExpression = parser.parse(finalExpr);
      ContextModel context = ContextModel();
      double eval = parsedExpression.evaluate(EvaluationType.REAL, context);
      return eval.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    } catch (_) {
      return 'Invalid';
    }
  }

  Widget _buildButton(String text, {Color? color}) {
    return _AnimatedCalculatorButton(
      label: text,
      color: color ?? Colors.grey[850]!,
      onTap: () => _buttonPressed(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.dark_mode),
            tooltip: 'Toggle Theme',
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  _cleanDisplay(_expression),
                  style: TextStyle(fontSize: 60, color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Text(
                  _result,
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 600,
                height: 960,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: buttons.map((button) {
                    final isOperator = ['÷', '×', '-', '+', '='].contains(button);
                    final color = button == 'C'
                        ? Colors.red
                        : isOperator
                            ? Colors.orange
                            : null;
                    return _buildButton(button, color: color);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCalculatorButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedCalculatorButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedCalculatorButton> createState() => _AnimatedCalculatorButtonState();
}

class _AnimatedCalculatorButtonState extends State<_AnimatedCalculatorButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _flashController;
  late Animation<Color?> _flashAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _flashAnimation = ColorTween(
      begin: widget.color,
      end: const Color.fromARGB(255, 184, 183, 183),
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOut,
    ));

    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.reverse();
    _flashController.forward(from: 0.0);
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.forward();
  }

  void _onTapCancel() {
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _audioPlayer.play(AssetSource('sounds/click.wav'));
        widget.onTap();
      },
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleController,
        child: AnimatedBuilder(
          animation: _flashAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: _flashAnimation.value,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
