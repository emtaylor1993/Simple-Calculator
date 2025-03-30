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
 */

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:math_expressions/math_expressions.dart';

void main() => runApp(CalculatorApp());

// This class represents the root widget for the entire app.
class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: CalculatorHomePage(),
    );
  }
}

// Main stateful widget that holds the calculator logic and UI.
class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key});

  @override
  CalculatorHomePageState createState() => CalculatorHomePageState();
}

class CalculatorHomePageState extends State<CalculatorHomePage> {
  String _expression = '';  // User input.
  String _result = '';      // Result after pressing "=".
  bool _justEvaluated = false;

  // Button labels in order. Used to build button grid.
  final List<String> buttons = [
    '7', '8', '9', '÷',
    '4', '5', '6', '×',
    '1', '2', '3', '-',
    'C', '0', '.', '+',
    '⌫', '', '', '=',
  ];

  // Called when any button is tapped/pressed.
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
        } catch (e) {
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
            _expression = '0.'; // Start new decimal.
            _result = '';
            _justEvaluated = false;
          } else {
            _expression += value;
          }
        }
      } else {
        // If we just pressed = and now press a number, start fresh.
        if (_justEvaluated) {
          if (RegExp(r'^\d$').hasMatch(value)) {
            _expression = value; // New expression starts here.
            _result = '';
          } else if (['+', '-', '×', '÷'].contains(value)) {
            _expression = _result + value;
            _result = '';
          }
          _justEvaluated = false;
        } else {
          _expression += value;
        }
      }
    });
  }
  
  // Expression evaluator.
  String _evaluate(String expr) {
    try {
      // Replace all UI-friendly math symbols with true math symbols.
      String finalExpr = expr.replaceAll('×', '*').replaceAll('÷', '/');

      // Use math_expressions package to parse and evaluate.
      ShuntingYardParser parser = ShuntingYardParser();
      Expression parsedExpression = parser.parse(finalExpr);
      ContextModel context = ContextModel();

      double eval = parsedExpression.evaluate(EvaluationType.REAL, context);
      return eval.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    } catch (e) {
      return 'Invalid';
    }
  }

  // Constructs a single calculator button with animation and sound.
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display expression.
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  _expression,
                  style: TextStyle(fontSize: 94, color: Colors.grey[400]),
                ),
              ),

              // Display result.
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Text(
                  _result,
                  style: TextStyle(fontSize: 94, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              SizedBox(height: 20),

              // Grid of buttons.
              SizedBox(
                width: 640,
                height: 800,
                child: GridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: buttons.map((button) {
                    final isOperator = ['÷', '×', '-', '+', '='].contains(button);
                    final color = button == 'C' ? Colors.red : isOperator ? Colors.orange : null;
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

// Custom widget for animated, tappable calculator buttons.
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
  late AnimationController _scaleController;      // For scale-in animation.
  late AnimationController _flashController;      // For color flash.
  late Animation<Color?> _flashAnimation;         // Animates the button color.
  final AudioPlayer _audioPlayer = AudioPlayer(); // For tap sound.

  @override
  void initState() {
    super.initState();

    // Button press scale-in animation for a slight shrink.
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    // Flash-to-white animation controller.
    _flashController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    // Animate button color between original and a light gray.
    _flashAnimation = ColorTween(
      begin: widget.color,
      end: const Color.fromARGB(255, 184, 183, 183),
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOut,
    ));

    // Automatically reverse the flash after it's done.
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

  // When button is pressed.
  void _onTapDown(TapDownDetails details) {
    _scaleController.reverse();
    _flashController.forward(from: 0.0);
  }

  // When button is released.
  void _onTapUp(TapUpDetails details) {
    _scaleController.forward();
  }

  // Cancel animation if tap is cancelled.
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
                boxShadow: [
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
                    fontSize: 60,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Change to black for contrast on white flash
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
