import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/charging_session_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tuya_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/charging_calculator.dart';

final metricsProvider = Provider<ChargingMetrics>((ref) {
  final tuyaStatus = ref.watch(tuyaStatusProvider).value ?? [];
  final sessionState = ref.watch(chargingSessionProvider);
  final settingsState = ref.watch(settingsProvider);
  final activeVehicle = ref.watch(activeVehicleProvider);

  final relayStatus = tuyaStatus.firstWhere(
      (s) => s['code'] == 'switch_1',
      orElse: () => {'value': false})['value'];

  final curPower = tuyaStatus.firstWhere(
      (s) => s['code'] == 'cur_power',
      orElse: () => {'value': 0})['value'] / 10.0;

  final double usedCapacityKwh = (settingsState.useRealtime && activeVehicle != null)
      ? (activeVehicle.batteryVolt * activeVehicle.batteryAh) / 1000.0
      : settingsState.batteryCapacityKwh;

  final double usedEfficiency = (settingsState.useRealtime && activeVehicle != null)
      ? activeVehicle.efisiensiCharger
      : settingsState.efisiensiCharger;

  return ChargingCalculator.calculateMetrics(
    currentPowerConsumption: sessionState.powerHistoryKw.isEmpty ? curPower : sessionState.smoothedPowerKw * 1000.0,
    batteryCapacity: usedCapacityKwh,
    chargingEfficiency: usedEfficiency,
    electricityCostPerKWh: settingsState.tarifPln,
    persenAwal: sessionState.persenAwal,
    persenTarget: sessionState.persenTarget,
    persenRealtime: sessionState.persenRealtime,
    isCharging: relayStatus,
    calibration: ChargingCalibrationProfile(
      usableBatteryKWh: activeVehicle?.calibrationUsableBatteryKwh ?? usedCapacityKwh,
      wallEnergyFullKWh: activeVehicle?.calibrationWallEnergyFullKwh ?? (usedCapacityKwh / usedEfficiency),
      fullChargeHours: activeVehicle?.calibrationFullChargeHours ?? ((usedCapacityKwh / usedEfficiency) / (curPower > 0 ? curPower / 1000.0 : 1.0)),
      taperStartPercent: activeVehicle?.calibrationTaperStartPercent ?? 80.0,
    ),
  );
});