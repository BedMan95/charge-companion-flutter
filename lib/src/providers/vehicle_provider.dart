import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import "package:shared_preferences/shared_preferences.dart";
import 'dart:io';
import '../api/api_client.dart';

class Vehicle {
  final String id;
  final String evModelId;
  final String? evBrand;
  final String? evModelName;
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
    this.evBrand,
    this.evModelName,
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

  factory Vehicle.fromMap(Map<String, dynamic> map, {Map<String, dynamic>? modelData}) {
    return Vehicle(
      id: map['id'],
      evModelId: map['evModelId'] ?? map['ev_model_id'],
      evBrand: modelData?['brand'],
      evModelName: modelData?['model'],
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? map['image_url'], // fallback local
      isActive: (map['isActive'] == true || map['isActive'] == 1 || map['is_active'] == 1),
      calibrationUsableBatteryKwh: map['calibrationUsableBatteryKwh']?.toDouble(),
      calibrationWallEnergyFullKwh: map['calibrationWallEnergyFullKwh']?.toDouble(),
      calibrationFullChargeHours: map['calibrationFullChargeHours']?.toDouble(),
      calibrationTaperStartPercent: map['calibrationTaperStartPercent']?.toDouble(),
      customBatteryVolt: map['customBatteryVolt']?.toDouble(),
      customBatteryAh: map['customBatteryAh']?.toDouble(),
      customEfisiensiCharger: map['customEfisiensiCharger']?.toDouble(),
      batteryVolt: (map['customBatteryVolt'] ?? map['batteryVolt'] ?? 72).toDouble(),
      batteryAh: (map['customBatteryAh'] ?? map['batteryAh'] ?? 38).toDouble(),
      efisiensiCharger: (map['customEfisiensiCharger'] ?? map['efisiensiCharger'] ?? 0.82).toDouble(),
    );
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

final evModelsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.get('/api/vehicles/models');
    if (res.statusCode == 200) {
      return (res.data as List).cast<Map<String, dynamic>>();
    }
  } catch (e) {}
  return [];
});

class VehicleNotifier extends StateNotifier<AsyncValue<List<Vehicle>>> {
  final Ref ref;
  VehicleNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final userId = await ApiClient.getUserId();
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Load EV Models mapping
      final modelsRes = await ApiClient.instance.get('/api/vehicles/models');
      final modelsList = (modelsRes.data as List).cast<Map<String, dynamic>>();
      final modelMap = {for (var m in modelsList) m['id'] as String: m};

      final response = await ApiClient.instance.get('/api/vehicles/user/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        final vehicles = data.map((map) {
          final modelId = map['evModelId'] ?? map['ev_model_id'];
          return Vehicle.fromMap(map, modelData: modelMap[modelId]);
        }).toList();
        state = AsyncValue.data(vehicles);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addVehicle(String name, String evModelId) async {
    try {
      final userId = await ApiClient.getUserId();
      if (userId == null) throw Exception('Not logged in');

      final formData = FormData.fromMap({
        'id': 'v_${DateTime.now().millisecondsSinceEpoch}', // Mock ID, real DB generates it usually, but API accepts 'id' in form data
        'userId': userId,
        'evModelId': evModelId,
        'name': name,
        'isActive': state.value?.isEmpty ?? true,
      });

      await ApiClient.instance.post(
        '/api/vehicles/user',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadVehicles();
      state.whenData((vehicles) async {
        try {
          final active = vehicles.firstWhere((v) => v.isActive);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble("activeVehicleVolt", active.customBatteryVolt ?? active.batteryVolt);
          await prefs.setDouble("activeVehicleAh", active.customBatteryAh ?? active.batteryAh);
        } catch (_) {}
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  Future<void> addCustomVehicle({
    required String name,
    required String brand,
    required String model,
    required double batteryVolt,
    required double batteryAh,
    required double efisiensiCharger,
  }) async {
    try {
      final evModelId = "custom_${DateTime.now().millisecondsSinceEpoch}";
      final formDataModel = FormData.fromMap({
        "id": evModelId,
        "brand": brand,
        "model": model,
        "batteryVolt": batteryVolt,
        "batteryAh": batteryAh,
        "efisiensiCharger": efisiensiCharger,
      });
      await ApiClient.instance.post("/api/vehicles/models", data: formDataModel, options: Options(contentType: "multipart/form-data"));
      await addVehicle(name, evModelId);
      ref.invalidate(evModelsProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }


  Future<void> updateVehicleImage(String id, String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return;

      final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
      final mediaType = MediaType.parse(mimeType);

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          contentType: mediaType,
        ),
      });

      await ApiClient.instance.put(
        '/api/vehicles/user/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadVehicles();
      state.whenData((vehicles) async {
        try {
          final active = vehicles.firstWhere((v) => v.isActive);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble("activeVehicleVolt", active.customBatteryVolt ?? active.batteryVolt);
          await prefs.setDouble("activeVehicleAh", active.customBatteryAh ?? active.batteryAh);
        } catch (_) {}
      });
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
      final formData = FormData.fromMap({
        if (customBatteryVolt != null) 'customBatteryVolt': customBatteryVolt,
        if (customBatteryAh != null) 'customBatteryAh': customBatteryAh,
      });

      await ApiClient.instance.put(
        '/api/vehicles/user/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadVehicles();
      state.whenData((vehicles) async {
        try {
          final active = vehicles.firstWhere((v) => v.isActive);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble("activeVehicleVolt", active.customBatteryVolt ?? active.batteryVolt);
          await prefs.setDouble("activeVehicleAh", active.customBatteryAh ?? active.batteryAh);
        } catch (_) {}
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await ApiClient.instance.delete('/api/vehicles/user/$id');
      await loadVehicles();
      state.whenData((vehicles) async {
        try {
          final active = vehicles.firstWhere((v) => v.isActive);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble("activeVehicleVolt", active.customBatteryVolt ?? active.batteryVolt);
          await prefs.setDouble("activeVehicleAh", active.customBatteryAh ?? active.batteryAh);
        } catch (_) {}
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setActiveVehicle(String id) async {
    try {
      final formData = FormData.fromMap({
        'isActive': true,
      });

      await ApiClient.instance.put(
        '/api/vehicles/user/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // Ideally backend handles making others false.
      // If not, we might need a separate call, but the standard pattern is backend logic handles unique active states.
      await loadVehicles();
      state.whenData((vehicles) async {
        try {
          final active = vehicles.firstWhere((v) => v.isActive);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble("activeVehicleVolt", active.customBatteryVolt ?? active.batteryVolt);
          await prefs.setDouble("activeVehicleAh", active.customBatteryAh ?? active.batteryAh);
        } catch (_) {}
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, AsyncValue<List<Vehicle>>>((ref) {
  return VehicleNotifier(ref);
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