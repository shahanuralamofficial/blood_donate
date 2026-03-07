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
  final bool isIncoming;

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
  RtcEngine? _engine;
  bool _isEngineReady = false;

  // কল স্ট্যাটাস
  bool _hasAccepted = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isCallConnected = false;

  @override
  void initState() {
    super.initState();
    _hasAccepted = !widget.isIncoming;
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      await [
        Permission.microphone,
        if (widget.isVideoCall) Permission.camera,
      ].request();

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) setState(() => _localUserJoined = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
                _isCallConnected = true;
              });
              _startTimer();
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _onExitPressed();
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint("Leaved");
          },
        ),
      );

      await _engine!.enableAudio();
      await _engine!.setEnableSpeakerphone(true);

      if (widget.isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      setState(() => _isEngineReady = true);

      if (!widget.isIncoming) {
        _joinChannel();
      }
    } catch (e) {
      debugPrint("Agora Error: $e");
    }
  }

  Future<void> _joinChannel() async {
    if (_engine == null) return;
    try {
      await _engine!.joinChannel(
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
      if (mounted) setState(() => _hasAccepted = true);
    } catch (e) {
      debugPrint("Join Error: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // বাটন ক্লিক করার সাথে সাথে কল স্ক্রিন বন্ধ হবে
  void _onExitPressed() {
    if (mounted) Navigator.of(context).pop();
    _cleanupAndSaveInBackground();
  }

  Future<void> _cleanupAndSaveInBackground() async {
    _timer?.cancel();
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      String msg = widget.isVideoCall ? "মিসড ভিডিও কল" : "মিসড ভয়েস কল";
      String? duration;

      if (_isCallConnected && _secondsElapsed > 0) {
        msg = widget.isVideoCall ? "ভিডিও কল শেষ হয়েছে" : "ভয়েস কল শেষ হয়েছে";
        duration = _formatDuration(_secondsElapsed);
      }

      // ফায়ারস্টোরে লগ সেভ
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.channelId)
          .collection('messages')
          .add(MessageModel(
            senderId: uid,
            text: msg,
            timestamp: DateTime.now(),
            type: widget.isVideoCall ? 'video_call' : 'call',
            duration: duration,
          ).toMap());
    }

    // ইঞ্জিন বন্ধ
    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ভিডিও/ব্যাকগ্রাউন্ড
          _buildVideoView(),
          
          // কালো ওভারলে
          Container(color: Colors.black.withOpacity(0.4)),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80),
                if (!widget.isVideoCall || _remoteUid == null)
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.person, size: 70, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.otherUserName,
                          style: GoogleFonts.notoSansBengali(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isCallConnected 
                              ? _formatDuration(_secondsElapsed) 
                              : (widget.isIncoming && !_hasAccepted ? "ইনকামিং কল..." : "কল হচ্ছে..."),
                          style: GoogleFonts.notoSansBengali(color: Colors.white70, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                // বাটন এরিয়া - সবার উপরে রাখা হয়েছে
                Padding(
                  padding: const EdgeInsets.only(bottom: 70),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: widget.isIncoming && !_hasAccepted 
                        ? [
                            _buildActionButton(onTap: _onExitPressed, icon: Icons.call_end, color: Colors.red, label: "বাতিল"),
                            _buildActionButton(onTap: _joinChannel, icon: Icons.call, color: Colors.green, label: "রিসিভ"),
                          ]
                        : [
                            _buildActionButton(
                              onTap: () {
                                if (_engine != null) {
                                  setState(() => _muted = !_muted);
                                  _engine!.muteLocalAudioStream(_muted);
                                }
                              }, 
                              icon: _muted ? Icons.mic_off : Icons.mic, 
                              color: _muted ? Colors.red : Colors.white24, 
                              label: _muted ? "আনমিউট" : "মিউট"
                            ),
                            _buildActionButton(onTap: _onExitPressed, icon: Icons.call_end, color: Colors.red, label: "শেষ", isLarge: true),
                            if (widget.isVideoCall)
                              _buildActionButton(onTap: () => _engine?.switchCamera(), icon: Icons.switch_camera, color: Colors.white24, label: "ক্যামেরা"),
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

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required String label,
    bool isLarge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: isLarge ? 80 : 65,
          height: isLarge ? 80 : 65,
          child: FloatingActionButton(
            heroTag: label, // ইউনিক ট্যাগ
            onPressed: onTap,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: isLarge ? 35 : 28),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildVideoView() {
    if (!widget.isVideoCall || !_hasAccepted || _engine == null) return Container(color: Colors.black);
    return Stack(
      children: [
        _remoteUid != null
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelId),
                ),
              )
            : Container(color: Colors.black),
        if (_localUserJoined)
          Positioned(
            top: 50,
            right: 20,
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
