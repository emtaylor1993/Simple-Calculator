/*
 * MAIN CLASS
 * 
 * @author Emmanuel Taylor
 * 
 * @description
 *    This will be the core class for the Simple Calculator application. It
 *    provides functionality for basic and scientific calculations, expression
 *    parsing, theme management, memory operations, and historic tracking.
 * 
 * @dependencies
 *    - flutter: Core UI framework
 *    - audioplayers: Used for button sound effects
 *    - math_expressions: Used to parse and evaluate mathematical expressions
 *    - shared_preferences: Used to persist theme and calculation history
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isScientific = false;
  
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  final Duration _cooldownDuration = const Duration(milliseconds: 2000);

  List<String> get allButtons {
    return [
      // Regular calculator buttons
      'MC', 'MR', 'M+', 'M-',
      'AC/⌫', '+/-', '%', '÷',
      '7', '8', '9', '×',
      '4', '5', '6', '-',
      '1', '2', '3', '+',
      '', '0', '.', '=',

      // Scientific buttons come after
      if (_isScientific) ...scientificButtons,
    ];
  }

  final List<String> scientificButtons = [
    'sin', 'cos', 'tan', 'log',
    'ln', '√', 'x²', 'x!',
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

  void _saveToUndoStack() {
    if (_expression.isNotEmpty & (_undoStack.isEmpty || _undoStack.last != _expression)) {
      _undoStack.add(_expression);
      if (_undoStack.length > 100) _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_expression);
      _expression = _undoStack.removeLast();
      _result = '';
      _justEvaluated = false;
      setState(() {});
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_expression);
      _expression = _redoStack.removeLast();
      _result = '';
      _justEvaluated = false;
      setState(() {});
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
                      _showSnackBar('History Cleared', icon: Icons.delete, bgColor: Colors.green[400]);
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
                  : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _history.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Theme.of(context).dividerColor,
                      thickness: 1,
                      height: 12,
                    ),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _history[index],
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                      );
                    },
                  )
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
      if (value != 'Undo' && value != 'Redo') {
        _saveToUndoStack();
      }

      // Clear expression.
      if (value == 'AC/⌫') {
        if (_expression.isEmpty && _result.isEmpty) {
          _memory = 0.0;
          _undoStack.clear();
          _redoStack.clear();
          _clearHistory();
          _showSnackBar('Calculator Reset', icon: Icons.restart_alt_sharp, bgColor: Colors.green[400]);
        } else {
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
        }
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

      } else if (['sin', 'cos', 'tan', 'log', 'ln', '√', 'x²', 'x!'].contains(value)) {
        String wrapped = _expression.isEmpty ? '0' : _expression;

        switch (value) {
          case '√':
            _expression = 'sqrt($wrapped)';
            break;
          case 'x²':
            _expression = '($wrapped)^2';
            break;
          case 'x!':
            _expression = '($wrapped)!';
            break;
          default:
            _expression = '$value($wrapped)';
        }

        _justEvaluated = false;
        return;

      // Handles support for negative numbers.
      } else if (value == '+/-') {
        final match = RegExp(r'(\-?\(?\d*\.?\d+\)?)$').firstMatch(_expression);
        if (match != null) {
          final lastNumber = match.group(0)!;
          final start = match.start;
          final end = match.end;

          if (lastNumber == '0' || lastNumber == '-0') return;

          // Check if the number is already negated.
          if (lastNumber.startsWith('-(') && lastNumber.endsWith(')')) {
            // Remove the -(...) wrapper and shift back to positive.
            final unwrapped = lastNumber.substring(2, lastNumber.length - 1);
            _expression = _expression.replaceRange(start, end, unwrapped);
          } else if (lastNumber.startsWith('-')) {
            // Remove single minus.
            _expression = _expression.replaceRange(start, end, lastNumber.replaceFirst('-', ''));
          } else {
            // Add negation with parentheses.
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
      expr = expr.replaceAllMapped(RegExp(r'(?<!\d)\.(\d+)'), (match) => '0.${match[1]}');
      expr = expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('√', 'sqrt');

      // Convert percentages to their decimal equivalents (e.g., 20% → (20*0.01))
      expr = expr.replaceAllMapped(RegExp(r'(\d+(\.\d+)?)%'), (match) {
        final number = match.group(1);
        return '($number*0.01)';
      });

      ShuntingYardParser parser = ShuntingYardParser();
      Expression parsedExpression = parser.parse(expr);
      ContextModel context = ContextModel();
      double eval = parsedExpression.evaluate(EvaluationType.REAL, context);
      return eval.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    } catch (_) {
      return 'Invalid';
    }
  }

  Widget _buildDisplay(bool isMobile) {
    final expressionStyle = TextStyle(
      fontSize: isMobile ? 28 : 40,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).textTheme.bodyLarge!.color,
    );

    final resultColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final resultStyle = TextStyle(
      fontSize: isMobile ? 48 : 64,
      fontWeight: FontWeight.bold,
      color: resultColor,
    );

    String liveResult = '';
    bool isPreview = false;

    if (_expression.isNotEmpty && !_justEvaluated) {
      final preview = _evaluate(_expression);
      if (preview != 'Invalid') {
        liveResult = '= $preview';
        isPreview = true;
      }
    } else if (_result.isNotEmpty) {
      liveResult = _result;
      isPreview = false;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: isMobile ? 40 : 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _expression,
                style: expressionStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: isMobile ? 56 : 72,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                liveResult,
                style: resultStyle.copyWith(
                  color: isPreview ? resultColor.withAlpha((0.5 * 255).round()) : resultColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGrid(bool isMobile, BoxConstraints constraints) {
    final gridPadding = 16.0;
    final crossAxisCount = 4;
    final rowCount = _isScientific ? 9 : 7;
    final spacing = 8.0;

    final availableHeight = constraints.maxHeight - 220; // Display + spacing
    final buttonHeight = (availableHeight - ((rowCount - 1) * spacing)) / rowCount;
    final buttonWidth = (constraints.maxWidth - ((crossAxisCount - 1) * spacing) - gridPadding * 2) / crossAxisCount;
    final buttonsToShow = _isScientific ? allButtons : allButtons;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      child: SizedBox(
        key: ValueKey(_isScientific),
        height: availableHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            itemCount: buttonsToShow.length,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: buttonWidth / buttonHeight,
            ),
            itemBuilder: (context, index) {
              final button = buttonsToShow[index];
              final isMemory = ['MC', 'MR', 'M+', 'M-'].contains(button);
              final isOperator = ['÷', '×', '-', '+', '='].contains(button);
              final color = button == 'AC/⌫' ? Colors.red : isMemory ? Colors.teal.shade600 : isOperator ? Colors.orange : null;
              return _buildButton(button, color: color, isMobile: isMobile);
            },
          ),
        )
      ),
    );
  }

  Widget _buildButton(String text, {Color? color, bool isMobile = false}) {
    final String label = text == 'AC/⌫' ? (_expression.isEmpty && _result.isEmpty ? 'AC' : '⌫') : text;
    final double fontSize = _isScientific ? (isMobile ? 20 : 28) : (isMobile ? 24 : 32);

    return _AnimatedCalculatorButton(
      label: label,
      color: color ?? Colors.grey[850]!,
      onTap: () => _buttonPressed(text),
      fontSize: fontSize,
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
            icon: const Icon(Icons.undo),
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: Icon(_isScientific ? Icons.calculate : Icons.functions),
            onPressed: () {
              setState(() {
                _isScientific = !_isScientific;
              });
            },
            tooltip: 'Toggle Scientific Mode',
          ),
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
        HapticFeedback.lightImpact();
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