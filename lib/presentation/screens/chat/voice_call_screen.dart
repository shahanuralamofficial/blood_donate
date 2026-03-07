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
    // পারমিশন চেক
    await [
      Permission.microphone,
      if (widget.isVideoCall) Permission.camera,
    ].request();

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
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Error: $err, $msg");
        }
      ),
    );

    // অডিও কনফিগারেশন (উভয় কলের জন্য)
    await _engine.enableAudio();
    await _engine.setEnableSpeakerphone(true);
    await _engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );

    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    }

    // চ্যানেলে জয়েন করা
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
    
    // কল লগ সেভ করা
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
          // ভিডিও ভিউ (শুধুমাত্র ভিডিও কলের জন্য)
          _buildVideoView(),
          
          // কল ইনফো এবং ইউআই
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),
                // ইউজার আইকন এবং নাম
                if (!widget.isVideoCall || _remoteUid == null) ...[
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
                ],
                
                const SizedBox(height: 10),
                // কানেক্টিং বা ডিউরেশন টেক্সট
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isCallConnected 
                        ? _formatDuration(_secondsElapsed) 
                        : "Calling...",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // কল কন্ট্রোল বাটনসমূহ
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // মিউট বাটন
                      _buildActionButton(
                        onPressed: () {
                          setState(() => _muted = !_muted);
                          _engine.muteLocalAudioStream(_muted);
                        },
                        icon: _muted ? Icons.mic_off : Icons.mic,
                        color: _muted ? Colors.red : Colors.white24,
                        label: _muted ? "Unmute" : "Mute",
                      ),
                      
                      // কল এন্ড বাটন
                      _buildActionButton(
                        onPressed: _endCall,
                        icon: Icons.call_end,
                        color: Colors.red,
                        isLarge: true,
                        label: "End",
                      ),
                      
                      // ভিডিও পজ বা ক্যামেরা সুইচ
                      if (widget.isVideoCall)
                        _buildActionButton(
                          onPressed: () => _engine.switchCamera(),
                          icon: Icons.switch_camera,
                          color: Colors.white24,
                          label: "Switch",
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (!widget.isVideoCall) return Container(color: const Color(0xFF1A1A1A));
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
            padding: EdgeInsets.all(isLarge ? 18 : 14),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isLarge ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                )
              ] : null,
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
