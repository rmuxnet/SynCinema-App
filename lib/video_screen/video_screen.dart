import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api_service.dart';
import 'chat_widget.dart';
import 'reaction_overlay.dart';

class VideoScreen extends StatefulWidget {
  final String movieFilename;
  const VideoScreen({super.key, required this.movieFilename});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  IO.Socket? socket;
  
  bool _isSyncing = false;
  bool _isVideoInitialized = false;
  String _errorMessage = '';
  String _cookieHeader = '';
  
  final List<Map<String, dynamic>> _messages = [];
  final StreamController<String> _reactionStreamController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _initSocket();
  }

  Future<void> _initPlayer() async {
    try {
      _cookieHeader = await ApiService.getCookieHeader();
      final url = ApiService.getMovieUrl(widget.movieFilename);
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: {'Cookie': _cookieHeader},
      );
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(playedColor: const Color(0xFF6366F1), handleColor: Colors.white, backgroundColor: Colors.grey.shade800, bufferedColor: Colors.white24),
        errorBuilder: (context, errorMessage) => Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red))),
      );
      
      _videoController!.addListener(_onVideoStateChange);
      if (mounted) setState(() => _isVideoInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Error: $e");
    }
  }

  Future<void> _initSocket() async {
    try {
      String cookieHeader = await ApiService.getCookieHeader();
      socket = IO.io(ApiService.baseUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Cookie': cookieHeader})
          .build());
      socket!.connect();
      socket!.onConnect((_) => socket!.emit('change_movie', {'movie': widget.movieFilename}));
      
      socket!.on('play_video', (data) { if(_isVideoInitialized) { _handleRemoteSeek(data['time']); _handleRemotePlay(); }});
      socket!.on('pause_video', (data) { if(_isVideoInitialized) { _handleRemoteSeek(data['time']); _handleRemotePause(); }});
      socket!.on('seek_video', (data) => _handleRemoteSeek(data['time']));
      socket!.on('sync_state', (data) { if(data['current_time']!=null) _handleRemoteSeek(data['current_time']); if(data['is_playing']==true) _handleRemotePlay();});
      
      socket!.on('new_message', (data) => _addMessage(data));
      socket!.on('chat_history', (data) { if (data is List) for (var msg in data) _addMessage(msg); });
      socket!.on('new_reaction', (data) => _reactionStreamController.add(data['emoji']));

      socket!.on('message_reaction_update', (data) {
        if (!mounted) return;
        setState(() {
          for (var msg in _messages) {
            if (msg['id'] == data['message_id']) {
              msg['reactions'] = data['reactions'];
              break;
            }
          }
        });
      });

    } catch (e) { print(e); }
  }

  void _handleRemotePlay() { _isSyncing = true; _videoController?.play().then((_) => Future.delayed(const Duration(milliseconds: 500), () => _isSyncing = false)); }
  void _handleRemotePause() { _isSyncing = true; _videoController?.pause().then((_) => Future.delayed(const Duration(milliseconds: 500), () => _isSyncing = false)); }
  void _handleRemoteSeek(dynamic time) { 
    if (_videoController == null) return;
    double t = (time is int) ? time.toDouble() : time;
    if ((_videoController!.value.position.inSeconds - t).abs() > 1) {
       _isSyncing = true; 
       _videoController!.seekTo(Duration(milliseconds: (t * 1000).toInt())).then((_) => Future.delayed(const Duration(milliseconds: 1000), () => _isSyncing = false)); 
    }
  }

  bool _wasPlaying = false;
  void _onVideoStateChange() {
    if (_videoController == null || socket == null || _isSyncing) return;
    final isPlaying = _videoController!.value.isPlaying;
    final currentTime = _videoController!.value.position.inSeconds.toDouble();
    if (isPlaying && !_wasPlaying) socket!.emit('play', {'time': currentTime});
    else if (!isPlaying && _wasPlaying) socket!.emit('pause', {'time': currentTime});
    _wasPlaying = isPlaying;
  }

  void _addMessage(dynamic data) {
    if (mounted) setState(() => _messages.add(data));
  }

  void _onSendMessage(String text, bool isSpoiler) {
    socket!.emit('send_message', {'message': text, 'spoiler': isSpoiler});
  }

  void _onSendReaction(String emoji) {
    socket!.emit('send_reaction', {'emoji': emoji, 'video_time': _videoController?.value.position.inSeconds ?? 0});
  }

  void _onMessageReaction(String messageId, String emoji) {
    socket!.emit('react_to_message', {'message_id': messageId, 'emoji': emoji});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    socket?.disconnect();
    _reactionStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final videoWidget = Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _isVideoInitialized 
            ? Chewie(controller: _chewieController!)
            : Center(child: _errorMessage.isEmpty ? const CircularProgressIndicator() : Text(_errorMessage, style: const TextStyle(color: Colors.red))),
          ReactionOverlay(reactionStream: _reactionStreamController.stream),
        ],
      ),
    );

    final chatWidget = ChatWidget(
      messages: _messages,
      onSendMessage: _onSendMessage,
      onSendReaction: _onSendReaction,
      onMessageReaction: _onMessageReaction,
      cookieHeader: _cookieHeader,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: isLandscape ? null : AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        title: Text(widget.movieFilename.split('.').first, style: const TextStyle(fontSize: 16)),
      ),
      body: SafeArea(
        top: !isLandscape,
        left: false, right: false,
        child: isLandscape 
          ? Row(children: [Expanded(flex: 2, child: videoWidget), Expanded(flex: 1, child: chatWidget)])
          : Column(children: [SizedBox(height: 250, child: videoWidget), Expanded(child: chatWidget)]),
      ),
    );
  }
}