import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api_service.dart';

class ChatWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Function(String message, bool isSpoiler) onSendMessage;
  final Function(String emoji) onSendReaction;
  final Function(String messageId, String emoji) onMessageReaction;
  final String cookieHeader;

  const ChatWidget({
    super.key, 
    required this.messages, 
    required this.onSendMessage,
    required this.onSendReaction,
    required this.onMessageReaction,
    required this.cookieHeader,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSpoiler = false;
  
  final Color chatBg = Colors.black; 
  final Color msgOtherBg = Colors.black; 
  final Color accentColor = const Color(0xFF6366F1);
  final Color borderColor = Colors.white.withOpacity(0.15);

  @override
  void didUpdateWidget(ChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handleSend() {
    if (_msgController.text.trim().isEmpty) return;
    widget.onSendMessage(_msgController.text, _isSpoiler);
    _msgController.clear();
    setState(() => _isSpoiler = false);
  }

  void _showReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 150,
          child: Column(
            children: [
              const Text("React to message", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '👍', '👎', '😮', '😢'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      widget.onMessageReaction(messageId, emoji);
                      Navigator.pop(context);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: chatBg,
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.black, border: Border(bottom: BorderSide(color: borderColor))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['❤️', '😂', '😱', '😢', '🔥'].map((e) => 
                GestureDetector(
                  onTap: () => widget.onSendReaction(e),
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                )
              ).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(widget.messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black, border: Border(top: BorderSide(color: borderColor))),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isSpoiler ? Icons.visibility_off : Icons.visibility, color: _isSpoiler ? Colors.red : Colors.grey),
                  onPressed: () => setState(() => _isSpoiler = !_isSpoiler),
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isSpoiler ? "Type spoiler..." : "Type message...",
                      hintStyle: TextStyle(color: Colors.grey.shade700),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.black,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: accentColor)),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: Icon(Icons.send_rounded, color: accentColor), onPressed: _handleSend),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isSpoiler = msg['spoiler'] == true;
    String avatarUrl = msg['avatar_url'] ?? '';
    String messageId = msg['id'] ?? '';
    Map<String, dynamic> reactions = msg['reactions'] ?? {};

    return GestureDetector(
      onLongPress: () => _showReactionPicker(messageId),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accentColor,
                  child: (avatarUrl.isNotEmpty && widget.cookieHeader.isNotEmpty)
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: "${ApiService.baseUrl}$avatarUrl",
                          httpHeaders: {'Cookie': widget.cookieHeader},
                          fit: BoxFit.cover,
                          width: 28, height: 28,
                          errorWidget: (_, __, ___) => Text(msg['username']?[0] ?? "?", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      )
                    : Text(msg['username']?[0] ?? "?", style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(msg['username'] ?? "System", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(msg['timestamp'] ?? "", style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      isSpoiler 
                        ? _SpoilerText(text: msg['message'] ?? "")
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: msgOtherBg, 
                              borderRadius: BorderRadius.circular(8), 
                              border: Border.all(color: borderColor)
                            ),
                            child: Text(msg['message'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ),
                    ],
                  ),
                ),
              ],
            ),
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 36.0, top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: reactions.entries.map((entry) {
                    String emoji = entry.key;
                    List<dynamic> users = entry.value;
                    bool iReacted = users.contains(ApiService.currentUser);

                    return GestureDetector(
                      onTap: () => widget.onMessageReaction(messageId, emoji),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iReacted ? accentColor.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: iReacted ? accentColor : Colors.white.withOpacity(0.2)
                          ),
                        ),
                        child: Text(
                          "$emoji ${users.length}",
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpoilerText extends StatefulWidget {
  final String text;
  const _SpoilerText({required this.text});
  @override
  State<_SpoilerText> createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<_SpoilerText> {
  bool isRevealed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => isRevealed = !isRevealed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isRevealed ? const Color(0xFF1F2937) : Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isRevealed ? Colors.white.withOpacity(0.05) : Colors.red.withOpacity(0.5)),
        ),
        child: isRevealed
            ? Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 14))
            : Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16), SizedBox(width: 4), Text("SPOILER", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}