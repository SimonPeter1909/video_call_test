import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Call Test',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: VideoCallScreen(),
    );
  }
}

class VideoCallScreen extends StatefulWidget {
  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _joined = false;
  int _remoteUid = null;
  bool _switch = false;

  bool _isCallConnected = false;

  bool _audioDisabled = false;

  RtcEngine engine;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Initialize the app
  Future<void> initPlatformState() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    // Create RTC client instance
    RtcEngineConfig config = RtcEngineConfig(APP_ID);
    engine = await RtcEngine.createWithConfig(config);
    // Define event handling
    engine.setEventHandler(RtcEngineEventHandler(
        joinChannelSuccess: (String channel, int uid, int elapsed) {
      print('joinChannelSuccess $channel $uid');
      setState(() {
        _joined = true;
      });
    }, userJoined: (int uid, int elapsed) {
      print('userJoined $uid');
      setState(() {
        _remoteUid = uid;
      });
    }, userOffline: (int uid, UserOfflineReason reason) {
      print('userOffline $uid');
      setState(() {
        _remoteUid = null;
      });
    }));
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter example app'),
        ),
        body: _isCallConnected
            ? Stack(
                children: [
                  Center(
                    child:
                        _switch ? _renderRemoteVideo() : _renderLocalPreview(),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.blue,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _switch = !_switch;
                          });
                        },
                        child: Center(
                          child: _switch
                              ? _renderLocalPreview()
                              : _renderRemoteVideo(),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                      child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FloatingActionButton(
                            child: Icon(Icons.flip_camera_android),
                            onPressed: () async {
                              await engine.switchCamera();
                            },
                          ),
                          FloatingActionButton(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.call_end),
                            onPressed: () async {
                              await engine.leaveChannel();
                              setState(() {
                                _isCallConnected = false;
                              });
                            },
                          ),
                          FloatingActionButton(
                            child: Icon(
                                _audioDisabled ? Icons.mic : Icons.mic_off),
                            onPressed: () async {
                              setState(() {
                                _audioDisabled = !_audioDisabled;
                              });
                              _audioDisabled
                                  ? await engine.enableAudio()
                                  : await engine.disableAudio();
                            },
                          ),
                        ],
                      ),
                    ),
                  ))
                ],
              )
            : Center(
                child: ElevatedButton(
                  child: Text('Join Call'),
                  onPressed: () async {
                    // Enable video
                    await engine.enableVideo();

                    // Join channel 123
                    await engine.joinChannel(Token, CHANNEL, null, 0);

                    setState(() {
                      _isCallConnected = true;
                    });
                  },
                ),
              ),
      ),
    );
  }

  // Generate local preview
  Widget _renderLocalPreview() {
    if (_joined) {
      return RtcLocalView.SurfaceView();
    } else {
      return Text(
        'Please join channel first',
        textAlign: TextAlign.center,
      );
    }
  }

  // Generate remote preview
  Widget _renderRemoteVideo() {
    if (_remoteUid != null) {
      return RtcRemoteView.SurfaceView(uid: _remoteUid);
    } else {
      return Text(
        'Please wait remote user join',
        textAlign: TextAlign.center,
      );
    }
  }
}
