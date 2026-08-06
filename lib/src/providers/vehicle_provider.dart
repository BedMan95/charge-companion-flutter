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
      final maps = await db.query('user_vehicles');
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
