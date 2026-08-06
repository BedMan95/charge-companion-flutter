import 'dart:math';

class ChargingCalibrationProfile {
  final double usableBatteryKWh;
  final double wallEnergyFullKWh;
  final double fullChargeHours;
  final double taperStartPercent;

  const ChargingCalibrationProfile({
    required this.usableBatteryKWh,
    required this.wallEnergyFullKWh,
    required this.fullChargeHours,
    required this.taperStartPercent,
  });
}

class ChargingMetrics {
  final double powerInKw;
  final double actualPowerToBatteryKw;
  final double timeToChargeHours;
  final double totalCost;
  final double chargingEfficiency;

  const ChargingMetrics({
    required this.powerInKw,
    required this.actualPowerToBatteryKw,
    required this.timeToChargeHours,
    required this.totalCost,
    required this.chargingEfficiency,
  });
}

class ChargingCalculator {
  static ChargingMetrics calculateMetrics({
    required double currentPowerConsumption,
    required double batteryCapacity,
    required double chargingEfficiency,
    required double electricityCostPerKWh,
    required double persenAwal,
    required double persenTarget,
    required double persenRealtime,
    required bool isCharging,
    ChargingCalibrationProfile? calibration,
  }) {
    final powerInKw = currentPowerConsumption / 1000.0;

    // Dynamic efficiency based on SLA voltage curve
    // SLA 72V nominal: ~63V empty to ~84V full
    // As voltage increases and power drops in CV, efficiency of charger changes.
    // For now we use the base efficiency provided, but ensure power scaling is correct.
    final dynamicEfficiency = chargingEfficiency;

    final actualPowerToBatteryKw =
        isCharging ? powerInKw * dynamicEfficiency : 0.0;
    final currentPercent = persenRealtime;
    final deltaPersenTotal = max(0.0, (persenTarget - persenAwal) / 100.0);

    final effectiveBatteryKWh =
        calibration?.usableBatteryKWh ?? batteryCapacity;
    final taperStartPercent = calibration?.taperStartPercent ?? 80.0;
    final calibratedWallEnergyFullKWh = calibration?.wallEnergyFullKWh;
    final calibratedFullChargeHours = calibration?.fullChargeHours;

    double timeToChargeHours = 0.0;
    if (isCharging && actualPowerToBatteryKw > 0) {
      if (calibration != null &&
          persenAwal == 0 &&
          persenRealtime == 0 &&
          persenTarget == 100 &&
          calibratedFullChargeHours != null) {
        timeToChargeHours = calibratedFullChargeHours;
      } else {
        // Minimum power assumption to prevent infinite time
        double powerForEstimate = max(actualPowerToBatteryKw, 0.5 * dynamicEfficiency);

        // Time for CC phase (below taper start)
        if (currentPercent < taperStartPercent) {
          final ccEndPercent = min(persenTarget, taperStartPercent);
          final ccDelta = max(0.0, (ccEndPercent - currentPercent) / 100.0);
          final ccEnergyKwh = effectiveBatteryKWh * ccDelta;
          timeToChargeHours += ccEnergyKwh / powerForEstimate;
        }

        // Time for CV phase (SLA taper) using numerical integration
        if (persenTarget > taperStartPercent) {
          final cvStartPercent = max(taperStartPercent, currentPercent);
          if (cvStartPercent < persenTarget) {
            final steps = (persenTarget - cvStartPercent).ceil();
            double cvTime = 0.0;

            for (int i = 0; i < steps; i++) {
              final stepSoC = cvStartPercent + i;
              // Simulate SLA CV taper: power drops linearly from max at 80% to 10% of max at 100%
              // Normalized SoC in CV phase: 0.0 at 80%, 1.0 at 100%
              final normalizedCVSoC = (stepSoC - taperStartPercent) / (100.0 - taperStartPercent);
              // Power factor drops from 1.0 down to 0.1
              final powerFactor = 1.0 - (0.9 * normalizedCVSoC);

              final stepPower = max(powerForEstimate * powerFactor, 0.1 * dynamicEfficiency);
              final stepEnergyKwh = effectiveBatteryKWh * (1.0 / 100.0);

              cvTime += stepEnergyKwh / stepPower;
            }
            timeToChargeHours += cvTime;
          }
        }
      }
    }

    final totalEnergiAc0100Kwh =
        calibratedWallEnergyFullKWh ?? (batteryCapacity / dynamicEfficiency);
    final totalCost =
        totalEnergiAc0100Kwh * deltaPersenTotal * electricityCostPerKWh;

    return ChargingMetrics(
      powerInKw: powerInKw,
      actualPowerToBatteryKw: actualPowerToBatteryKw,
      timeToChargeHours: timeToChargeHours,
      totalCost: totalCost,
      chargingEfficiency: dynamicEfficiency,
    );
  }
}
