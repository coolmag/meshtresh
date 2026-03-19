import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/mesh_network_service.dart';

/// Screen showing detailed network status and connected peers
class NetworkStatusScreen extends StatelessWidget {
  const NetworkStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meshService = context.watch<MeshNetworkService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статус сети'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(
            context,
            'Статус сети',
            [
              _statusRow('Сканирование', meshService.isScanning ? 'Активно' : 'Неактивно'),
              _statusRow('Вещание', meshService.isAdvertising ? 'Активно' : 'Неактивно'),
              _statusRow('ID устройства', meshService.deviceId ?? 'Не задано'),
              _statusRow('Имя устройства', meshService.deviceName ?? 'Не задано'),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            context,
            'Подключенные узлы',
            [
              _statusRow('Всего узлов', '${meshService.peers.length}'),
              _statusRow('В сети', '${meshService.onlinePeers.length}'),
              _statusRow('Поблизости', '${meshService.peers.where((p) => p.status.name == 'nearby').length}'),
            ],
          ),
          const SizedBox(height: 16),
          _buildPeersList(context, meshService),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeersList(BuildContext context, MeshNetworkService meshService) {
    final peers = meshService.peers;

    if (peers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.devices_other, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Узлы пока не обнаружены',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Обнаруженные узлы',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: peers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final peer = peers[index];
              final statusColor = peer.isAvailable ? Colors.green : Colors.grey;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Text(
                    peer.name[0].toUpperCase(),
                    style: TextStyle(color: statusColor),
                  ),
                ),
                title: Text(peer.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${peer.deviceType} • ${peer.status.name}'),
                    if (peer.signalStrength != 0)
                      Text(
                        'Сигнал: ${peer.connectionQuality}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                trailing: Icon(
                  Icons.circle,
                  color: statusColor,
                  size: 12,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
