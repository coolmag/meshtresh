import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'mesh_network_service.dart';
import 'message_storage_service.dart';
import 'emergency_service.dart';

final getIt = GetIt.instance;

/// Initialize all services
Future<void> initializeServices() async {
  // 1. Check and request permissions (Critical for Mesh networking)
  await _requestPermissions();

  // 2. Register mesh network service
  getIt.registerSingleton<MeshNetworkService>(MeshNetworkService());

  // 3. Register storage service
  final storageService = MessageStorageService();
  await storageService.init();
  getIt.registerSingleton<MessageStorageService>(storageService);

  // 4. Register emergency service
  getIt.registerSingleton<EmergencyService>(EmergencyService());

  // 5. Start mesh network service discovery
  // Note: We use the actual method names from mesh_network_service.dart
  final meshService = getIt<MeshNetworkService>();
  
  // We'll need a way to get persistent device info, but for now use unique ID
  await meshService.initialize('device-${DateTime.now().millisecondsSinceEpoch}', 'Crisis-Node');
  await meshService.startScanning();
  await meshService.startAdvertising();
}

/// Request required permissions for mesh networking
Future<void> _requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.nearbyWifiDevices,
  ].request();
  
  // We don't block initialization if some permissions are denied,
  // but in a production app we should handle this and show a UI warning.
  print('Permissions requested: $statuses');
}

/// Cleanup all services
Future<void> cleanupServices() async {
  final meshService = getIt<MeshNetworkService>();
  await meshService.stopScanning();
  await meshService.stopAdvertising();
  await getIt<MessageStorageService>().dispose();
  await getIt.reset();
}
