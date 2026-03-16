import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/message.dart';
import '../theme/app_theme.dart';

/// A chat message bubble (Retro Terminal Style)
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    required this.message,
    required this.isMe,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.terminalBlack : AppTheme.terminalPureBlack,
        border: Border(
          left: BorderSide(
            color: isMe ? AppTheme.terminalGreen : AppTheme.terminalDarkGreen, 
            width: 2
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
                isMe ? '[ TX_LOCAL ]' : '[ RX_REMOTE ]',
                style: TextStyle(
                  color: isMe ? AppTheme.terminalGreen : AppTheme.terminalDarkGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: AppTheme.terminalDarkGreen,
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(),
                  ],
                  if (message.hopCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '[HOPS:${message.hopCount}]',
                      style: const TextStyle(
                        color: AppTheme.terminalDarkGreen,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildMessageContent(),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    final content = message.content;
    
    if (content.startsWith('[GEO:')) {
      final coords = content.substring(5, content.length - 1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '> TARGET COORDINATES RECEIVED:',
            style: TextStyle(
              color: AppTheme.terminalGreen,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.terminalGreen),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.satellite_alt, color: AppTheme.terminalGreen),
                const SizedBox(width: 8),
                Text(
                  coords,
                  style: const TextStyle(color: AppTheme.terminalGreen, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (content.startsWith('[IMG:')) {
      final base64Str = content.substring(5, content.length - 1);
      try {
        final bytes = base64Decode(base64Str);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '> VISUAL DATA DECODED:',
              style: TextStyle(
                color: AppTheme.terminalGreen,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.terminalGreen, width: 2),
              ),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      } catch (e) {
        return const Text('> [ERROR DECODING VISUAL DATA]', style: TextStyle(color: AppTheme.errorColor));
      }
    }

    // Default Text Message
    return Text(
      content.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.terminalGreen,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const Text('[..]', style: TextStyle(color: AppTheme.terminalDarkGreen, fontSize: 10));
      case MessageStatus.sent:
        return const Text('[OK]', style: TextStyle(color: AppTheme.terminalGreen, fontSize: 10));
      case MessageStatus.delivered:
        return const Text('[ACK]', style: TextStyle(color: AppTheme.terminalGreen, fontSize: 10));
      case MessageStatus.failed:
        return const Text('[ERR]', style: TextStyle(color: AppTheme.errorColor, fontSize: 10));
      case MessageStatus.relayed:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MM/dd HH:mm').format(timestamp);
    } else {
      return DateFormat('HH:mm:ss').format(timestamp);
    }
  }
}
