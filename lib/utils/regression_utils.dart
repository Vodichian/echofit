import 'package:fl_chart/fl_chart.dart';

class RegressionResult {
  final double slope;
  final double intercept;

  RegressionResult(this.slope, this.intercept);

  double predict(double x) => slope * x + intercept;
}

RegressionResult calculateLinearRegression(List<FlSpot> points) {
  if (points.length < 2) return RegressionResult(0, 0);

  double sumX = 0;
  double sumY = 0;
  double sumXY = 0;
  double sumXX = 0;
  int n = points.length;

  for (var point in points) {
    sumX += point.x;
    sumY += point.y;
    sumXY += point.x * point.y;
    sumXX += point.x * point.x;
  }

  double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  double intercept = (sumY - slope * sumX) / n;

  return RegressionResult(slope, intercept);
}
