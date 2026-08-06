import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/tuya_api.dart';
import 'dart:async';

final tuyaStatusProvider =
    StateNotifierProvider<TuyaStatusNotifier, AsyncValue<List<dynamic>>>((ref) {
  return TuyaStatusNotifier();
});

class TuyaStatusNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  TuyaStatusNotifier() : super(const AsyncValue.loading()) {
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchStatus());
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await TuyaApi.getDeviceStatus();
      if (data != null && data['status'] != null) {
        state = AsyncValue.data(data['status']);
      } else {
        state = AsyncValue.error(
            'Kredensial Tuya belum diatur atau tidak valid.',
            StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleRelay(bool value) async {
    final success = await TuyaApi.sendCommand([
      {'code': 'switch_1', 'value': value}
    ]);
    if (success) {
      _fetchStatus();
    }
  }

  Future<void> setCountdown(int seconds) async {
    final success = await TuyaApi.sendCommand([
      {'code': 'countdown_1', 'value': seconds}
    ]);
    if (success) {
      _fetchStatus();
    }
  }
}
