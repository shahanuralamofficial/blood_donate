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
  final bool isIncoming; // নতুন প্যারামিটার

  const CallScreen({
    super.key,
    required this.channelId,
    required this.otherUserName,
    this.isVideoCall = false,
    this.isIncoming = false,
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

  // কল স্ট্যাটাস
  bool _hasAccepted = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isCallConnected = false;

  @override
  void initState() {
    super.initState();
    _hasAccepted = !widget.isIncoming; // যদি আউটগোয়িং হয় তবে অটো একসেপ্টেড
    initAgora();
  }

  Future<void> initAgora() async {
    // ইঞ্জিন ইনিশিয়ালাইজ
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined: ${connection.localUid}");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
            _isCallConnected = true;
          });
          _startTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user offline: $remoteUid");
          _endCall();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("Leave channel");
          if (mounted) Navigator.pop(context);
        },
      ),
    );

    // আউটগোয়িং কল হলে সাথে সাথে জয়েন করবে
    if (!widget.isIncoming) {
      _joinChannel();
    }
  }

  Future<void> _joinChannel() async {
    // পারমিশন চেক
    await [
      Permission.microphone,
      if (widget.isVideoCall) Permission.camera,
    ].request();

    await _engine.enableAudio();
    await _engine.setEnableSpeakerphone(true);

    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    }

    await _engine.joinChannel(
      token: "",
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishMicrophoneTrack: true,
        publishCameraTrack: true,
      ),
    );
    
    setState(() {
      _hasAccepted = true;
    });
  }

  void _startTimer() {
    _timer?.cancel();
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
    
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      String messageText;
      String? finalDuration;

      if (_isCallConnected && _secondsElapsed > 0) {
        finalDuration = _formatDuration(_secondsElapsed);
        messageText = widget.isVideoCall ? "ভিডিও কল শেষ হয়েছে" : "ভয়েস কল শেষ হয়েছে";
      } else {
        messageText = widget.isVideoCall ? "মিসড ভিডিও কল" : "মিসড ভয়েস কল";
        finalDuration = null;
      }

      final message = MessageModel(
        senderId: currentUid,
        text: messageText,
        timestamp: DateTime.now(),
        type: widget.isVideoCall ? 'video_call' : 'call',
        duration: finalDuration,
      );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.channelId)
          .collection('messages')
          .add(message.toMap());
    }

    try {
      await _engine.leaveChannel();
    } catch (e) {
      debugPrint("Leave error: $e");
    }
    
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
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80),
                const Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.otherUserName,
                  style: GoogleFonts.notoSansBengali(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isCallConnected 
                      ? _formatDuration(_secondsElapsed) 
                      : (widget.isIncoming && !_hasAccepted ? "Incoming Call..." : "Calling..."),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                
                const Spacer(),
                
                // বাটন এরিয়া
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: widget.isIncoming && !_hasAccepted 
                      ? _buildIncomingControls() // ইনকামিং কলের জন্য Accept/Decline
                      : _buildInCallControls(),   // কল চলাকালীন কন্ট্রোলস
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decline বাটন
        _buildActionButton(
          onPressed: _endCall,
          icon: Icons.call_end,
          color: Colors.red,
          isLarge: true,
          label: "Decline",
        ),
        // Accept বাটন
        _buildActionButton(
          onPressed: _joinChannel,
          icon: widget.isVideoCall ? Icons.videocam : Icons.call,
          color: Colors.green,
          isLarge: true,
          label: "Accept",
        ),
      ],
    );
  }

  Widget _buildInCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          onPressed: () {
            setState(() => _muted = !_muted);
            _engine.muteLocalAudioStream(_muted);
          },
          icon: _muted ? Icons.mic_off : Icons.mic,
          color: _muted ? Colors.red : Colors.white24,
          label: _muted ? "Unmute" : "Mute",
        ),
        _buildActionButton(
          onPressed: _endCall,
          icon: Icons.call_end,
          color: Colors.red,
          isLarge: true,
          label: "End",
        ),
        if (widget.isVideoCall)
          _buildActionButton(
            onPressed: () => _engine.switchCamera(),
            icon: Icons.switch_camera,
            color: Colors.white24,
            label: "Switch",
          ),
      ],
    );
  }

  Widget _buildVideoView() {
    if (!widget.isVideoCall || !_hasAccepted) return Container(color: const Color(0xFF1A1A1A));
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
              : Container(color: Colors.black),
        ),
        if (_localUserJoined && !_videoDisabled)
          Positioned(
            top: 40,
            right: 20,
            width: 110,
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                color: Colors.black54,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
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
    required String label,
    bool isLarge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.all(isLarge ? 20 : 14),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: isLarge ? 32 : 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
