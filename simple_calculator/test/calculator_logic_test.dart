/*
 * CALCULATOR LOGIC TEST CLASS
 * 
 * @author Emmanuel Taylor
 * 
 * @description
 *    This class is designed to test the functionality of the calculator
 *    logic.
 * 
 * @packages
 *    flutter_test
 *    simple_calculator
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calculator/calculator_logic.dart'; // adjust based on your actual app name

void main() {
  group('CalculatorLogic.evaluate', () {
    test('Basic Operations', () {
      expect(CalculatorLogic.evaluate('2+2'), '4');
      expect(CalculatorLogic.evaluate('5-3'), '2');
      expect(CalculatorLogic.evaluate('4×3'), '12');
      expect(CalculatorLogic.evaluate('8÷2'), '4');
    });

    test('Chained Operations', () {
      expect(CalculatorLogic.evaluate('2+3×4'), '14');
      expect(CalculatorLogic.evaluate('10-2×3'), '4');
      expect(CalculatorLogic.evaluate('8÷2+3'), '7');
    });

    test('Decimal Support', () {
      expect(CalculatorLogic.evaluate('3.5+1.2'), '4.7');
      expect(CalculatorLogic.evaluate('10÷4'), '2.5');
      expect(CalculatorLogic.evaluate('2.5×4'), '10');
      expect(CalculatorLogic.evaluate('5.0-0.25'), '4.75');
    });

    test('Invalid Expressions', () {
      expect(CalculatorLogic.evaluate('3..5+2'), 'Invalid');
      expect(CalculatorLogic.evaluate('+×2'), 'Invalid');
      expect(CalculatorLogic.evaluate(''), 'Invalid');
    });

    test('Long Expression', () {
      expect(CalculatorLogic.evaluate('2+3×4-5÷2+1.1×3'), '14.8');
    });
  });
}