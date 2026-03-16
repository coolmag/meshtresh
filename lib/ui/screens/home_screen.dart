import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/mesh_network_service.dart';
import '../../core/services/message_storage_service.dart';
import '../../core/services/emergency_service.dart';
import '../../core/di/service_locator.dart';
import '../widgets/conversation_list_item.dart';
import '../widgets/network_status_banner.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'network_status_screen.dart';
import 'emergency_alerts_screen.dart';
import 'sos_screen.dart';

/// Main screen showing conversation list (Retro Terminal Style)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = getIt<MessageStorageService>();
  
  @override
  void initState() {
    super.initState();
    _initializeMeshNetwork();
  }

  Future<void> _initializeMeshNetwork() async {
    final meshService = context.read<MeshNetworkService>();
    final deviceId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    const deviceName = 'OPERATOR'; // Retro default name
    
    await meshService.initialize(deviceId, deviceName);
    await meshService.startScanning();
    await meshService.startAdvertising();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.terminalPureBlack,
      appBar: AppBar(
        title: const Text('[CRISIS_MESH_OS]'),
        actions: [
          // Emergency alerts button with badge
          Consumer<EmergencyService>(
            builder: (context, emergencyService, child) {
              final criticalCount = emergencyService.criticalSignalsCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.warning_amber_rounded),
                    color: criticalCount > 0 ? AppTheme.errorColor : AppTheme.terminalGreen,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmergencyAlertsScreen(),
                        ),
                      );
                    },
                  ),
                  if (criticalCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        color: AppTheme.errorColor,
                        child: Text(
                          '$criticalCount',
                          style: const TextStyle(
                            color: AppTheme.terminalPureBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.radar),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NetworkStatusScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusBanner(),
          _buildSOSBanner(),
          Expanded(
            child: _buildConversationList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewConversationDialog,
        icon: const Icon(Icons.add_box),
        label: const Text('INIT COMM'),
        backgroundColor: AppTheme.terminalGreen,
        foregroundColor: AppTheme.terminalPureBlack,
        shape: const BeveledRectangleBorder(),
      ),
    );
  }

  Widget _buildSOSBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.terminalPureBlack,
        border: Border.all(color: AppTheme.errorColor, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SOSScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.crisis_alert,
                  color: AppTheme.errorColor,
                  size: 28,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '!!! BROADCAST SOS !!!',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '> TAP TO TRANSMIT EMERGENCY SIGNAL',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.errorColor.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    final conversations = _storageService.getAllConversations();
    
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory,
              size: 64,
              color: AppTheme.terminalDarkGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              '> COMM_LOG EMPTY',
              style: TextStyle(
                color: AppTheme.terminalDarkGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AWAITING INCOMING TRANSMISSION...',
              style: TextStyle(
                color: AppTheme.terminalDarkGreen.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationListItem(
          conversation: conversation,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  peerId: conversation.peerId,
                  peerName: conversation.peerName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNewConversationDialog() {
    final meshService = context.read<MeshNetworkService>();
    final peers = meshService.peers;

    if (peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('> ERROR: NO RECEIVERS IN RANGE'),
          backgroundColor: AppTheme.terminalBlack,
          behavior: SnackBarBehavior.floating,
          shape: Border.all(color: AppTheme.terminalGreen, width: 1),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.terminalPureBlack,
        shape: Border.all(color: AppTheme.terminalGreen, width: 2),
        title: const Text('> SELECT RECEIVER', style: TextStyle(color: AppTheme.terminalGreen)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final peer = peers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.terminalDarkGreen, width: 1),
                ),
                child: ListTile(
                  leading: Text(
                    '[${peer.name.substring(0, 1).toUpperCase()}]',
                    style: const TextStyle(color: AppTheme.terminalGreen, fontWeight: FontWeight.bold),
                  ),
                  title: Text(
                    peer.name.toUpperCase(),
                    style: const TextStyle(color: AppTheme.terminalGreen),
                  ),
                  subtitle: Text(
                    '> ${peer.status.name.toUpperCase()}',
                    style: const TextStyle(color: AppTheme.terminalDarkGreen, fontSize: 10),
                  ),
                  trailing: Icon(
                    peer.isAvailable ? Icons.adjust : Icons.block,
                    color: peer.isAvailable ? AppTheme.terminalGreen : AppTheme.terminalDarkGreen,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          peerId: peer.id,
                          peerName: peer.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('[ ABORT ]', style: TextStyle(color: AppTheme.terminalGreen)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final meshService = context.read<MeshNetworkService>();
    meshService.stopScanning();
    meshService.stopAdvertising();
    super.dispose();
  }
}
