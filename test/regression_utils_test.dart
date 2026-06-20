import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:echofit/utils/regression_utils.dart';

void main() {
  test('Linear regression calculation', () {
    final points = [
      const FlSpot(0, 10),
      const FlSpot(1, 12),
      const FlSpot(2, 14),
      const FlSpot(3, 16),
    ];

    final result = calculateLinearRegression(points);

    expect(result.slope, closeTo(2.0, 0.001));
    expect(result.intercept, closeTo(10.0, 0.001));
    expect(result.predict(4), closeTo(18.0, 0.001));
  });

  test('Regression with less than 2 points returns zero result', () {
    final points = [const FlSpot(0, 10)];
    final result = calculateLinearRegression(points);
    expect(result.slope, 0);
    expect(result.intercept, 0);
  });
}
