import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tuya_provider.dart';
import '../providers/charging_session_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/vehicle_provider.dart';
import '../api/api_client.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'vehicle_management_view.dart';
import '../utils/auth_image_provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  static const routeName = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuyaStatus = ref.watch(tuyaStatusProvider);
    final sessionState = ref.watch(chargingSessionProvider);
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950
      body: SafeArea(
        child: tuyaStatus.when(
          data: (status) {
            final relayStatus = status.firstWhere(
                (s) => s['code'] == 'switch_1',
                orElse: () => {'value': false})['value'];
            final curCurrent = status.firstWhere(
                    (s) => s['code'] == 'cur_current',
                    orElse: () => {'value': 0})['value'] /
                1000.0;
            final curVoltage = status.firstWhere(
                    (s) => s['code'] == 'cur_voltage',
                    orElse: () => {'value': 0})['value'] /
                10.0;
            final curPower = status.firstWhere((s) => s['code'] == 'cur_power',
                    orElse: () => {'value': 0})['value'] /
                10.0;


            // Calculation moved to background service to prevent isolate race condition

            final metrics = sessionState;

            return Scaffold(
              backgroundColor: const Color(0xFF020617),
              body: RefreshIndicator(
                color: const Color(0xFF10B981), // emerald-500
                backgroundColor: const Color(0xFF0F172A), // slate-900
                onRefresh: () async {
                  // Riverpod handles periodic refresh
                },
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  children: [
                    _buildHeroSection(relayStatus, ref, context),
                    const SizedBox(height: 32),
                    _buildSummarySection(metrics, sessionState.accumulatedEnergyWh / 1000, sessionState, settingsState),
                    const SizedBox(height: 32),
                    _buildPowerFlowSection(
                        relayStatus, curVoltage, curCurrent, curPower, metrics.chargingEfficiency, metrics),
                    const SizedBox(height: 32),
                    _buildGarageSection(context, ref),
                    const SizedBox(height: 32),
                    _buildControlsSection(
                        context, ref, sessionState, settingsState),
                  ],
                ),
              ),
            );
          },
          loading: () => _buildModernLoading(),
          error: (err, stack) => Scaffold(
            backgroundColor: const Color(0xFF020617),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A), // slate-900
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () =>
                          ref.read(tuyaStatusProvider.notifier).refresh(),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernLoading() {
    return const ModernLoadingScreen();
  }

  Widget _buildHeroSection(bool isCharging, WidgetRef ref, BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final persenRealtime = ref.watch(chargingSessionProvider).persenRealtime;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4), // slate-900/40
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.8)), // slate-800/80
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          // Status and Percentage Header inside card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.8), // slate-800/80
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155).withOpacity(0.8)), // slate-700/80
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCharging
                            ? const Color(0xFF34D399) // emerald-400
                            : const Color(0xFF64748B), // slate-500
                        boxShadow: isCharging
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF34D399).withOpacity(0.5),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isCharging ? 'Charging' : 'Standby',
                      style: const TextStyle(
                          color: Color(0xFFCBD5E1), // slate-300
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.8), // slate-800/80
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)), // emerald-500/30
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.battery,
                        color: Color(0xFF34D399), size: 16), // emerald-400
                    const SizedBox(width: 6),
                    Text(
                      '${persenRealtime.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow background
              if (isCharging)
                const PulsingGlow(color: Color(0xFF10B981))
              else
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.1), // blue-500/10
                        blurRadius: 60,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                ),
              // Image
              SizedBox(
                height: 280,
                child: Center(
                  child: activeVehicle?.imageUrl != null
                      ? Image(
                          image: AuthNetworkImage('${ApiClient.baseUrl}${activeVehicle!.imageUrl}'),
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          'assets/images/motor.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            LucideIcons.car,
                            size: 140,
                            color: Colors.grey.shade800
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress bar
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF020617), // slate-950
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1E293B)), // slate-800
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (ref.watch(chargingSessionProvider).persenRealtime / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399), // emerald-400
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.5),
                      blurRadius: 10,
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCharging
                    ? const Color(0xFFDC2626) // red-600
                    : const Color(0xFF10B981), // emerald-500
                foregroundColor: isCharging ? Colors.white : const Color(0xFF020617), // slate-950
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final notifier = ref.read(tuyaStatusProvider.notifier);
                final sessionNotifier =
                    ref.read(chargingSessionProvider.notifier);

                if (!isCharging) {
                  final settingsState = ref.read(settingsProvider); final activeVehicle = ref.read(activeVehicleProvider); _showPreChargeDialog(context, ref, ref.read(chargingSessionProvider), settingsState, activeVehicle);
                } else {
                  notifier.toggleRelay(false);
                  sessionNotifier.stopSession();
                }
              },
              icon: const Icon(LucideIcons.power, size: 16),
              label: Text(
                isCharging ? 'STOP CHARGING' : 'START CHARGING',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreChargeDialog(BuildContext context, WidgetRef ref, ChargingMetricsState sessionState, SettingsState settingsState, Vehicle? activeVehicle) {
    final batController = TextEditingController(text: sessionState.persenAwal.toStringAsFixed(0));
    final hController = TextEditingController(text: '0');
    final mController = TextEditingController(text: '0');
    final sController = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155), // slate-700
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Mulai Pengisian', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Baterai Saat Ini (%)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 4),
              TextField(
                controller: batController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF10B981))),
                  filled: true, fillColor: Color(0xFF1E293B),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Delay Timer (Opsional)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTimerInput('Jam', hController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimerInput('Menit', mController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimerInput('Detik', sController)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final bat = double.tryParse(batController.text) ?? 0.0;
                    final h = int.tryParse(hController.text) ?? 0;
                    final m = int.tryParse(mController.text) ?? 0;
                    final s = int.tryParse(sController.text) ?? 0;
                    final totalSeconds = (h * 3600) + (m * 60) + s;

                    final sessionNotifier = ref.read(chargingSessionProvider.notifier);
                    final tuyaNotifier = ref.read(tuyaStatusProvider.notifier);

                    sessionNotifier.updatePersenAwalLocal(bat);
                    if (!context.mounted) return;

                    if (totalSeconds > 0) {
                      tuyaNotifier.setCountdown(totalSeconds);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Timer diatur: $h j, $m m, $s d')),
                        );
                      } else {
                        tuyaNotifier.toggleRelay(true);
                        sessionNotifier.startSession(vehicleId: activeVehicle?.id ?? "", persenAwal: sessionState.persenAwal, persenTarget: sessionState.persenTarget, batteryVolt: settingsState.batteryVolt, batteryAh: settingsState.batteryAh, efisiensiCharger: settingsState.efisiensiCharger);
                      }
                      Navigator.pop(context);
                  },
                  child: const Text('Mulai Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)), // slate-500
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.left,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF10B981))),
            filled: true, fillColor: Color(0xFF1E293B),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(
      ChargingMetricsState metrics, double accumulatedEnergyKWh, ChargingMetricsState sessionState, SettingsState settingsState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4), // slate-900/40
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.8)), // slate-800/80
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.zap, color: Color(0xFF34D399), size: 20), // emerald-400
              SizedBox(width: 12),
              Text('Ringkasan Pengisian',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildSummaryItem(LucideIcons.zap, 'Daya Pengisian',
                      '${metrics.actualPowerToBatteryKw.toStringAsFixed(3)} kW')),
              Expanded(
                  child: _buildSummaryItem(
                      LucideIcons.batteryCharging,
                      'Energi Masuk',
                      '${(sessionState.accumulatedEnergyWh / 1000 * settingsState.efisiensiCharger).toStringAsFixed(3)} kWh')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildSummaryItem(LucideIcons.clock, 'Sisa Waktu',
                      '${metrics.timeToChargeHours.floor()}j ${((metrics.timeToChargeHours % 1) * 60).round()}m',
                      subtext: 'Penuh: ${metrics.timeToChargeHours > 0 ? DateTime.now().add(Duration(minutes: (metrics.timeToChargeHours * 60).round())).toString().substring(11, 16) : '-'}')),
              Expanded(
                  child: _buildSummaryItem(
                      LucideIcons.circleDollarSign,
                      'Est. Biaya',
                      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(metrics.totalCost))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value,
      {String? subtext}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // slate-800
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)), // slate-700/50
          ),
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 20), // slate-400
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF94A3B8), // slate-400
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            if (subtext != null) ...[
              const SizedBox(height: 2),
              Text(subtext,
                  style: const TextStyle(
                      color: Color(0xFF34D399), // emerald-400
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildPowerFlowSection(
      bool isCharging, double voltage, double current, double power, double usedEfficiency, ChargingMetricsState metrics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4), // slate-900/40
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.8)), // slate-800/80
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.activity, color: Color(0xFF34D399), size: 20), // emerald-400
              SizedBox(width: 12),
              Text('Grafik & Aliran Daya',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressBar(
              'Daya Input AC (PLN)',
              '${power.toStringAsFixed(1)} W',
              power / 2200,
              const Color(0xFF3B82F6)), // blue-500
          const SizedBox(height: 24),
          _buildProgressBar(
              'Daya Output DC (Baterai)',
              '${(metrics.actualPowerToBatteryKw * 1000).toStringAsFixed(1)} W',
              (metrics.actualPowerToBatteryKw * 1000) / 2200,
              const Color(0xFF10B981)), // emerald-500
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF020617).withOpacity(0.4), // slate-950/40
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.5)), // slate-800/50
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallMetric(
                    '${voltage.toStringAsFixed(1)} V', 'Voltase AC'),
                _buildSmallMetric('${current.toStringAsFixed(2)} A', 'Arus AC'),
                _buildSmallMetric(
                    '${(metrics.actualPowerToBatteryKw * 1000).toStringAsFixed(1)} W',
                    'Daya DC',
                    color: const Color(0xFF34D399)), // emerald-400
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, String value, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF020617).withOpacity(0.5), // slate-950/50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.5)), // slate-800/50
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), // slate-400
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      color: color == const Color(0xFF10B981) ? const Color(0xFF34D399) : const Color(0xFFE2E8F0), // emerald-400 or slate-200
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // slate-900
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.8)), // slate-800/80
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(String value, String label,
      {Color color = const Color(0xFFE2E8F0)}) { // slate-200
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF64748B), // slate-500
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGarageSection(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    ref.watch(vehicleProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4), // slate-900/40
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.8)), // slate-800/80
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Garasi: Kendaraan Aktif',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // emerald-500
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, VehicleManagementView.routeName);
                },
                child: const Text('Garasi',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (activeVehicle != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1), // emerald-500/10
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF10B981)), // emerald-500
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981), // emerald-500
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.5),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activeVehicle.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(activeVehicle.evBrand != null ? '${activeVehicle.evBrand} ${activeVehicle.evModelName}' : 'Model ID: ${activeVehicle.evModelId}',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), // slate-400
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada kendaraan di garasi Anda. Tambahkan EV untuk memulai.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)), // slate-400
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsSection(BuildContext context, WidgetRef ref,
      ChargingMetricsState sessionState, SettingsState settingsState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4), // slate-900/40
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.8)), // slate-800/80
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.settings,
                      color: Color(0xFF34D399), size: 16), // emerald-400
                  SizedBox(width: 8),
                  Text('Kontrol & Parameter',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0), // slate-200
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                ],
              ),
              Row(
                children: [
                  const Text('Realtime',
                      style:
                          TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)), // slate-400
                  const SizedBox(width: 8),
                  Switch(
                      value: settingsState.useRealtime,
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).toggleRealtime(v),
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF059669), // emerald-600
                      inactiveThumbColor: const Color(0xFF94A3B8), // slate-400
                      inactiveTrackColor: const Color(0xFF1E293B)), // slate-800
                ],
              ),
            ],
          ),
          if (!settingsState.useRealtime) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInputField('BATERAI AWAL (%)',
                      sessionState.persenAwal.toStringAsFixed(0),
                      onTap: () => _showEditDialog(
                          context,
                          'Baterai Awal (%)',
                          sessionState.persenAwal.toStringAsFixed(0),
                          (val) => ref
                              .read(chargingSessionProvider.notifier)
                              .updatePersenAwalLocal(double.parse(val)))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInputField('TARGET (%)',
                      sessionState.persenTarget.toStringAsFixed(0),
                      onTap: () => _showEditDialog(
                          context,
                          'Target Pengisian (%)',
                          sessionState.persenTarget.toStringAsFixed(0),
                          (val) => ref
                              .read(chargingSessionProvider.notifier)
                              .updatePersenTargetLocal(double.parse(val)))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildInputField('VOLTASE BAT (V)',
                        settingsState.batteryVolt.toStringAsFixed(0),
                        onTap: () => _showEditDialog(
                            context,
                            'Voltase Baterai (V)',
                            settingsState.batteryVolt.toStringAsFixed(0),
                            (val) => ref
                                .read(settingsProvider.notifier)
                                .updateBatteryVolt(double.parse(val))))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildInputField('KAPASITAS (AH)',
                        settingsState.batteryAh.toStringAsFixed(0),
                        onTap: () => _showEditDialog(
                            context,
                            'Kapasitas (Ah)',
                            settingsState.batteryAh.toStringAsFixed(0),
                            (val) => ref
                                .read(settingsProvider.notifier)
                                .updateBatteryAh(double.parse(val))))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildInputField('EFISIENSI',
                        settingsState.efisiensiCharger.toStringAsFixed(2),
                        onTap: () => _showEditDialog(
                            context,
                            'Efisiensi',
                            settingsState.efisiensiCharger.toStringAsFixed(2),
                            (val) => ref
                                .read(settingsProvider.notifier)
                                .updateEfisiensi(double.parse(val))))),
              ],
            ),
          ],
          const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF0F172A), // slate-900
                      side: const BorderSide(color: Color(0xFF1E293B)), // slate-800
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () =>
                        ref.read(chargingSessionProvider.notifier).stopSession(),
                    icon: const Icon(LucideIcons.refreshCcw,
                        color: Color(0xFFCBD5E1), size: 14), // slate-300
                    label: const Text('Reset Sesi',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF0F172A), // slate-900
                      side: const BorderSide(color: Color(0xFF1E293B)), // slate-800
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () =>
                        Navigator.restorablePushNamed(context, '/settings'),
                    icon: const Icon(LucideIcons.settings,
                        color: Color(0xFFCBD5E1), size: 14), // slate-300
                    label: const Text('Pengaturan',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String value, {bool isReadOnly = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF94A3B8), // slate-400
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isReadOnly ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFF020617), // slate-900/50 or slate-950
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)), // slate-800
            ),
            child: Text(value,
                style: TextStyle(
                    color: isReadOnly ? const Color(0xFF94A3B8) : const Color(0xFFF1F5F9), // slate-400 or slate-100
                    fontSize: 14,
                    fontWeight: isReadOnly ? FontWeight.normal : FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Edit $title', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF10B981))),
                  filled: true, fillColor: Color(0xFF1E293B),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      onSave(controller.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernLoadingScreen extends StatefulWidget {
  const ModernLoadingScreen({super.key});

  @override
  State<ModernLoadingScreen> createState() => _ModernLoadingScreenState();
}

class _ModernLoadingScreenState extends State<ModernLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF020617), // slate-950
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.zap,
                      color: Color(0xFF34D399),
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 56),
          const Text(
            'Menghubungkan ke Garasi...',
            style: TextStyle(
              color: Color(0xFF94A3B8), // slate-400
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: Color(0xFF0F172A), // slate-900
                color: Color(0xFF10B981), // emerald-500
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingGlow extends StatefulWidget {
  final Color color;
  const PulsingGlow({super.key, required this.color});

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.05, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 160,
          width: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_glowAnimation.value),
                blurRadius: 80,
                spreadRadius: 40,
              )
            ],
          ),
        );
      },
    );
  }
}
