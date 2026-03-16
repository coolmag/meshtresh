import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/conversation.dart';
import '../theme/app_theme.dart';

/// A list item showing a conversation preview (Retro Terminal Style)
class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationListItem({
    required this.conversation,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final color = hasUnread ? AppTheme.terminalGreen : AppTheme.terminalDarkGreen;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.terminalDarkGreen, width: 1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            conversation.peerName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '> ${conversation.peerName.toUpperCase()}',
                style: TextStyle(
                  color: color,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (conversation.isPinned)
              const Icon(Icons.push_pin, size: 16, color: AppTheme.terminalDarkGreen),
          ],
        ),
        subtitle: Text(
          conversation.lastMessagePreview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(conversation.lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: color,
                child: Text(
                  '${conversation.unreadCount} NEW',
                  style: const TextStyle(
                    color: AppTheme.terminalPureBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'YDAY';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(timestamp).toUpperCase();
    } else {
      return DateFormat('dd/MM').format(timestamp);
    }
  }
}
