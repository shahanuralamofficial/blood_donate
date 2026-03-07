import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _hasAccepted = false;
  
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isCallConnected = false;
  Timer? _ringingTimer;

  @override
  void initState() {
    super.initState();
    _hasAccepted = !widget.isIncoming;
    _initAgora();
    
    if (widget.isIncoming) {
      _startRingingEffect();
    }

    _ringingTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && !_isCallConnected) {
        debugPrint("Call timeout - no connection established");
        _onExitPressed();
      }
    });
  }

  void _startRingingEffect() {
    // এখানে আপনি audioplayers ব্যবহার করে রিংটোন বাজাতে পারেন
    // আপাতত হ্যাপটিক ফিডব্যাক দেওয়া হচ্ছে
    HapticFeedback.vibrate();
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _isCallConnected || _hasAccepted) {
        timer.cancel();
      } else {
        HapticFeedback.vibrate();
      }
    });
  }

  Future<void> _initAgora() async {
    try {
      debugPrint("Initializing Agora for channel: ${widget.channelId.trim()}");
      final statuses = await [
        Permission.microphone,
        if (widget.isVideoCall) Permission.camera,
      ].request();

      if (statuses[Permission.microphone] != PermissionStatus.granted ||
          (widget.isVideoCall && statuses[Permission.camera] != PermissionStatus.granted)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("কল করার জন্য মাইক্রোফোন ও ক্যামেরা পারমিশন প্রয়োজন"))
          );
        }
        _onExitPressed();
        return;
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Join success: ${connection.localUid}");
            if (mounted) setState(() => _localUserJoined = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("User joined callback: $remoteUid");
            if (mounted) {
              setState(() => _remoteUid = remoteUid);
              // ইনকামিং কলের ক্ষেত্রে যদি অলরেডি একসেপ্ট করা থাকে, তবে কানেকশন চেক করবে।
              if (_hasAccepted && widget.isIncoming) {
                debugPrint("Receiver already accepted, checking connection.");
                _startCallConnection();
              }
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint("User offline: $remoteUid");
            _onExitPressed();
          },
          onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
            debugPrint("Remote audio state changed: $remoteUid, state: $state");
            if (state == RemoteAudioState.remoteAudioStateDecoding && _hasAccepted) {
              if (mounted) setState(() => _remoteUid = remoteUid);
              _startCallConnection();
            }
          },
        ),
      );

      await _engine!.enableAudio();
      await _engine!.setEnableSpeakerphone(true);
      await _engine!.setParameters('{"che.audio.opensl":true}');
      
      if (widget.isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      await _engine!.joinChannel(
        token: "",
        channelId: widget.channelId.trim(),
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: _hasAccepted,
          publishCameraTrack: widget.isVideoCall && _hasAccepted,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      debugPrint("Agora Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("কল সংযোগে ত্রুটি হয়েছে")));
        _onExitPressed();
      }
    }
  }

  void _startCallConnection() {
    if (_isCallConnected) return;
    _ringingTimer?.cancel(); // স্টপ টাইমার যদি কানেক্ট হয়ে যায়
    if (mounted) {
      setState(() => _isCallConnected = true);
      _startTimer();
    }
  }

  Future<void> _acceptCall() async {
    if (_engine == null) return;
    debugPrint("Accepting call... Current Remote UID: $_remoteUid");
    try {
      // Ensure we use the correct media options for the call type
      await _engine!.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishMicrophoneTrack: true,
          publishCameraTrack: widget.isVideoCall,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      
      await _engine!.muteLocalAudioStream(false);
      if (widget.isVideoCall) {
        await _engine!.muteLocalVideoStream(false);
      }
      
      if (mounted) {
        setState(() {
          _hasAccepted = true;
          // If the remote user is already here, connect immediately
          if (_remoteUid != null) {
            debugPrint("Remote user already present, starting connection.");
            _startCallConnection();
          } else {
            debugPrint("Call accepted, waiting for remote user to join...");
          }
        });
      }
    } catch (e) {
      debugPrint("Accept Call Error: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onExitPressed() {
    if (!mounted) return;
    Navigator.of(context).pop();
    _cleanupAndSave();
  }

  Future<void> _cleanupAndSave() async {
    _timer?.cancel();
    _timer = null;
    _ringingTimer?.cancel();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    // ডুপ্লিকেট মেসেজ এড়াতে শুধুমাত্র কলার (Initiator) মেসেজটি চ্যাটে সেভ করবে।
    if (uid != null && !widget.isIncoming) {
      String msg = widget.isVideoCall ? "মিসড ভিডিও কল" : "মিসড ভয়েস কল";
      String? duration;
      if (_isCallConnected && _secondsElapsed > 0) {
        msg = widget.isVideoCall ? "ভিডিও কল শেষ হয়েছে" : "ভয়েস কল শেষ হয়েছে";
        duration = _formatDuration(_secondsElapsed);
      }
      
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.channelId.trim())
          .collection('messages')
          .add(MessageModel(
            senderId: uid,
            text: msg,
            timestamp: DateTime.now(),
            type: widget.isVideoCall ? 'video_call' : 'call',
            duration: duration,
          ).toMap());
    }
    
    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoView(),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80),
                _buildUserInfo(),
                const Spacer(),
                _buildControls(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        if (!widget.isVideoCall || _remoteUid == null)
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            child: const Icon(Icons.person, size: 60, color: Colors.white),
          ),
        const SizedBox(height: 20),
        Text(
          widget.otherUserName,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _isCallConnected 
              ? _formatDuration(_secondsElapsed) 
              : (widget.isIncoming && !_hasAccepted ? "ইনকামিং কল..." : "কল হচ্ছে..."),
          style: GoogleFonts.notoSansBengali(color: Colors.white70, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildControls() {
    if (widget.isIncoming && !_hasAccepted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleBtn(onTap: _onExitPressed, icon: Icons.call_end, color: Colors.red, label: "বাতিল"),
          _buildCircleBtn(onTap: _acceptCall, icon: widget.isVideoCall ? Icons.videocam : Icons.call, color: Colors.green, label: "রিসিভ"),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleBtn(
          onTap: () {
            if (_engine != null) {
              setState(() => _muted = !_muted);
              _engine!.muteLocalAudioStream(_muted);
            }
          },
          icon: _muted ? Icons.mic_off : Icons.mic,
          color: _muted ? Colors.red : Colors.white24,
          label: _muted ? "আনমিউট" : "মিউট",
        ),
        _buildCircleBtn(onTap: _onExitPressed, icon: Icons.call_end, color: Colors.red, label: "শেষ", isLarge: true),
        if (widget.isVideoCall)
          _buildCircleBtn(onTap: () => _engine?.switchCamera(), icon: Icons.switch_camera, color: Colors.white24, label: "ক্যামেরা"),
      ],
    );
  }

  Widget _buildCircleBtn({required VoidCallback onTap, required IconData icon, required Color color, String? label, bool isLarge = false}) {
    double size = isLarge ? 80 : 65;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 8,
            ),
            child: Icon(icon, size: size * 0.45),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 14)),
        ]
      ],
    );
  }

  Widget _buildVideoView() {
    if (!widget.isVideoCall || _engine == null) return Container(color: Colors.black);
    
    // ইনকামিং কল রিসিভ করার আগে নিজের প্রিভিউ দেখা যাবে
    if (widget.isIncoming && !_hasAccepted) {
       return _localUserJoined 
           ? AgoraVideoView(controller: VideoViewController(rtcEngine: _engine!, canvas: const VideoCanvas(uid: 0)))
           : Container(color: Colors.black);
    }

    return Stack(
      children: [
        // মেইন উইন্ডো: রিমোট ইউজার থাকলে তাকে দেখাবে, নাহলে নিজের ভিডিও ফুল স্ক্রিনে দেখাবে
        _remoteUid != null
            ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelId.trim()),
                ),
              )
            : (_localUserJoined 
                ? AgoraVideoView(controller: VideoViewController(rtcEngine: _engine!, canvas: const VideoCanvas(uid: 0)))
                : Container(color: Colors.black)),
        
        // PIP (Picture-in-Picture): কল কানেক্টেড হলে নিজের ভিডিও ছোট করে উপরে দেখাবে
        if (_localUserJoined && _remoteUid != null)
          Positioned(
            top: 50,
            right: 20,
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  border: Border.all(color: Colors.white24, width: 1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AgoraVideoView(
                  controller: VideoViewController(rtcEngine: _engine!, canvas: const VideoCanvas(uid: 0)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
