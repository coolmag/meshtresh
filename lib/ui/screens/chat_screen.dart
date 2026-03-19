import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/message.dart';
import '../../core/services/mesh_network_service.dart';
import '../../core/services/message_storage_service.dart';
import '../../core/di/service_locator.dart';
import '../widgets/message_bubble.dart';
import '../theme/app_theme.dart';

/// Chat screen for messaging with a specific peer (Retro Terminal Style)
class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatScreen({
    required this.peerId,
    required this.peerName,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _storageService = getIt<MessageStorageService>();
  final _uuid = const Uuid();
  
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupMessageListener();
  }

  void _loadMessages() {
    final meshService = context.read<MeshNetworkService>();
    final deviceId = meshService.deviceId ?? '';
    
    setState(() {
      _messages = _storageService.getMessagesForConversation(
        widget.peerId,
        deviceId,
      );
    });

    // Mark conversation as read
    final conversation = _storageService.getConversationByPeer(widget.peerId);
    if (conversation != null) {
      _storageService.markConversationAsRead(conversation.id);
    }
    
    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _setupMessageListener() {
    final meshService = context.read<MeshNetworkService>();
    meshService.onMessageReceived = (message) {
      if (message.senderId == widget.peerId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        
        // Save message
        _storageService.saveMessage(message);
        _storageService.updateConversationWithMessage(
          message,
          meshService.deviceId ?? '',
          widget.peerName,
        );
      }
    };
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _sendRawMessage(text);
  }

  Future<void> _sendLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      _sendRawMessage('[GEO:${position.latitude},${position.longitude}]');
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _sendPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600, // Compress for mesh network
        imageQuality: 50,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        _sendRawMessage('[IMG:$base64Image]');
      }
    } catch (e) {
      debugPrint('Photo error: $e');
    }
  }

  void _sendRawMessage(String content) {
    final meshService = context.read<MeshNetworkService>();
    final deviceId = meshService.deviceId ?? '';

    final message = Message(
      id: _uuid.v4(),
      senderId: deviceId,
      recipientId: widget.peerId,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();

    // Send through mesh network
    meshService.sendMessage(message).then((success) {
      if (success) {
        final updatedMessage = message.copyWith(status: MessageStatus.sent);
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
        _storageService.saveMessage(updatedMessage);
      } else {
        final updatedMessage = message.copyWith(status: MessageStatus.failed);
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
        _storageService.saveMessage(updatedMessage);
      }
    });

    // Update conversation
    _storageService.updateConversationWithMessage(
      message,
      deviceId,
      widget.peerName,
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100), // Faster scroll for retro feel
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final meshService = context.watch<MeshNetworkService>();
    final peer = meshService.peers.where((p) => p.id == widget.peerId).firstOrNull;
    final isOnline = peer?.isAvailable ?? false;

    return Scaffold(
      backgroundColor: AppTheme.terminalPureBlack,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('> ${widget.peerName.toUpperCase()}'),
            Text(
              isOnline ? '[ LINK_ACTIVE ]' : '[ LINK_LOST ]',
              style: TextStyle(
                color: isOnline ? AppTheme.terminalGreen : AppTheme.errorColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showPeerInfo(peer);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: AppTheme.errorColor,
              child: const Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.terminalPureBlack, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'УЗЕЛ НЕ В СЕТИ. TX БУДЕТ В ОЧЕРЕДИ НА ПОВТОРНУЮ ПОПЫТКУ.',
                      style: TextStyle(
                        color: AppTheme.terminalPureBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.terminal,
              size: 64,
              color: AppTheme.terminalDarkGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              '> БЕЗОПАСНЫЙ КАНАЛ УСТАНОВЛЕН',
              style: TextStyle(
                color: AppTheme.terminalDarkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ОЖИДАНИЕ ВВОДА...',
              style: TextStyle(
                color: AppTheme.terminalDarkGreen.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final meshService = context.read<MeshNetworkService>();
    final currentUserId = meshService.deviceId ?? '';

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == currentUserId;
        
        return MessageBubble(
          message: message,
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppTheme.terminalBlack,
        border: Border(top: BorderSide(color: AppTheme.terminalGreen, width: 2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _sendPhoto,
            icon: const Icon(Icons.camera_alt),
            color: AppTheme.terminalGreen,
            tooltip: 'Отправить фото',
          ),
          IconButton(
            onPressed: _sendLocation,
            icon: const Icon(Icons.location_on),
            color: AppTheme.terminalGreen,
            tooltip: 'Отправить геопозицию',
          ),
          const Text('> ', style: TextStyle(color: AppTheme.terminalGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: AppTheme.terminalGreen, fontFamily: 'Courier', fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'ВВЕДИТЕ TX...',
                hintStyle: TextStyle(color: AppTheme.terminalDarkGreen),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: AppTheme.terminalGreen,
          ),
        ],
      ),
    );
  }

  void _showPeerInfo(dynamic peer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.terminalPureBlack,
        shape: Border.all(color: AppTheme.terminalGreen, width: 2),
        title: Text('> СИСТ_ИНФО: ${widget.peerName.toUpperCase()}', style: const TextStyle(color: AppTheme.terminalGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('ID', widget.peerId),
            _infoRow('STAT', peer?.status.name.toUpperCase() ?? 'UNKNOWN'),
            _infoRow('TYPE', peer?.deviceType.toUpperCase() ?? 'UNKNOWN'),
            if (peer != null) ...[
              _infoRow('SIG', '${peer.connectionQuality}%'),
              _infoRow('TX/RX', '${_messages.length} ПАКЕТОВ'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('[ ЗАКРЫТЬ ]', style: TextStyle(color: AppTheme.terminalGreen)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppTheme.terminalDarkGreen, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.terminalGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
