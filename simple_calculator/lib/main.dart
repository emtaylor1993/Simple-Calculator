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
  // Tracks the current theme mode from the system.
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();

    // Loads the saved theme on startup.
    _loadTheme();
  }

  /// Loads the theme preference from shared preferences.
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

  /// Toggles between light/dark mode and saves it.
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
  // Triggered when toggling the theme.
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
  @override
  void initState() {
    super.initState();

    // Load stored calculation history on app startup.
    _loadHistory();

    // Load stored memory value on app startup.
    _loadMemory();
  }

  String _expression = '';      // Current user expression input.
  String _result = '';          // Result after pressing '='.
  bool _justEvaluated = false;  // Prevents appending after evaluation.
  List<String> _history = [];   // Stores recent calculations.
  double? _memory = 0.0;         // Stores values in memory for M+, M-, MR, MC.
  DateTime? _lastSnackBarTime;
  
  final Duration _cooldownDuration = const Duration(milliseconds: 2000);
  final List<String> buttons = [
    'MC', 'MR', 'M+', 'M-',
    'C', '+/-', '%', '÷',
    '7', '8', '9', '×',
    '4', '5', '6', '-',
    '1', '2', '3', '+',
    '⌫', '0', '.', '=',
  ];

  /// Load saved history from shared preferences.
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('calc_history') ?? [];
    });
  }

  /// Save a new expression and result to history.
  Future<void> _saveToHistory(String expression, String result) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = '$expression = $result';
    setState(() {
      _history.insert(0, entry);
      if (_history.length > 20) {
        _history = _history.sublist(0, 20);
      }
    });
    await prefs.setStringList('calc_history', _history);
  }

  /// Clear all stored history.
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('calc_history');
    setState(() {
      _history.clear();
    });
  }

  Future<void> _loadMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMemory = prefs.getDouble('memory_value');
    setState(() {
      _memory = storedMemory;
    });
  }

  Future<void> _saveMemory() async {
    final prefs = await SharedPreferences.getInstance();
    if (_memory != null) {
      await prefs.setDouble('memory_value', _memory!);
    } else {
      await prefs.remove('memory_value');
    }
  }

  /// Shows the history as a sliding panel.
  void _showHistoryPopup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Calculation History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      _clearHistory();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete),
                    tooltip: 'Clear History',
                    iconSize: 28,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _history.isEmpty
                  ? Center(child: Text(
                    'No History Yet', 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    )))
                  : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_history[index], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {IconData icon = Icons.info, Color? bgColor}) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = bgColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);

    if (_lastSnackBarTime != null && now.difference(_lastSnackBarTime!) < _cooldownDuration) {
      return;
    }

    _lastSnackBarTime = now;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(icon, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles all button pressing logic.
  void _buttonPressed(String value) {
    setState(() {

      // Clear expression.
      if (value == 'C') {
        _expression = '';
        _result = '';
        _justEvaluated = false;

      // Evaluate current expression.
      } else if (value == '=') {
        try {
          final evaluated = _evaluate(_expression);
          if (evaluated != 'Invalid') {
            _result = evaluated;
            _saveToHistory(_expression, evaluated);
            _justEvaluated = true;
          } else {
            _result = 'Invalid';
          }
        } catch (_) {
          _result = 'Error';
        }

      // Backspaces character.
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }

      // Handles decimal point functionality.
      } else if (value == '.') {
        final parts = _expression.split(RegExp(r'[+\-×÷()]'));
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

      // Handles support for negative numbers.
      } else if (value == '+/-') {
        final match = RegExp(r'(-?\d*\.?\d+)$').firstMatch(_expression);
        if (match != null) {
          final lastNumber = match.group(0)!;
          final start = match.start;
          final end = match.end;
          if (lastNumber.replaceAll(RegExp(r'[().]'), '') == '0') return;
          if (lastNumber.startsWith('-(')) {
            _expression = _expression.replaceRange(start, end, lastNumber.substring(2, lastNumber.length - 1));
          } else if (lastNumber.startsWith('-')) {
            _expression = _expression.replaceRange(start, end, lastNumber.replaceFirst('-', ''));
          } else {
            _expression = _expression.replaceRange(start, end, '-($lastNumber)');
          }
        }

      // Handles clearing memory.
      } else if (value == 'MC') {
        _memory = 0.0;
        _saveMemory();
        _showSnackBar('Memory Cleared', icon: Icons.delete);

      // Handles appending memory value to the current expression.
      } else if (value == 'MR') {
        _expression += _memory.toString().replaceAll(RegExp(r'\.0$'), '');
        _showSnackBar('Recalled from Memory: ${_memory!.toString()}');

      // Handles adding the result of the current expression to memory.
      } else if (value == 'M+') {
        final current = double.tryParse(_result);
        if (current != null) {
          _memory = (_memory ?? 0) + current;
          _saveMemory();
          _showSnackBar('Added ${current.toString()} to Memory', icon: Icons.copy, bgColor: Colors.green[400]);
        }

      // Handles subtracting the result of the current expression to memory.
      } else if (value == 'M-') {
        final current = double.tryParse(_result);
        if (current != null) {
          _memory = (_memory ?? 0) - current;
          _saveMemory();
          _showSnackBar('Subtracted ${current.toString()} from Memory', icon: Icons.delete, bgColor: Colors.red[400]);
        }

      // Default input handling.
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

          if (last == '0' && value == '0') return;
          if (last == '0' && RegExp(r'^[1-9]$').hasMatch(value)) {
            _expression = _expression.substring(0, _expression.length - 1) + value;
          } else {
            _expression += value;
          }
        }
      }
    });
  }

  /// Evaluates mathematical string expressions.
  String _evaluate(String expr) {
    try {
      String finalExpr = expr.replaceAll('×', '*').replaceAll('÷', '/');

      // Convert percentages to their decimal equivalents (e.g., 20% → (20*0.01))
      finalExpr = finalExpr.replaceAllMapped(RegExp(r'(\d+(\.\d+)?)%'), (match) {
        final number = match.group(1);
        return '($number*0.01)';
      });

      ShuntingYardParser parser = ShuntingYardParser();
      Expression parsedExpression = parser.parse(finalExpr);
      ContextModel context = ContextModel();
      double eval = parsedExpression.evaluate(EvaluationType.REAL, context);
      return eval.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    } catch (_) {
      return 'Invalid';
    }
  }

  Widget _buildDisplay(bool isMobile) {
    final expressionStyle = TextStyle(
      fontSize: isMobile ? 36 : 60,
      color: Theme.of(context).textTheme.bodyLarge!.color,
    );
    final resultStyle = expressionStyle.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(_expression, style: expressionStyle),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(_result, style: resultStyle),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonGrid(bool isMobile, BoxConstraints constraints) {
    final gridPadding = 16.0;
    final crossAxisCount = 4;
    final rowCount = 7;
    final spacing = 8.0;

    final availableHeight = constraints.maxHeight - 220; // Display + spacing
    final buttonHeight = (availableHeight - ((rowCount - 1) * spacing)) / rowCount;
    final buttonWidth = (constraints.maxWidth - ((crossAxisCount - 1) * spacing) - gridPadding * 2) / crossAxisCount;

    return SizedBox(
      height: availableHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          itemCount: buttons.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: buttonWidth / buttonHeight,
          ),
          itemBuilder: (context, index) {
            final button = buttons[index];
            final isMemory = ['MC', 'MR', 'M+', 'M-'].contains(button);
            final isOperator = ['÷', '×', '-', '+', '='].contains(button);
            final color = button == 'C' ? Colors.red : isMemory ? Colors.teal.shade600 : isOperator ? Colors.orange : null;
            return _buildButton(button, color: color, isMobile: isMobile);
          },
        ),
      ),
    );
  }

  Widget _buildButton(String text, {Color? color, bool isMobile = false}) {
    return _AnimatedCalculatorButton(
      label: text,
      color: color ?? Colors.grey[850]!,
      onTap: () => _buttonPressed(text),
      fontSize: isMobile ? 28 : 60,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryPopup,
            tooltip: 'Show History',
          ),
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.dark_mode),
            tooltip: 'Toggle Theme',
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildDisplay(isMobile),
                  const SizedBox(height: 12),
                  _buildButtonGrid(isMobile, constraints),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedCalculatorButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double fontSize;

  const _AnimatedCalculatorButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.fontSize = 60,
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
                  style: TextStyle(
                    fontSize: widget.fontSize,
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