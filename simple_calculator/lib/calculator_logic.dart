/*
 * CALCULATOR LOGIC CLASS
 * 
 * @author Emmanuel Taylor
 * 
 * @description
 *    This class extracts the calculator logic so that we can run unit tests
 *    on them without the complexities of the UI.
 * 
 * @packages
 *    flutter
 *    cupertino_icons
 *    audioplayer
 */

import 'package:math_expressions/math_expressions.dart';

class CalculatorLogic {
  String expression = '';
  String result = '';
  bool justEvaluated = false;

  /// Evaluates the current expression string.
  static String evaluate(String expression) {
    try {
      final finalExpr = expression.replaceAll('×', '*').replaceAll('÷', '/');
      final parser = ShuntingYardParser();
      final exp = parser.parse(finalExpr);
      final context = ContextModel();
      final result = exp.evaluate(EvaluationType.REAL, context);
      return result.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    } catch (_) {
      return 'Invalid';
    }
  }

  /// Handles any button press including numbers, operators, and special keys.
  void press(String value) {
    if (value == 'C') {
      expression = '';
      result = '';
      justEvaluated = false;
    } else if (value == '=') {
      result = evaluate(expression);
      justEvaluated = true;
    } else if (value == '⌫') {
      if (expression.isNotEmpty) {
        expression = expression.substring(0, expression.length - 1);
      }
    } else if (value == '.') {
      final parts = expression.split(RegExp(r'[+\-×÷()]'));
      final last = parts.isNotEmpty ? parts.last : '';
      if (!last.contains('.')) {
        if (justEvaluated) {
          expression = '0.';
          result = '';
          justEvaluated = false;
        } else {
          expression += value;
        }
      }
    } else if (value == '+/-') {
      // Find last number and togge its sign.
      final match = RegExp(r'(-?\(?\d*\.?\d+\)?)$').firstMatch(expression);
      if (match != null) {
        final lastNumber = match.group(0)!;
        final start = match.start;
        final end = match.end;

        // Avoid toggling if it's just 0 or -(0).
        if (lastNumber.replaceAll(RegExp(r'[().]'), '') == '0') return;

        final toggled = lastNumber.startsWith('-(') && lastNumber.endsWith(')') ? lastNumber.substring(2, lastNumber.length - 1) : lastNumber.startsWith('-') ? lastNumber.replaceFirst('-', '') : '-($lastNumber)';
        expression = expression.replaceRange(start, end, toggled);
      }
    } else {
      // Handle input after pressing "="
      if (justEvaluated) {
        if (RegExp(r'^\d$').hasMatch(value) || value == '.') {
          expression = value;
          result = '';
        } else if (['+', '-', '×', '÷', '(', ')'].contains(value)) {
          expression = result + value;
          result = '';
        }
        justEvaluated = false;
      } else {
        final parts = expression.split(RegExp(r'[+\-×÷()]'));
        final last = parts.isNotEmpty ? parts.last : '';

        // Prevent duplicate leading zeros
        if (value == '0') {
          if (last == '0') return;
        }

        // Prevent leading zeros like 03
        if (last.startsWith('0') &&
            !last.contains('.') &&
            last.length == 1 &&
            RegExp(r'^[1-9]$').hasMatch(value)) {
          expression = expression.substring(0, expression.length - 1) + value;
        } else {
          expression += value;
        }
      }
    }
  }
}