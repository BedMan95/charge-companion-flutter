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

  const ChargingMetrics({
    required this.powerInKw,
    required this.actualPowerToBatteryKw,
    required this.timeToChargeHours,
    required this.totalCost,
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
    final actualPowerToBatteryKw =
        isCharging ? powerInKw * chargingEfficiency : 0.0;
    final currentPercent = persenRealtime;
    final deltaPersenRealtime =
        max(0.0, (persenTarget - currentPercent) / 100.0);
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
        final energiDcDibutuhkanRealtimeKwh =
            effectiveBatteryKWh * deltaPersenRealtime;
        timeToChargeHours =
            energiDcDibutuhkanRealtimeKwh / actualPowerToBatteryKw;

        if (persenTarget > taperStartPercent) {
          final trickleStartPercent = max(taperStartPercent, currentPercent);
          final trickleDelta =
              max(0.0, (persenTarget - trickleStartPercent) / 100.0);
          final trickleEnergyKwh = effectiveBatteryKWh * trickleDelta;
          final trickleBaseTime = trickleEnergyKwh / actualPowerToBatteryKw;
          timeToChargeHours += trickleBaseTime * 0.5;
        }
      }
    }

    final totalEnergiAc0100Kwh =
        calibratedWallEnergyFullKWh ?? (batteryCapacity / chargingEfficiency);
    final totalCost =
        totalEnergiAc0100Kwh * deltaPersenTotal * electricityCostPerKWh;

    return ChargingMetrics(
      powerInKw: powerInKw,
      actualPowerToBatteryKw: actualPowerToBatteryKw,
      timeToChargeHours: timeToChargeHours,
      totalCost: totalCost,
    );
  }
}
