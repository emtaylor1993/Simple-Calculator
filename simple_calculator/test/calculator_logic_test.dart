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
import 'package:simple_calculator/calculator_logic.dart';

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

  group('CalculatorLogic.input', () {
    late CalculatorLogic logic;

    setUp(() {
      logic = CalculatorLogic();
    });

    test('Prevent Double 0 (00)', () {
      logic.press('0');
      logic.press('0');
      expect(logic.expression, '0');
    });

    test('Allow Decimal After 0', () {
      logic.press('0');
      logic.press('.');
      logic.press('5');
      expect(logic.expression, '0.5');
    });

    test('Prevents Leading Zeroes Like 03', () {
      logic.press('0');
      logic.press('3');
      expect(logic.expression, '3');
    });

    test('Toggles Negative Sign Correctly', () {
      logic.press('4');
      logic.press('+/-');
      expect(logic.expression, '-(4)');
    });

    test('Toggles Negative Sign Back to Positive', () {
      logic.press('7');
      logic.press('+/-');
      logic.press('+/-');
      expect(logic.expression, '7');
    });

    test('Does Not Toggle Negative For 0', () {
      logic.press('0');
      logic.press('+/-');
      expect(logic.expression, '0');
    });

    test('Chaining Expressions After =', () {
      logic.press('1');
      logic.press('+');
      logic.press('2');
      logic.press('=');
      expect(logic.result, '3');

      logic.press('+');
      logic.press('4');
      logic.press('=');
      expect(logic.result, '7');
    });

    test('Backspace Deletes Characters', () {
      logic.press('1');
      logic.press('2');
      logic.press('3');
      logic.press('⌫');
      expect(logic.expression, '12');
    });

    test('Clears All On C', () {
      logic.press('9');
      logic.press('+');
      logic.press('1');
      logic.press('C');
      expect(logic.expression, '');
      expect(logic.result, '');
    });

    test('Decimal In Multiple Sections', () {
      logic.press('1');
      logic.press('.');
      logic.press('5');
      logic.press('+');
      logic.press('2');
      logic.press('.');
      logic.press('5');
      logic.press('=');
      expect(logic.result, '4');
    });
  });
}