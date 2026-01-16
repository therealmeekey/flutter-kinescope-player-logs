// Copyright (c) 2021-present, Kinescope
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'package:flutter_kinescope_sdk/src/data/player_parameters.dart';
import 'package:flutter_kinescope_sdk/src/data/player_status.dart';
import 'package:flutter_kinescope_sdk/src/data/player_time_update.dart';
import 'package:flutter_kinescope_sdk/src/player/kinescope_player_navigation.dart';

/// Controls a Kinescope player, and provides status updates using [status] stream.
///
/// The video is displayed in a Flutter app by creating a `KinescopePlayer` widget.
class KinescopePlayerController {
  String _videoId;

  /// Initial `KinescopePlayer` parameters.
  final PlayerParameters parameters;

  /// Diagnostic callback for WebView/JS events inside the player.
  void Function(String message)? onLog;

  /// Picture-in-Picture callback
  void Function(bool)? onChangePip;

  /// Fullscreen callback
  void Function(bool)? onChangeFullscreen;

  /// Playback callback
  void Function(double)? onChangePlaybackRate;

  /// StreamController for [status] stream.
  final statusController = StreamController<KinescopePlayerStatus>();

  /// Controller to communicate with WebView.
  late ControllerProxy controllerProxy = ControllerProxy();

  /// [Stream], that provides current player status
  Stream<KinescopePlayerStatus> get status => statusController.stream;

  /// Currently playing video id
  String get videoId => _videoId;

  /// StreamController for timeUpdate stream.
  final StreamController<KinescopePlayerTimeUpdate> timeUpdateController =
      StreamController<KinescopePlayerTimeUpdate>.broadcast();

  // [Stream] that provides current time of the video
  Stream<KinescopePlayerTimeUpdate> get timeUpdateStream =>
      timeUpdateController.stream;

  KinescopePlayerController(
    /// The video id with which the player initializes.
    String videoId, {
    this.parameters = const PlayerParameters(),
    this.onLog,
    this.onChangePip,
    this.onChangeFullscreen,
    this.onChangePlaybackRate,
  }) : _videoId = videoId {
    timeUpdateStream;
  }

  /// Loads the video as per the [videoId] provided.
  void load(String videoId) {
    try {
      statusController.sink.add(KinescopePlayerStatus.unknown);
      controllerProxy.loadVideo(videoId);
      _videoId = videoId;
    } catch (e, stackTrace) {
      onLog?.call('load_error error=$e videoId=$videoId stackTrace=$stackTrace');
      rethrow;
    }
  }

  /// Plays the video.
  void play() {
    try {
      controllerProxy.play();
    } catch (e, stackTrace) {
      onLog?.call('play_error error=$e stackTrace=$stackTrace');
    }
  }

  /// Pauses the video.
  void pause() {
    try {
      controllerProxy.pause();
    } catch (e, stackTrace) {
      onLog?.call('pause_error error=$e stackTrace=$stackTrace');
    }
  }

  /// Stops the video.
  void stop() {
    try {
      controllerProxy.stop();
    } catch (e, stackTrace) {
      onLog?.call('stop_error error=$e stackTrace=$stackTrace');
    }
  }

  /// Get current position.
  Future<Duration> getCurrentTime() async {
    try {
      return await controllerProxy.getCurrentTime();
    } catch (e, stackTrace) {
      onLog?.call('getCurrentTime_error error=$e stackTrace=$stackTrace');
      return Duration.zero;
    }
  }

  /// Get Playback Rate
  Future<double> getPlaybackRate() async {
    try {
      return await controllerProxy.getPlaybackRate();
    } catch (e, stackTrace) {
      onLog?.call('getPlaybackRate_error error=$e stackTrace=$stackTrace');
      return 1.0;
    }
  }

  /// Is the video on pause?
  Future<bool> isPaused() async {
    try {
      return await controllerProxy.isPaused();
    } catch (e, stackTrace) {
      onLog?.call('isPaused_error error=$e stackTrace=$stackTrace');
      return false;
    }
  }

  /// Get duration of video.
  Future<Duration> getDuration() async {
    try {
      return await controllerProxy.getDuration();
    } catch (e, stackTrace) {
      onLog?.call('getDuration_error error=$e stackTrace=$stackTrace');
      return Duration.zero;
    }
  }

  /// Seek to any position.
  void seekTo(Duration duration) {
    try {
      controllerProxy.seekTo(duration);
    } catch (e, stackTrace) {
      onLog?.call('seekTo_error error=$e duration=$duration stackTrace=$stackTrace');
    }
  }

  void setFullscreen(bool value) {
    try {
      controllerProxy.setFullscreen(value);
    } catch (e, stackTrace) {
      onLog?.call('setFullscreen_error error=$e value=$value stackTrace=$stackTrace');
    }
  }

  /// Set volume level
  /// (0..1, where 0 is 0% and 1 is 100%)
  /// Works only on Android
  void setVolume(double value) {
    try {
      if (value > 0 || value <= 1) {
        controllerProxy.setVolume(value);
      }
    } catch (e, stackTrace) {
      onLog?.call('setVolume_error error=$e value=$value stackTrace=$stackTrace');
    }
  }

  /// Mutes the player.
  void mute() {
    try {
      controllerProxy.mute();
    } catch (e, stackTrace) {
      onLog?.call('mute_error error=$e stackTrace=$stackTrace');
    }
  }

  /// Unmutes the player.
  void unmute() {
    try {
      controllerProxy.unmute();
    } catch (e, stackTrace) {
      onLog?.call('unmute_error error=$e stackTrace=$stackTrace');
    }
  }

  /// Close [statusController] and [timeUpdateController] stream.
  void dispose() {
    try {
      statusController.close();
      timeUpdateController.close();
    } catch (e, stackTrace) {
      onLog?.call('dispose_error error=$e stackTrace=$stackTrace');
    }
  }
}
