class QueueInput {
  final int serviceCount;
  final double avgServiceTime;
  final double arrivalRate;
  final String timeOfDay;

  QueueInput({
    required this.serviceCount,
    required this.avgServiceTime,
    required this.arrivalRate,
    required this.timeOfDay,
  });
}

class PredictionResult {
  final double predictedQueueLength;
  final double avgWaitTime;
  final double utilization;
  final double confidence;

  PredictionResult({
    required this.predictedQueueLength,
    required this.avgWaitTime,
    required this.utilization,
    required this.confidence,
  });
}

class QueuePredictionService {
  Future<PredictionResult> predictQueueLength(QueueInput input) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final serviceRate = 1.0 / input.avgServiceTime;
    final totalServiceRate = serviceRate * input.serviceCount;
    final utilization = input.arrivalRate / totalServiceRate;

    double predictedQueueLength;
    double avgWaitTime;
    double confidence;

    if (utilization >= 1.0) {
      predictedQueueLength = double.infinity;
      avgWaitTime = double.infinity;
      confidence = 0.95;
    } else {
      predictedQueueLength = (input.arrivalRate * input.arrivalRate) /
          (totalServiceRate * (totalServiceRate - input.arrivalRate));
      
      avgWaitTime = input.arrivalRate /
          (totalServiceRate * (totalServiceRate - input.arrivalRate));

      final hour = _parseHour(input.timeOfDay);
      confidence = _calculateConfidence(hour, utilization);
    }

    return PredictionResult(
      predictedQueueLength: predictedQueueLength.isFinite ? predictedQueueLength : 100.0,
      avgWaitTime: avgWaitTime.isFinite ? avgWaitTime : 60.0,
      utilization: utilization.clamp(0.0, 1.0),
      confidence: confidence,
    );
  }

  int _parseHour(String timeOfDay) {
    try {
      final parts = timeOfDay.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]);
      }
    } catch (e) {
      return 12;
    }
    return 12;
  }

  double _calculateConfidence(int hour, double utilization) {
    double baseConfidence = 0.85;

    if (hour >= 9 && hour <= 11) {
      baseConfidence += 0.10;
    } else if (hour >= 12 && hour <= 14) {
      baseConfidence += 0.05;
    } else if (hour >= 17 && hour <= 19) {
      baseConfidence += 0.08;
    } else if (hour >= 0 && hour <= 6) {
      baseConfidence -= 0.15;
    }

    if (utilization > 0.8) {
      baseConfidence -= 0.10;
    } else if (utilization < 0.3) {
      baseConfidence -= 0.05;
    }

    return baseConfidence.clamp(0.5, 0.99);
  }
}
