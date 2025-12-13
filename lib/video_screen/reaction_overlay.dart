import 'dart:math';
import 'package:flutter/material.dart';

class ReactionOverlay extends StatefulWidget {
  final Stream<String> reactionStream;
  const ReactionOverlay({super.key, required this.reactionStream});

  @override
  State<ReactionOverlay> createState() => _ReactionOverlayState();
}

class _ReactionOverlayState extends State<ReactionOverlay> {
  final List<Widget> _reactions = [];

  @override
  void initState() {
    super.initState();
    widget.reactionStream.listen(_showReaction);
  }

  void _showReaction(String emoji) {
    if (!mounted) return;
    final id = DateTime.now().millisecondsSinceEpoch;
    final randomX = Random().nextDouble() * 200 - 100;
    setState(() {
      _reactions.add(
        Positioned(
          key: Key(id.toString()),
          bottom: 20,
          right: 20 + (Random().nextDouble() * 50),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            builder: (context, val, child) {
              return Transform.translate(
                offset: Offset(randomX * val * 0.2, -200 * val),
                child: Opacity(
                  opacity: 1 - val,
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              );
            },
            onEnd: () {},
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: _reactions);
  }
}