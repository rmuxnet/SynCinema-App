import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api_service.dart';

class ChatWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Function(String message, bool isSpoiler) onSendMessage;
  final Function(String emoji) onSendReaction;
  final String cookieHeader;

  const ChatWidget({
    super.key, 
    required this.messages, 
    required this.onSendMessage,
    required this.onSendReaction,
    required this.cookieHeader,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSpoiler = false;
  
  // Colors
  final Color chatBg = const Color(0xFF111827); 
  final Color msgOtherBg = const Color(0xFF1F2937); 
  final Color accentColor = const Color(0xFF6366F1);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: chatBg,
      child: Column(
        children: [
          // Quick Reactions
          Container(
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF1F2937), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
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
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(widget.messages[index]),
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1F2937), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
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
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF374151),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
                      decoration: BoxDecoration(color: msgOtherBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.05))),
                      child: Text(msg['message'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
              ],
            ),
          ),
        ],
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