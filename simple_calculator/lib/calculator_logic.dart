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
  static String evaluate(String expression) {
    try {
      final finalExpr = expression.replaceAll('×', '*').replaceAll('÷', '/');
      final parser = ShuntingYardParser();
      final exp = parser.parse(finalExpr);
      final context = ContextModel();
      final result = exp.evaluate(EvaluationType.REAL, context);

      return result.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    } catch (e) {
      return 'Invalid';
    }
  }
}