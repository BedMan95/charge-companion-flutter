import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';

class Vehicle {
  final String id;
  final String evModelId;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final double? calibrationUsableBatteryKwh;
  final double? calibrationWallEnergyFullKwh;
  final double? calibrationFullChargeHours;
  final double? calibrationTaperStartPercent;

  // Relational data from ev_models
  final double batteryVolt;
  final double batteryAh;
  final double efisiensiCharger;

  // Custom overrides
  final double? customBatteryVolt;
  final double? customBatteryAh;
  final double? customEfisiensiCharger;

  Vehicle({
    required this.id,
    required this.evModelId,
    required this.name,
    this.imageUrl,
    this.isActive = false,
    this.calibrationUsableBatteryKwh,
    this.calibrationWallEnergyFullKwh,
    this.calibrationFullChargeHours,
    this.calibrationTaperStartPercent,
    this.batteryVolt = 72.0,
    this.batteryAh = 38.0,
    this.efisiensiCharger = 0.82,
    this.customBatteryVolt,
    this.customBatteryAh,
    this.customEfisiensiCharger,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      evModelId: map['ev_model_id'],
      name: map['name'] ?? '',
      imageUrl: map['image_url'],
      isActive: map['is_active'] == 1,
      calibrationUsableBatteryKwh: map['calibration_usable_battery_kwh'],
      calibrationWallEnergyFullKwh: map['calibration_wall_energy_full_kwh'],
      calibrationFullChargeHours: map['calibration_full_charge_hours'],
      calibrationTaperStartPercent: map['calibration_taper_start_percent'],
      customBatteryVolt: map['custom_battery_volt'],
      customBatteryAh: map['custom_battery_ah'],
      customEfisiensiCharger: map['custom_efisiensi_charger'],
      batteryVolt: (map['custom_battery_volt'] ?? map['battery_volt'] ?? 72).toDouble(),
      batteryAh: (map['custom_battery_ah'] ?? map['battery_ah'] ?? 38).toDouble(),
      efisiensiCharger: (map['custom_efisiensi_charger'] ?? map['efisiensi_charger'] ?? 0.82).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ev_model_id': evModelId,
      'name': name,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'calibration_usable_battery_kwh': calibrationUsableBatteryKwh,
      'calibration_wall_energy_full_kwh': calibrationWallEnergyFullKwh,
      'calibration_full_charge_hours': calibrationFullChargeHours,
      'calibration_taper_start_percent': calibrationTaperStartPercent,
      'custom_battery_volt': customBatteryVolt,
      'custom_battery_ah': customBatteryAh,
      'custom_efisiensi_charger': customEfisiensiCharger,
    };
  }

  Vehicle copyWith({
    String? id,
    String? evModelId,
    String? name,
    String? imageUrl,
    bool? isActive,
    double? calibrationUsableBatteryKwh,
    double? calibrationWallEnergyFullKwh,
    double? calibrationFullChargeHours,
    double? calibrationTaperStartPercent,
    double? customBatteryVolt,
    double? customBatteryAh,
    double? customEfisiensiCharger,
    double? batteryVolt,
    double? batteryAh,
    double? efisiensiCharger,
  }) {
    return Vehicle(
      id: id ?? this.id,
      evModelId: evModelId ?? this.evModelId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      calibrationUsableBatteryKwh:
          calibrationUsableBatteryKwh ?? this.calibrationUsableBatteryKwh,
      calibrationWallEnergyFullKwh:
          calibrationWallEnergyFullKwh ?? this.calibrationWallEnergyFullKwh,
      calibrationFullChargeHours:
          calibrationFullChargeHours ?? this.calibrationFullChargeHours,
      calibrationTaperStartPercent:
          calibrationTaperStartPercent ?? this.calibrationTaperStartPercent,
      customBatteryVolt: customBatteryVolt ?? this.customBatteryVolt,
      customBatteryAh: customBatteryAh ?? this.customBatteryAh,
      customEfisiensiCharger: customEfisiensiCharger ?? this.customEfisiensiCharger,
      batteryVolt: batteryVolt ?? this.batteryVolt,
      batteryAh: batteryAh ?? this.batteryAh,
      efisiensiCharger: efisiensiCharger ?? this.efisiensiCharger,
    );
  }
}

class VehicleNotifier extends StateNotifier<AsyncValue<List<Vehicle>>> {
  VehicleNotifier() : super(const AsyncValue.loading()) {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.rawQuery('''
        SELECT uv.*, em.battery_volt, em.battery_ah, em.efisiensi_charger
        FROM user_vehicles uv
        LEFT JOIN ev_models em ON uv.ev_model_id = em.id
      ''');
      final vehicles = maps.map((map) => Vehicle.fromMap(map)).toList();
      state = AsyncValue.data(vehicles);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addVehicle(String name, String evModelId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final newVehicle = Vehicle(
        id: const Uuid().v4(),
        evModelId: evModelId,
        name: name,
        isActive:
            state.value?.isEmpty ?? true, // Make active if it's the first one
      );

      await db.insert('user_vehicles', newVehicle.toMap());
      await loadVehicles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateVehicleImage(String id, String imagePath) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'user_vehicles',
        {'image_url': imagePath},
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadVehicles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateVehicleSettings(
    String id, {
    double? usableBatteryKwh,
    double? wallEnergyFullKwh,
    double? fullChargeHours,
    double? taperStartPercent,
    double? customBatteryVolt,
    double? customBatteryAh,
    double? customEfisiensiCharger,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'user_vehicles',
        {
          'calibration_usable_battery_kwh': usableBatteryKwh,
          'calibration_wall_energy_full_kwh': wallEnergyFullKwh,
          'calibration_full_charge_hours': fullChargeHours,
          'calibration_taper_start_percent': taperStartPercent,
          'custom_battery_volt': customBatteryVolt,
          'custom_battery_ah': customBatteryAh,
          'custom_efisiensi_charger': customEfisiensiCharger,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadVehicles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'user_vehicles',
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadVehicles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setActiveVehicle(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.update('user_vehicles', {'is_active': 0});
        await txn.update('user_vehicles', {'is_active': 1},
            where: 'id = ?', whereArgs: [id]);
      });
      await loadVehicles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, AsyncValue<List<Vehicle>>>((ref) {
  return VehicleNotifier();
});

final activeVehicleProvider = Provider<Vehicle?>((ref) {
  final vehiclesState = ref.watch(vehicleProvider);
  return vehiclesState.maybeWhen(
    data: (vehicles) {
      try {
        return vehicles.firstWhere((v) => v.isActive);
      } catch (e) {
        return vehicles.isNotEmpty ? vehicles.first : null;
      }
    },
    orElse: () => null,
  );
});
