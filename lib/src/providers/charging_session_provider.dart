import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'tuya_provider.dart';

class ChargingMetricsState {
  final double powerInKw;
  final double actualPowerToBatteryKw;
  final double timeToChargeHours;
  final double totalCost;
  final double chargingEfficiency;
  final double persenRealtime;
  final String status; // ACTIVE, STOPPED, dll
  final double accumulatedEnergyWh;
  final double cost; // Total cost session

  // Additional session params kept for UI
  final double persenAwal;
  final double persenTarget;
  final String? sessionId;

  const ChargingMetricsState({
    this.powerInKw = 0.0,
    this.actualPowerToBatteryKw = 0.0,
    this.timeToChargeHours = 0.0,
    this.totalCost = 0.0,
    this.chargingEfficiency = 0.82,
    this.persenRealtime = 0.0,
    this.status = 'IDLE',
    this.accumulatedEnergyWh = 0.0,
    this.cost = 0.0,
    this.persenAwal = 0.0,
    this.persenTarget = 100.0,
    this.sessionId,
  });

  ChargingMetricsState copyWith({
    double? powerInKw,
    double? actualPowerToBatteryKw,
    double? timeToChargeHours,
    double? totalCost,
    double? chargingEfficiency,
    double? persenRealtime,
    String? status,
    double? accumulatedEnergyWh,
    double? cost,
    double? persenAwal,
    double? persenTarget,
    String? sessionId,
  }) {
    return ChargingMetricsState(
      powerInKw: powerInKw ?? this.powerInKw,
      actualPowerToBatteryKw: actualPowerToBatteryKw ?? this.actualPowerToBatteryKw,
      timeToChargeHours: timeToChargeHours ?? this.timeToChargeHours,
      totalCost: totalCost ?? this.totalCost,
      chargingEfficiency: chargingEfficiency ?? this.chargingEfficiency,
      persenRealtime: persenRealtime ?? this.persenRealtime,
      status: status ?? this.status,
      accumulatedEnergyWh: accumulatedEnergyWh ?? this.accumulatedEnergyWh,
      cost: cost ?? this.cost,
      persenAwal: persenAwal ?? this.persenAwal,
      persenTarget: persenTarget ?? this.persenTarget,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class ChargingSessionNotifier extends StateNotifier<ChargingMetricsState> {
  final Ref ref;
  Timer? _pollingTimer;

  ChargingSessionNotifier(this.ref) : super(const ChargingMetricsState()) {
    // Attempt to resume session polling if we have active session locally (or fetch latest active from history)
    _fetchLatestSession();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestSession() async {
    try {
      final userId = await ApiClient.getUserId();
      if (userId == null) return;

      final res = await ApiClient.instance.get('/api/sessions/history/$userId?limit=1');
      if (res.statusCode == 200 && (res.data as List).isNotEmpty) {
        final latest = res.data[0];
        if (latest['status'] == 'ACTIVE') {
          state = state.copyWith(
            sessionId: latest['id'].toString(),
            status: 'ACTIVE',
            persenAwal: latest['persenAwal']?.toDouble(),
            persenTarget: latest['persenTarget']?.toDouble(),
          );
          _startPolling();
        } else {
          state = state.copyWith(
            status: latest['status'],
            persenRealtime: latest['persenAwal']?.toDouble() ?? 0.0,
          );
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollMetrics());
  }

  Future<void> _pollMetrics() async {
    if (state.sessionId == null || state.status != 'ACTIVE') return;

    try {
      // Get current power from TuyaProvider first
      final tuyaData = ref.read(tuyaStatusProvider).value ?? [];
      final curPower = tuyaData.firstWhere(
              (s) => s['code'] == 'cur_power',
          orElse: () => {'value': 0})['value'] / 10.0;

      final res = await ApiClient.instance.get('/api/sessions/metrics/${state.sessionId}?watt=$curPower');

      if (res.statusCode == 200 && res.data != null) {
        final d = res.data;
        state = state.copyWith(
          powerInKw: d['powerInKw']?.toDouble() ?? 0.0,
          actualPowerToBatteryKw: d['actualPowerToBatteryKw']?.toDouble() ?? 0.0,
          timeToChargeHours: d['timeToChargeHours']?.toDouble() ?? 0.0,
          totalCost: d['totalCost']?.toDouble() ?? 0.0,
          chargingEfficiency: d['chargingEfficiency']?.toDouble() ?? 0.82,
          persenRealtime: d['persenRealtime']?.toDouble() ?? state.persenAwal,
          status: d['status'] ?? 'ACTIVE',
          accumulatedEnergyWh: d['accumulatedEnergy']?.toDouble() ?? 0.0,
          cost: d['cost']?.toDouble() ?? 0.0,
        );

        if (d['status'] != 'ACTIVE') {
           _pollingTimer?.cancel();
        }
      }
    } catch (e) {
      // Silent error for background polling
    }
  }

  Future<void> startSession({
    required String vehicleId,
    required double persenAwal,
    required double persenTarget,
    required double batteryVolt,
    required double batteryAh,
    required double efisiensiCharger,
  }) async {
    try {
      final userId = await ApiClient.getUserId();
      if (userId == null) throw Exception('Not logged in');

      final res = await ApiClient.instance.post('/api/sessions/start', data: {
        'userId': userId,
        'vehicleId': vehicleId,
        'persenAwal': persenAwal,
        'persenTarget': persenTarget,
        'batteryVolt': batteryVolt,
        'batteryAh': batteryAh,
        'efisiensiCharger': efisiensiCharger,
      });

      if (res.statusCode == 200 && res.data != null) {
        state = state.copyWith(
          sessionId: res.data['id'].toString(),
          status: 'ACTIVE',
          persenAwal: persenAwal,
          persenTarget: persenTarget,
          persenRealtime: persenAwal,
        );
        _startPolling();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopSession() async {
    try {
      if (state.sessionId != null) {
        await ApiClient.instance.post('/api/sessions/stop/${state.sessionId}');
      }
      _pollingTimer?.cancel();
      state = state.copyWith(status: 'STOPPED_MANUAL');
    } catch (e) {
      // Ignored
    }
  }

  void updatePersenAwalLocal(double value) {
    state = state.copyWith(persenAwal: value, persenRealtime: value);
  }

  void updatePersenTargetLocal(double value) {
    state = state.copyWith(persenTarget: value);
  }
}

final chargingSessionProvider =
    StateNotifierProvider<ChargingSessionNotifier, ChargingMetricsState>((ref) {
  return ChargingSessionNotifier(ref);
});