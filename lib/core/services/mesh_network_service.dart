import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart' hide Message;
import '../models/peer.dart';
import '../models/message.dart';

/// Service managing the mesh network connections and discovery
class MeshNetworkService extends ChangeNotifier {
  final Logger _logger = Logger();
  
  // Current state
  final Map<String, Peer> _peers = {};
  bool _isScanning = false;
  bool _isAdvertising = false;
  bool _isBatterySaver = false;
  String? _deviceId;
  String? _deviceName;

  late NearbyService _nearbyService;
  StreamSubscription? _subscription;
  StreamSubscription? _dataSubscription;
  Timer? _batterySaverTimer;

  // Callbacks
  Function(Message)? onMessageReceived;
  Function(Peer)? onPeerDiscovered;
  Function(String)? onPeerDisconnected;

  // Getters
  List<Peer> get peers => _peers.values.toList();
  List<Peer> get onlinePeers => 
      _peers.values.where((p) => p.status == PeerStatus.online).toList();
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  bool get isBatterySaver => _isBatterySaver;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;

  /// Toggle Battery Saver Mode
  void toggleBatterySaver() {
    _isBatterySaver = !_isBatterySaver;
    _logger.i('Battery Saver Mode: $_isBatterySaver');
    
    if (_isBatterySaver) {
      _startBatterySaverCycle();
    } else {
      _batterySaverTimer?.cancel();
      startScanning();
      startAdvertising();
    }
    notifyListeners();
  }

  void _startBatterySaverCycle() {
    _batterySaverTimer?.cancel();
    // Start by sleeping
    stopScanning();
    stopAdvertising();
    
    _batterySaverTimer = Timer.periodic(const Duration(minutes: 3), (timer) async {
      _logger.i('[BATTERY_SAVER] Waking up to sync mesh network...');
      await startScanning();
      await startAdvertising();
      
      // Stay awake for 15 seconds to sync data
      Future.delayed(const Duration(seconds: 15), () {
        if (_isBatterySaver) {
          _logger.i('[BATTERY_SAVER] Going back to sleep...');
          stopScanning();
          stopAdvertising();
        }
      });
    });
  }

  /// Initialize the mesh network service
  Future<void> initialize(String deviceId, String deviceName) async {
    _deviceId = deviceId;
    _deviceName = deviceName;
    _logger.i('Mesh network initialized: $deviceName ($deviceId)');

    _nearbyService = NearbyService();
    await _nearbyService.init(
      serviceType: 'crisis-mesh',
      deviceName: deviceName,
      strategy: Strategy.P2P_CLUSTER,
      callback: (List<Device> devicesList) {
        _handleDevicesListUpdate(devicesList);
      },
    );

    _dataSubscription = _nearbyService.dataReceivedSubscription(callback: (data) {
      _handleRawData(data);
    });
  }

  void _handleDevicesListUpdate(List<Device> devicesList) {
    _logger.i('Nearby devices updated: ${devicesList.length} devices');
    
    // Check for missing peers (disconnected)
    final newDeviceIds = devicesList.map((d) => d.deviceId).toSet();
    final currentPeerIds = _peers.keys.toSet();
    
    for (final id in currentPeerIds) {
      if (!newDeviceIds.contains(id) && _peers[id]?.status != PeerStatus.offline) {
        _logger.i('Peer disconnected: $id');
        _peers[id] = _peers[id]!.copyWith(status: PeerStatus.offline);
        onPeerDisconnected?.call(id);
      }
    }

    for (var device in devicesList) {
      final status = _mapSessionState(device.state);
      final existingPeer = _peers[device.deviceId];
      
      final peer = existingPeer?.copyWith(
        status: status,
        lastSeen: DateTime.now(),
      ) ?? Peer(
        id: device.deviceId,
        name: device.deviceName,
        lastSeen: DateTime.now(),
        status: status,
        deviceType: 'Unknown',
        signalStrength: -50,
      );

      if (existingPeer == null) {
        _logger.i('New peer discovered: ${peer.name}');
        onPeerDiscovered?.call(peer);
      }
      
      _peers[peer.id] = peer;

      // Auto-connect to available peers in a mesh network
      if (device.state == SessionState.notConnected) {
        _logger.i('Auto-inviting peer: ${device.deviceName}');
        _nearbyService.invitePeer(
          deviceID: device.deviceId,
          deviceName: device.deviceName,
        );
      }
    }
    
    notifyListeners();
  }

  PeerStatus _mapSessionState(SessionState state) {
    switch (state) {
      case SessionState.connected:
        return PeerStatus.online;
      case SessionState.connecting:
        return PeerStatus.connecting;
      case SessionState.notConnected:
        return PeerStatus.nearby;
    }
  }

  void _handleRawData(dynamic data) {
    try {
      final messageStr = data['message'];
      final json = jsonDecode(messageStr);
      final message = Message.fromJson(json);
      _handleReceivedMessage(message);
    } catch (e) {
      _logger.e('Error parsing message: $e');
    }
  }

  /// Start scanning for nearby peers
  Future<void> startScanning() async {
    if (_isScanning) return;
    _logger.i('Starting peer discovery...');
    _isScanning = true;
    notifyListeners();

    await _nearbyService.startBrowsingForPeers();
  }

  /// Stop scanning for peers
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    _logger.i('Stopping peer discovery...');
    _isScanning = false;
    notifyListeners();

    await _nearbyService.stopBrowsingForPeers();
  }

  /// Start advertising this device
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;
    _logger.i('Starting advertising: $_deviceName');
    _isAdvertising = true;
    notifyListeners();

    await _nearbyService.startAdvertisingPeer();
  }

  /// Stop advertising this device
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    _logger.i('Stopping advertising');
    _isAdvertising = false;
    notifyListeners();

    await _nearbyService.stopAdvertisingPeer();
  }

  /// Connect to a specific peer manually
  Future<bool> connectToPeer(String peerId) async {
    _logger.i('Connecting to peer: $peerId');
    final peer = _peers[peerId];
    if (peer == null) {
      _logger.w('Peer not found: $peerId');
      return false;
    }

    _peers[peerId] = peer.copyWith(status: PeerStatus.connecting);
    notifyListeners();

    _nearbyService.invitePeer(deviceID: peerId, deviceName: peer.name);
    return true;
  }

  /// Disconnect from a peer
  Future<void> disconnectFromPeer(String peerId) async {
    _logger.i('Disconnecting from peer: $peerId');
    _nearbyService.disconnectPeer(deviceID: peerId);
    
    final peer = _peers[peerId];
    if (peer != null) {
      _peers[peerId] = peer.copyWith(status: PeerStatus.offline);
      notifyListeners();
    }
  }

  /// Send a message through the mesh network
  Future<bool> sendMessage(Message message) async {
    _logger.i('Sending message: ${message.id} to ${message.recipientId}');

    // Check if recipient is directly connected
    final recipient = _peers[message.recipientId];
    if (recipient?.status == PeerStatus.online) {
      return await _sendDirectMessage(message, recipient!);
    }

    // Otherwise, use epidemic routing - send to all connected peers
    return await _broadcastMessage(message);
  }

  /// Send message directly to a connected peer
  Future<bool> _sendDirectMessage(Message message, Peer peer) async {
    try {
      final messageJson = jsonEncode(message.toJson());
      _logger.d('Sending direct message to ${peer.name}: ${message.content}');
      _nearbyService.sendMessage(peer.id, messageJson);
      return true;
    } catch (e) {
      _logger.e('Failed to send message: $e');
      return false;
    }
  }

  /// Broadcast message to all connected peers (epidemic routing)
  Future<bool> _broadcastMessage(Message message) async {
    if (!message.canForward) {
      _logger.w('Message has reached max hops: ${message.id}');
      return false;
    }

    final onlinePeersList = onlinePeers;
    if (onlinePeersList.isEmpty) {
      _logger.w('No peers available to relay message');
      return false;
    }

    _logger.i('Broadcasting message to ${onlinePeersList.length} peers');
    
    int successCount = 0;
    for (final peer in onlinePeersList) {
      // Don't send back to the immediate sender (basic loop prevention)
      if (peer.id != message.senderId) {
        final forwarded = message.incrementHop(_deviceId!);
        if (await _sendDirectMessage(forwarded, peer)) {
          successCount++;
        }
      }
    }

    return successCount > 0;
  }

  /// Handle received message
  void _handleReceivedMessage(Message message) {
    _logger.i('Received message: ${message.id}');

    // Check if message is for us
    if (message.recipientId == _deviceId) {
      _logger.i('Message is for us!');
      onMessageReceived?.call(message);
      return;
    }

    // Forward the message if it can still hop
    if (message.canForward) {
      _logger.i('Forwarding message: ${message.id}');
      _broadcastMessage(message);
    } else {
      _logger.w('Message reached max hops, dropping: ${message.id}');
    }
  }

  @override
  void dispose() {
    stopScanning();
    stopAdvertising();
    _subscription?.cancel();
    _dataSubscription?.cancel();
    _peers.clear();
    super.dispose();
  }
}
