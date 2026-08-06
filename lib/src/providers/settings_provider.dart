import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final double batteryVolt;
  final double batteryAh;
  final double efisiensiCharger;
  final double tarifPln;
  final bool useRealtime;

  const SettingsState({
    this.batteryVolt = 72.0,
    this.batteryAh = 38.0,
    this.efisiensiCharger = 0.82,
    this.tarifPln = 1600.0,
    this.useRealtime = true,
  });

  double get batteryCapacityKwh => (batteryVolt * batteryAh) / 1000.0;

  SettingsState copyWith({
    double? batteryVolt,
    double? batteryAh,
    double? efisiensiCharger,
    double? tarifPln,
    bool? useRealtime,
  }) {
    return SettingsState(
      batteryVolt: batteryVolt ?? this.batteryVolt,
      batteryAh: batteryAh ?? this.batteryAh,
      efisiensiCharger: efisiensiCharger ?? this.efisiensiCharger,
      tarifPln: tarifPln ?? this.tarifPln,
      useRealtime: useRealtime ?? this.useRealtime,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      batteryVolt: prefs.getDouble('batteryVolt') ?? 72.0,
      batteryAh: prefs.getDouble('batteryAh') ?? 38.0,
      efisiensiCharger: prefs.getDouble('efisiensiCharger') ?? 0.82,
      tarifPln: prefs.getDouble('tarifPln') ?? 1600.0,
      useRealtime: prefs.getBool('useRealtime') ?? true,
    );
  }

  Future<void> _saveSettings(SettingsState newState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('batteryVolt', newState.batteryVolt);
    await prefs.setDouble('batteryAh', newState.batteryAh);
    await prefs.setDouble('efisiensiCharger', newState.efisiensiCharger);
    await prefs.setDouble('tarifPln', newState.tarifPln);
    await prefs.setBool('useRealtime', newState.useRealtime);
    state = newState;
  }

  Future<void> updateBatteryVolt(double value) async {
    await _saveSettings(state.copyWith(batteryVolt: value));
  }

  Future<void> updateBatteryAh(double value) async {
    await _saveSettings(state.copyWith(batteryAh: value));
  }

  Future<void> updateEfisiensi(double value) async {
    await _saveSettings(state.copyWith(efisiensiCharger: value));
  }

  Future<void> updateTarifPln(double value) async {
    await _saveSettings(state.copyWith(tarifPln: value));
  }

  Future<void> toggleRealtime(bool value) async {
    await _saveSettings(state.copyWith(useRealtime: value));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
