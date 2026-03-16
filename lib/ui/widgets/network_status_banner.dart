import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/mesh_network_service.dart';
import '../theme/app_theme.dart';

/// Banner showing current network status
class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final meshService = context.watch<MeshNetworkService>();
    final peerCount = meshService.peers.length;
    final onlineCount = meshService.onlinePeers.length;

    Color textColor = AppTheme.terminalGreen;
    String statusStr;
    String message;

    if (onlineCount > 0) {
      statusStr = "[ CONNECTED ]";
      message = '> $onlineCount PEER(S) LINKED';
    } else if (peerCount > 0) {
      statusStr = "[ DETECTING ]";
      message = '> $peerCount SIGNAL(S) IN RANGE';
    } else {
      statusStr = "[ SCANNING ]";
      message = '> NO LOCAL SIGNALS';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.terminalBlack,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.terminalGreen,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NETWORK STATUS:',
                style: TextStyle(
                  color: AppTheme.terminalDarkGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                statusStr,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (meshService.isScanning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.terminalGreen),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
