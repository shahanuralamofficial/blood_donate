import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // Permissions
    await [
      Permission.microphone,
      if (widget.isVideoCall) Permission.camera,
    ].request();

    // Create the engine
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
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
          Navigator.pop(context);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          Navigator.pop(context);
        },
      ),
    );

    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.enableAudio();
      // ভয়েস কলের জন্য স্পিকারফোন অন করা এবং অডিও সিনারিও সেট করা
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

  @override
  void dispose() {
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
          // Background / Video Views
          _buildVideoView(),
          
          // Overlay UI
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
                    _remoteUid == null ? "Calling..." : "Connected",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          
          // Call Controls
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
                    onPressed: () {
                      _engine.switchCamera();
                    },
                    icon: Icons.switch_camera,
                    color: Colors.white24,
                  ),
                _buildActionButton(
                  onPressed: () => Navigator.pop(context),
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
