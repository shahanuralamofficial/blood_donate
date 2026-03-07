import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../data/models/message_model.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final String otherUserName;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.otherUserName,
    this.isVideoCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const String appId = "1a3cffb089de46c8bc49934befb8b9d2";
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _videoDisabled = false;
  late RtcEngine _engine;

  // কল টাইম ট্র্যাকিং
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isCallConnected = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [
      Permission.microphone,
      if (widget.isVideoCall) Permission.camera,
    ].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            _isCallConnected = true;
          });
          _startTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _endCall();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (mounted) Navigator.pop(context);
        },
      ),
    );

    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.enableAudio();
      await _engine.setEnableSpeakerphone(true);
      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
    }

    await _engine.joinChannel(
      token: "",
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    
    // কল লগ সেভ করা (যদি কল কানেক্ট হয়ে থাকে)
    if (_isCallConnected && _secondsElapsed > 0) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        final durationStr = _formatDuration(_secondsElapsed);
        final message = MessageModel(
          senderId: currentUid,
          text: widget.isVideoCall ? "ভিডিও কল শেষ হয়েছে" : "ভয়েস কল শেষ হয়েছে",
          timestamp: DateTime.now(),
          type: widget.isVideoCall ? 'video_call' : 'call',
          duration: durationStr,
        );

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.channelId)
            .collection('messages')
            .add(message.toMap());
      }
    }

    await _engine.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          _buildVideoView(),
          if (!widget.isVideoCall || _remoteUid == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.otherUserName,
                    style: GoogleFonts.notoSansBengali(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _remoteUid == null 
                        ? "Calling..." 
                        : "Connected - ${_formatDuration(_secondsElapsed)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  onPressed: () {
                    setState(() => _muted = !_muted);
                    _engine.muteLocalAudioStream(_muted);
                  },
                  icon: _muted ? Icons.mic_off : Icons.mic,
                  color: _muted ? Colors.red : Colors.white24,
                ),
                if (widget.isVideoCall)
                  _buildActionButton(
                    onPressed: () => _engine.switchCamera(),
                    icon: Icons.switch_camera,
                    color: Colors.white24,
                  ),
                _buildActionButton(
                  onPressed: _endCall,
                  icon: Icons.call_end,
                  color: Colors.red,
                  isLarge: true,
                ),
                if (widget.isVideoCall)
                  _buildActionButton(
                    onPressed: () {
                      setState(() => _videoDisabled = !_videoDisabled);
                      _engine.muteLocalVideoStream(_videoDisabled);
                    },
                    icon: _videoDisabled ? Icons.videocam_off : Icons.videocam,
                    color: _videoDisabled ? Colors.red : Colors.white24,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (!widget.isVideoCall) return const SizedBox.shrink();
    return Stack(
      children: [
        Center(
          child: _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channelId),
                  ),
                )
              : Container(color: Colors.black87),
        ),
        if (_localUserJoined && !_videoDisabled)
          Positioned(
            top: 50,
            right: 20,
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: isLarge ? 35 : 28),
      style: IconButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.all(isLarge ? 20 : 15),
      ),
    );
  }
}
