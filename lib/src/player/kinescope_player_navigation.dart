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

import '../utils/uri_builder.dart';

typedef LoadVideoCallback = void Function(String videoId);
typedef MethodCallback = void Function();
typedef SeekToCallback = void Function(Duration offset);
typedef SetVolumeCallback = void Function(double volume);
typedef SetFullscreenCallback = void Function(bool value);
typedef GetCurrentTimeCallback = Future<Duration> Function();
typedef GetIsPausedCallback = Future<bool> Function();
typedef GetPlayBackRateCallback = Future<double> Function();
typedef GetDurationCallback = Future<Duration> Function();

class ControllerProxy {
  LoadVideoCallback? _loadVideoCallback;
  MethodCallback? _playCallback;
  MethodCallback? _pauseCallback;
  MethodCallback? _stopCallback;
  MethodCallback? _muteCallback;
  MethodCallback? _unmuteCallback;
  SeekToCallback? _seekToCallback;
  SetFullscreenCallback? _setFullscreenCallback;
  SetVolumeCallback? _setVolumeCallback;
  GetPlayBackRateCallback? _getPlaybackRateCallback;
  GetCurrentTimeCallback? _getCurrentTimeCallback;
  GetIsPausedCallback? _getIsPausedCallback;
  GetDurationCallback? _getDurationCallback;

  void loadVideo(String videoId) {
    final callback = _loadVideoCallback;
    if (callback != null) {
      callback('${UriBuilder.buildVideoUri(videoId: videoId)}');
    }
  }

  void play() {
    final callback = _playCallback;
    if (callback != null) {
      callback();
    }
  }

  void pause() {
    final callback = _pauseCallback;
    if (callback != null) {
      callback();
    }
  }

  void stop() {
    final callback = _stopCallback;
    if (callback != null) {
      callback();
    }
  }

  void mute() {
    final callback = _muteCallback;
    if (callback != null) {
      callback();
    }
  }

  void unmute() {
    final callback = _unmuteCallback;
    if (callback != null) {
      callback();
    }
  }

  void seekTo(Duration offset) {
    final callback = _seekToCallback;
    if (callback != null) {
      callback(offset);
    }
  }

  void setVolume(double volume) {
    final callback = _setVolumeCallback;
    if (callback != null) {
      callback(volume);
    }
  }

  void setFullscreen(bool value) {
    final callback = _setFullscreenCallback;
    if (callback != null) {
      callback(value);
    }
  }

  Future<Duration> getCurrentTime() {
    final callback = _getCurrentTimeCallback;
    if (callback != null) {
      return callback();
    }
    return Future.value(Duration.zero);
  }

  Future<double> getPlaybackRate() {
    final callback = _getPlaybackRateCallback;
    if (callback != null) {
      return callback();
    }
    return Future.value(1.0);
  }

  Future<bool> isPaused() {
    final callback = _getIsPausedCallback;
    if (callback != null) {
      return callback();
    }
    return Future.value(false);
  }

  Future<Duration> getDuration() {
    final callback = _getDurationCallback;
    if (callback != null) {
      return callback();
    }
    return Future.value(Duration.zero);
  }

  Future<void> setLoadVideoCallback(
    LoadVideoCallback loadVideoCallback,
  ) async {
    _loadVideoCallback = loadVideoCallback;
  }

  Future<void> setPlayCallback(
    MethodCallback playCallback,
  ) async {
    _playCallback = playCallback;
  }

  Future<void> setPauseCallback(
    MethodCallback pauseCallback,
  ) async {
    _pauseCallback = pauseCallback;
  }

  Future<void> setStopCallback(
    MethodCallback stopCallback,
  ) async {
    _stopCallback = stopCallback;
  }

  Future<void> setMuteCallback(
    MethodCallback muteCallback,
  ) async {
    _muteCallback = muteCallback;
  }

  Future<void> setUnuteCallback(
    MethodCallback unmuteCallback,
  ) async {
    _unmuteCallback = unmuteCallback;
  }

  Future<void> setSeekToCallback(
    SeekToCallback seekToCallback,
  ) async {
    _seekToCallback = seekToCallback;
  }

  Future<void> setSetVolumeCallback(
    SetVolumeCallback setVolumeCallback,
  ) async {
    _setVolumeCallback = setVolumeCallback;
  }

  Future<void> setSetFullscreenCallback(
    SetFullscreenCallback setFullscreenCallback,
  ) async {
    _setFullscreenCallback = setFullscreenCallback;
  }

  Future<void> setGetCurrentTimeCallback(
    GetCurrentTimeCallback getCurrentTimeCallback,
  ) async {
    _getCurrentTimeCallback = getCurrentTimeCallback;
  }

  Future<void> setGetPlayBackRateCallback(
    GetPlayBackRateCallback getPlayBackRateCallback,
  ) async {
    _getPlaybackRateCallback = getPlayBackRateCallback;
  }

  Future<void> setGetIsPausedCallback(
    GetIsPausedCallback getIsPausedCallback,
  ) async {
    _getIsPausedCallback = getIsPausedCallback;
  }

  Future<void> setGetDurationCallback(
    GetDurationCallback getDurationCallback,
  ) async {
    _getDurationCallback = getDurationCallback;
  }
}
