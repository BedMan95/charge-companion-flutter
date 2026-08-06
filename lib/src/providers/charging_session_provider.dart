import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChargingSessionState {
  final double persenAwal;
  final double persenTarget;
  final double persenRealtime;
  final double accumulatedEnergyKWh;
  final int? startTimeMs;
  final int? lastFetchTimeMs;
  final List<double> powerHistoryKw;
  final double smoothedPowerKw;

  const ChargingSessionState({
    this.persenAwal = 0.0,
    this.persenTarget = 100.0,
    this.persenRealtime = 0.0,
    this.accumulatedEnergyKWh = 0.0,
    this.startTimeMs,
    this.lastFetchTimeMs,
    this.powerHistoryKw = const [],
    this.smoothedPowerKw = 0.0,
  });

  ChargingSessionState copyWith({
    double? persenAwal,
    double? persenTarget,
    double? persenRealtime,
    double? accumulatedEnergyKWh,
    int? startTimeMs,
    int? lastFetchTimeMs,
    List<double>? powerHistoryKw,
    double? smoothedPowerKw,
  }) {
    return ChargingSessionState(
      persenAwal: persenAwal ?? this.persenAwal,
      persenTarget: persenTarget ?? this.persenTarget,
      persenRealtime: persenRealtime ?? this.persenRealtime,
      accumulatedEnergyKWh: accumulatedEnergyKWh ?? this.accumulatedEnergyKWh,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      lastFetchTimeMs: lastFetchTimeMs ?? this.lastFetchTimeMs,
      powerHistoryKw: powerHistoryKw ?? this.powerHistoryKw,
      smoothedPowerKw: smoothedPowerKw ?? this.smoothedPowerKw,
    );
  }
}

class ChargingSessionNotifier extends StateNotifier<ChargingSessionState> {
  ChargingSessionNotifier() : super(const ChargingSessionState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final powerHistoryStr = prefs.getString('powerHistoryKw') ?? '';
    final powerHistory = powerHistoryStr.isEmpty
        ? <double>[]
        : powerHistoryStr.split(',').map((e) => double.tryParse(e) ?? 0.0).toList();

    state = ChargingSessionState(
      persenAwal: prefs.getDouble('persenAwal') ?? 0.0,
      persenTarget: prefs.getDouble('persenTarget') ?? 100.0,
      persenRealtime: prefs.getDouble('persenRealtime') ?? 0.0,
      accumulatedEnergyKWh: prefs.getDouble('accumulatedEnergyKWh') ?? 0.0,
      startTimeMs: prefs.getInt('startTimeMs'),
      lastFetchTimeMs: prefs.getInt('lastFetchTimeMs'),
      powerHistoryKw: powerHistory,
      smoothedPowerKw: prefs.getDouble('smoothedPowerKw') ?? 0.0,
    );
  }

  Future<void> _saveState(ChargingSessionState newState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('persenAwal', newState.persenAwal);
    await prefs.setDouble('persenTarget', newState.persenTarget);
    await prefs.setDouble('persenRealtime', newState.persenRealtime);
    await prefs.setDouble(
        'accumulatedEnergyKWh', newState.accumulatedEnergyKWh);
    if (newState.startTimeMs != null) {
      await prefs.setInt('startTimeMs', newState.startTimeMs!);
    } else {
      await prefs.remove('startTimeMs');
    }
    if (newState.lastFetchTimeMs != null) {
      await prefs.setInt('lastFetchTimeMs', newState.lastFetchTimeMs!);
    } else {
      await prefs.remove('lastFetchTimeMs');
    }
    await prefs.setString('powerHistoryKw', newState.powerHistoryKw.join(','));
    await prefs.setDouble('smoothedPowerKw', newState.smoothedPowerKw);
    state = newState;
  }

  Future<void> updatePersenAwal(double value) async {
    await _saveState(state.copyWith(persenAwal: value, persenRealtime: value));
  }

  Future<void> updatePersenTarget(double value) async {
    await _saveState(state.copyWith(persenTarget: value));
  }

  Future<void> startSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _saveState(state.copyWith(
      startTimeMs: now,
      lastFetchTimeMs: now,
      accumulatedEnergyKWh: 0.0,
      persenRealtime: state.persenAwal,
    ));
  }

  Future<void> stopSession() async {
    await _saveState(state.copyWith(
      startTimeMs: null,
      lastFetchTimeMs: null,
    ));
  }

  Future<void> resetSession() async {
    await _saveState(const ChargingSessionState());
  }

  Future<void> processRealtimeData(double currentPowerKw,
      double batteryCapacityKwh, double efficiency) async {
    if (state.startTimeMs == null) return; // Not charging

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastFetch = state.lastFetchTimeMs ?? now;

    // Calculate elapsed hours since last fetch
    final elapsedHours = (now - lastFetch) / (1000 * 3600);
    if (elapsedHours <= 0) return;

    // Calculate energy added in this interval
    final energyAddedKwh = currentPowerKw * elapsedHours;
    final newAccumulatedEnergy = state.accumulatedEnergyKWh + energyAddedKwh;

    // Calculate new percentage
    final energyDcCharged = newAccumulatedEnergy * efficiency;
    final addedPercentage = (energyDcCharged / batteryCapacityKwh) * 100;
    final newPersenRealtime =
        (state.persenAwal + addedPercentage).clamp(0.0, state.persenTarget);

    const maxHistory = 10;
    final newHistory = List<double>.from(state.powerHistoryKw)..add(currentPowerKw);
    if (newHistory.length > maxHistory) {
      newHistory.removeAt(0);
    }
    final smoothed = newHistory.isEmpty ? 0.0 : newHistory.reduce((a, b) => a + b) / newHistory.length;

    await _saveState(state.copyWith(
      accumulatedEnergyKWh: newAccumulatedEnergy,
      persenRealtime: newPersenRealtime,
      lastFetchTimeMs: now,
      powerHistoryKw: newHistory,
      smoothedPowerKw: smoothed,
    ));
  }
}

final chargingSessionProvider =
    StateNotifierProvider<ChargingSessionNotifier, ChargingSessionState>((ref) {
  return ChargingSessionNotifier();
});
