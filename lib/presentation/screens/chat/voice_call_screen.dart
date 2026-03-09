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
  RtcEngine? _engine;

  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _videoDisabled = false;
  bool _isSpeakerOn = false;

  bool _hasAccepted = false;
  bool _isCallConnected = false;

  Timer? _timer;
  int _secondsElapsed = 0;

  StreamSubscription<DocumentSnapshot>? _callStreamSubscription;

  @override
  void initState() {
    super.initState();
    _hasAccepted = !widget.isIncoming; 
    _initAgora();
    _listenToCallStatus();
    _updateCallStatus('calling');
  }

  void _listenToCallStatus() {
    final cleanId = widget.channelId.trim();
    debugPrint("Listening to call status for: $cleanId");
    
    _callStreamSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(cleanId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['status'] == 'ended') {
          debugPrint("Call ended detected from Firestore. Closing screen...");
          _endCall(shouldUpdateFirestore: false);
        }
      }
    }, onError: (e) {
      debugPrint("Call Status Listener Error: $e");
    });
  }

  Future<void> _updateCallStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.channelId.trim())
          .set({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
        'callerName': widget.isIncoming ? "" : widget.otherUserName,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Update Call Status Error: $e");
    }
  }

  Future<void> _initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            debugPrint("Local user joined: ${connection.localUid}");
            if (mounted) setState(() => _localUserJoined = true);
          },
          onUserJoined: (connection, uid, elapsed) {
            debugPrint("Remote user joined: $uid");
            if (mounted && uid != 0) {
              setState(() {
                _remoteUid = uid;
              });
              _checkStartTimer();
            }
          },
          onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
            if (state == RemoteAudioState.remoteAudioStateDecoding) {
              debugPrint("Remote audio decoding for: $remoteUid");
              if (mounted && _remoteUid == null) {
                setState(() => _remoteUid = remoteUid);
              }
              _checkStartTimer();
            }
          },
          onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
            if (state == RemoteVideoState.remoteVideoStateDecoding) {
              debugPrint("Remote video decoding for: $remoteUid");
              if (mounted && _remoteUid == null) {
                setState(() => _remoteUid = remoteUid);
              }
              _checkStartTimer();
            }
          },
          onUserOffline: (connection, uid, reason) {
            debugPrint("Remote user left: $uid");
            // যদি অপরপক্ষ কল শেষ করে দেয়, তবে আমাদের ফোন থেকে আর মেসেজ পাঠানোর দরকার নেই
            // কারণ তার ফোন থেকে অলরেডি মেসেজ পাঠানো হয়েছে।
            _endCall(shouldUpdateFirestore: false);
          },
        ),
      );

      if (widget.isVideoCall) {
        await _engine!.enableVideo();
      }
      await _engine!.enableAudio();

      if (!widget.isIncoming) {
        await _joinChannel();
      }
    } catch (e) {
      debugPrint("Agora Init Error: $e");
    }
  }

  Future<void> _joinChannel() async {
    debugPrint("Attempting to join channel: ${widget.channelId.trim()}");
    
    if (_engine == null) {
      await _initAgora();
      if (_engine == null) return;
    }

    try {
      await [
        Permission.microphone,
        if (widget.isVideoCall) Permission.camera,
      ].request();

      if (widget.isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      await _engine!.joinChannel(
        token: "",
        channelId: widget.channelId.trim(),
        uid: 0,
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishMicrophoneTrack: true,
          publishCameraTrack: widget.isVideoCall,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      debugPrint("Join channel command sent. Video: ${widget.isVideoCall}");
    } catch (e) {
      debugPrint("Join Channel Error: $e");
    }
  }

  Future<void> _acceptCall() async {
    debugPrint("Accept button clicked");
    if (mounted) {
      setState(() {
        _hasAccepted = true; 
      });
    }
    await _joinChannel();
    _checkStartTimer();
  }

  void _checkStartTimer() {
    if (_isCallConnected) return;
    
    debugPrint("Checking Timer: _remoteUid=$_remoteUid, _hasAccepted=$_hasAccepted");
    
    if (_remoteUid != null && _remoteUid != 0 && _hasAccepted) {
      if (mounted) {
        setState(() {
          _isCallConnected = true;
          debugPrint("Timer starting now...");
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (mounted) setState(() => _secondsElapsed++);
          });
        });
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall({bool shouldUpdateFirestore = true}) async {
    if (!mounted) return;
    
    // Capture the duration before canceling anything
    final int finalDuration = _secondsElapsed;
    final bool talkHappened = finalDuration > 0;
    
    debugPrint("Ending call. Duration: $finalDuration, Talk Happened: $talkHappened");
    
    _timer?.cancel();
    _callStreamSubscription?.cancel();

    if (shouldUpdateFirestore) {
      await _updateCallStatus('ended');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String cleanChannelId = widget.channelId.trim();

    if (uid != null && cleanChannelId.isNotEmpty && shouldUpdateFirestore) {
      String messageText;
      String? durationStr;

      if (talkHappened) {
        messageText = widget.isVideoCall ? "ভিডিও কল শেষ হয়েছে" : "ভয়েস কল শেষ হয়েছে";
        durationStr = _formatDuration(finalDuration);
      } else {
        messageText = widget.isVideoCall ? "মিসড ভিডিও কল" : "মিসড ভয়েস কল";
        durationStr = null;
      }

      try {
        final Map<String, dynamic> messageData = {
          'senderId': uid,
          'text': messageText,
          'timestamp': FieldValue.serverTimestamp(),
          'type': widget.isVideoCall ? 'video_call' : 'call',
          'duration': durationStr,
          'isRead': false,
        };

        // Correct collection for this app is 'direct_chats'
        final chatDocRef = FirebaseFirestore.instance.collection('direct_chats').doc(cleanChannelId);
        
        // 1. Add message to the messages sub-collection
        await chatDocRef.collection('messages').add(messageData);

        // 2. Update chat metadata for the chat list
        await chatDocRef.set({
          'lastMessage': messageText,
          'lastMessageSenderId': uid,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'unread': true,
        }, SetOptions(merge: true));

        debugPrint("Call log saved successfully to direct_chats/$cleanChannelId");
      } catch (e) {
        debugPrint("CRITICAL: Firestore Message Save Error: $e");
      }
    }

    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
      }
    } catch (e) {
      debugPrint("Agora Cleanup Error: $e");
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callStreamSubscription?.cancel();
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoView(),
          Container(color: Colors.black.withAlpha(76)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80),
                _buildUserInfo(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: widget.isIncoming && !_hasAccepted
                      ? _buildIncomingControls()
                      : _buildInCallControls(),
                ),
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
        const CircleAvatar(
          radius: 60,
          backgroundColor: Colors.redAccent,
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          widget.otherUserName,
          style: GoogleFonts.notoSansBengali(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _isCallConnected
              ? _formatDuration(_secondsElapsed)
              : (widget.isIncoming && !_hasAccepted ? "ইনকামিং কল..." : "কল হচ্ছে..."),
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildIncomingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          onPressed: _endCall,
          icon: Icons.call_end,
          color: Colors.red,
          label: "বাতিল",
          isLarge: true,
        ),
        _buildActionButton(
          onPressed: _acceptCall,
          icon: widget.isVideoCall ? Icons.videocam : Icons.call,
          color: Colors.green,
          label: "রিসিভ",
          isLarge: true,
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
            if (_engine != null) {
              setState(() => _muted = !_muted);
              _engine!.muteLocalAudioStream(_muted);
            }
          },
          icon: _muted ? Icons.mic_off : Icons.mic,
          color: _muted ? Colors.red : Colors.white24,
          label: _muted ? "আনমিউট" : "মিউট",
        ),
        _buildActionButton(
          onPressed: () {
            if (_engine != null) {
              setState(() => _isSpeakerOn = !_isSpeakerOn);
              _engine!.setEnableSpeakerphone(_isSpeakerOn);
            }
          },
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
          color: _isSpeakerOn ? Colors.blue : Colors.white24,
          label: _isSpeakerOn ? "লাউড" : "স্পিকার",
        ),
        _buildActionButton(
          onPressed: _endCall,
          icon: Icons.call_end,
          color: Colors.red,
          label: "শেষ",
          isLarge: true,
        ),
        if (widget.isVideoCall)
          _buildActionButton(
            onPressed: () => _engine?.switchCamera(),
            icon: Icons.switch_camera,
            color: Colors.white24,
            label: "ক্যামেরা",
          ),
      ],
    );
  }

  Widget _buildVideoView() {
    if (!widget.isVideoCall || !_hasAccepted || _engine == null) {
      return Container(color: const Color(0xFF1A1A1A));
    }
    return Stack(
      children: [
        Center(
          child: _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channelId.trim()),
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
                decoration: BoxDecoration(
                  color: Colors.black54,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
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
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            padding: EdgeInsets.all(isLarge ? 20 : 14),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isLarge ? 32 : 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.notoSansBengali(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
