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
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../data/player_status.dart';
import '../data/player_time_update.dart';
import '../kinescope_player_controller.dart';
import '../utils/uri_builder.dart';

const _scheme = 'https';
const _kinescopeUri = 'kinescope.io';

class KinescopePlayerDevice extends StatefulWidget {
  final KinescopePlayerController controller;

  /// Aspect ratio for the player,
  /// by default it's 16 / 9.
  final double aspectRatio;

  /// A widget to play Kinescope videos.
  const KinescopePlayerDevice({
    super.key,
    required this.controller,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<KinescopePlayerDevice> createState() => _KinescopePlayerState();
}

class _KinescopePlayerState extends State<KinescopePlayerDevice> {
  late PlatformWebViewController controller;

  Completer<Duration>? getCurrentTimeCompleter;

  Completer<Duration>? getDurationCompleter;
  Completer<double>? getPlaybackRateCompleter;
  Completer<bool>? getIsPausedCompleter;

  late String videoId;
  late String externalId;
  late String baseUrl;
  late String baseHost;

  void _log(String message) {
    final logLine = '[kinescope_webview]'
        ' videoId=$videoId'
        ' baseHost=$baseHost'
        ' baseUrl=$baseUrl'
        ' $message';
    widget.controller.onLog?.call(logLine);
    // Keep debugPrint as a fallback for local diagnostics.
    debugPrint(logLine);
  }

  @override
  void initState() {
    super.initState();
    try {
      videoId = widget.controller.videoId;
      externalId = widget.controller.parameters.externalId ?? '';
      baseUrl = widget.controller.parameters.baseUrl ??
          Uri(
            scheme: _scheme,
            host: _kinescopeUri,
          ).toString();
      baseHost = Uri.parse(baseUrl).host;
    } catch (e, stackTrace) {
      _log('initState_error error=$e stackTrace=$stackTrace');
      rethrow;
    }

    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = PlatformWebViewController(params);

    // ignore: cascade_invocations
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setPlatformNavigationDelegate(
        PlatformNavigationDelegate(
          const PlatformNavigationDelegateCreationParams(),
        )
          ..setOnNavigationRequest((request) {
            if (!request.url.contains(_kinescopeUri) &&
                !request.url.contains(baseHost)) {
              _log('navigation_blocked url=${request.url}');
              return NavigationDecision.prevent;
            }
            _log('navigation_allowed url=${request.url}');
            return NavigationDecision.navigate;
          })
          ..setOnUrlChange(
            (change) {
              _log('url_change url=${change.url}');
            },
          ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'Events',
          onMessageReceived: (message) {
            try {
              _log('js_event ${message.message}');
              if (!widget.controller.statusController.isClosed) {
                widget.controller.statusController.add(
                  KinescopePlayerStatus.values.firstWhere(
                    (value) => value.toString() == message.message,
                    orElse: () => KinescopePlayerStatus.unknown,
                  ),
                );
              }
            } catch (e, stackTrace) {
              _log('js_event_error error=$e message=${message.message} stackTrace=$stackTrace');
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'KinescopeLog',
          onMessageReceived: (message) {
            _log('js_log ${message.message}');
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'CurrentTime',
          onMessageReceived: (message) {
            try {
              final dynamic seconds = double.parse(message.message);
              if (seconds is num) {
                getCurrentTimeCompleter?.complete(
                  Duration(milliseconds: (seconds * 1000).ceil()),
                );
              }
            } catch (e, stackTrace) {
              _log('CurrentTime_error error=$e message=${message.message} stackTrace=$stackTrace');
              getCurrentTimeCompleter?.completeError(e, stackTrace);
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'Duration',
          onMessageReceived: (message) {
            try {
              final dynamic seconds = double.parse(message.message);
              if (seconds is num) {
                getDurationCompleter?.complete(
                  Duration(milliseconds: (seconds * 1000).ceil()),
                );
              }
            } catch (e, stackTrace) {
              _log('Duration_error error=$e message=${message.message} stackTrace=$stackTrace');
              getDurationCompleter?.completeError(e, stackTrace);
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'PlayBackRate',
          onMessageReceived: (message) {
            try {
              final dynamic currentSpeed = double.parse(message.message);
              if (currentSpeed is num) {
                getPlaybackRateCompleter?.complete(currentSpeed.toDouble());
              }
            } catch (e, stackTrace) {
              _log('PlayBackRate_error error=$e message=${message.message} stackTrace=$stackTrace');
              getPlaybackRateCompleter?.completeError(e, stackTrace);
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'CheckPaused',
          onMessageReceived: (message) {
            try {
              final dynamic isPaused = bool.parse(message.message);
              if (isPaused is bool) {
                getIsPausedCompleter?.complete(isPaused);
              }
            } catch (e, stackTrace) {
              _log('CheckPaused_error error=$e message=${message.message} stackTrace=$stackTrace');
              getIsPausedCompleter?.completeError(e, stackTrace);
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'PipChange',
          onMessageReceived: (message) {
            try {
              final dynamic isPip = bool.parse(message.message);
              if (isPip is bool) {
                widget.controller.onChangePip?.call(isPip);
              }
            } catch (e, stackTrace) {
              _log('PipChange_error error=$e message=${message.message} stackTrace=$stackTrace');
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'PlaybackRateChange',
          onMessageReceived: (message) {
            try {
              final dynamic currentSpeed = message.message;
              if (currentSpeed is num) {
                widget.controller.onChangePlaybackRate?.call(
                  currentSpeed.toDouble(),
                );
              }
            } catch (e, stackTrace) {
              _log('PlaybackRateChange_error error=$e message=${message.message} stackTrace=$stackTrace');
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'FullScreen',
          onMessageReceived: (message) {
            try {
              final dynamic isFullscreen = bool.parse(message.message);
              if (isFullscreen is bool) {
                widget.controller.onChangeFullscreen?.call(isFullscreen);
              }
            } catch (e, stackTrace) {
              _log('FullScreen_error error=$e message=${message.message} stackTrace=$stackTrace');
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'TimeUpdate',
          onMessageReceived: (message) {
            try {
              if (message.message.contains('currentTime')) {
                final data = jsonDecode(message.message) as Map<String, dynamic>;
                if (!widget.controller.timeUpdateController.isClosed) {
                  widget.controller.timeUpdateController
                      .add(KinescopePlayerTimeUpdate.fromJson(data));
                }
              }
            } catch (e, stackTrace) {
              _log('TimeUpdate_error error=$e message=${message.message} stackTrace=$stackTrace');
            }
          },
        ),
      )
      ..setOnPlatformPermissionRequest(
        (request) {
          _log(
            'permission_request types=${request.types.map((type) => type.name).toList()}',
          );
          request.grant();
        },
      )
      ..enableZoom(false)
      ..setOnConsoleMessage((message) {
        _log('webview_console level=${message.level.name} message=${message.message}');
      })
      ..setUserAgent(getUserArgent())
      ..loadHtmlString(_player, baseUrl: baseUrl);

    _log('init ua=${getUserArgent()}');

    if (Platform.isAndroid) {
      (controller as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    widget.controller.controllerProxy
      ..setLoadVideoCallback(_proxyLoadVideo)
      ..setPlayCallback(_proxyPlay)
      ..setPauseCallback(_proxyPause)
      ..setStopCallback(_proxyStop)
      ..setGetCurrentTimeCallback(_proxyGetCurrentTime)
      ..setGetDurationCallback(_proxyGetDuration)
      ..setGetPlayBackRateCallback(_proxyGetPlayBackRate)
      ..setGetIsPausedCallback(_proxyGetIsPausedCallback)
      ..setSeekToCallback(_proxySeekTo)
      ..setSetFullscreenCallback(_proxySetFullscreen)
      ..setSetVolumeCallback(_proxySetVolume)
      ..setMuteCallback(_proxyMute)
      ..setUnuteCallback(_proxyUnmute);

    this.controller = controller;
  }

  @override
  void dispose() {
    try {
      widget.controller.dispose();
    } catch (e, stackTrace) {
      _log('dispose_error error=$e stackTrace=$stackTrace');
    }
    super.dispose();
  }

  void _proxyLoadVideo(String videoId) {
    try {
      controller.runJavaScript(
        'loadVideo("$videoId");',
      );
    } catch (e, stackTrace) {
      _log('_proxyLoadVideo_error error=$e videoId=$videoId stackTrace=$stackTrace');
    }
  }

  void _proxyPlay() {
    try {
      controller.runJavaScript('play();');
    } catch (e, stackTrace) {
      _log('_proxyPlay_error error=$e stackTrace=$stackTrace');
    }
  }

  void _proxyPause() {
    try {
      controller.runJavaScript('pause();');
    } catch (e, stackTrace) {
      _log('_proxyPause_error error=$e stackTrace=$stackTrace');
    }
  }

  void _proxyStop() {
    try {
      controller.runJavaScript('stop();');
    } catch (e, stackTrace) {
      _log('_proxyStop_error error=$e stackTrace=$stackTrace');
    }
  }

  Future<Duration> _proxyGetCurrentTime() async {
    try {
      getCurrentTimeCompleter = Completer<Duration>();

      await controller.runJavaScript(
        'getCurrentTime();',
      );

      final time = await getCurrentTimeCompleter?.future;

      return time ?? Duration.zero;
    } catch (e, stackTrace) {
      _log('_proxyGetCurrentTime_error error=$e stackTrace=$stackTrace');
      return Duration.zero;
    }
  }

  Future<Duration> _proxyGetDuration() async {
    try {
      getDurationCompleter = Completer<Duration>();

      await controller.runJavaScript(
        'getDuration();',
      );

      final duration = await getDurationCompleter?.future;

      return duration ?? Duration.zero;
    } catch (e, stackTrace) {
      _log('_proxyGetDuration_error error=$e stackTrace=$stackTrace');
      return Duration.zero;
    }
  }

  Future<double> _proxyGetPlayBackRate() async {
    try {
      getPlaybackRateCompleter = Completer<double>();
      await controller.runJavaScript('getPlaybackRate();');
      final playBackRate = await getPlaybackRateCompleter?.future;
      return playBackRate ?? 1.0;
    } catch (e, stackTrace) {
      _log('_proxyGetPlayBackRate_error error=$e stackTrace=$stackTrace');
      return 1.0;
    }
  }

  Future<bool> _proxyGetIsPausedCallback() async {
    try {
      getIsPausedCompleter = Completer<bool>();
      await controller.runJavaScript('isPaused();');
      final isPaused = await getIsPausedCompleter?.future;
      return isPaused ?? false;
    } catch (e, stackTrace) {
      _log('_proxyGetIsPausedCallback_error error=$e stackTrace=$stackTrace');
      return false;
    }
  }

  void _proxySeekTo(Duration duration) {
    try {
      controller.runJavaScript(
        'seekTo(${duration.inSeconds});',
      );
    } catch (e, stackTrace) {
      _log('_proxySeekTo_error error=$e duration=$duration stackTrace=$stackTrace');
    }
  }

  void _proxySetVolume(double value) {
    try {
      controller.runJavaScript('setVolume($value);');
    } catch (e, stackTrace) {
      _log('_proxySetVolume_error error=$e value=$value stackTrace=$stackTrace');
    }
  }

  void _proxyMute() {
    try {
      controller.runJavaScript('mute();');
    } catch (e, stackTrace) {
      _log('_proxyMute_error error=$e stackTrace=$stackTrace');
    }
  }

  void _proxyUnmute() {
    try {
      controller.runJavaScript('unmute();');
    } catch (e, stackTrace) {
      _log('_proxyUnmute_error error=$e stackTrace=$stackTrace');
    }
  }

  void _proxySetFullscreen(bool value) {
    try {
      controller.runJavaScript('setFullscreen($value);');
    } catch (e, stackTrace) {
      _log('_proxySetFullscreen_error error=$e value=$value stackTrace=$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: PlatformWebViewWidget(
        PlatformWebViewWidgetCreationParams(controller: controller),
      ).build(context),
    );
  }

  String? getUserArgent() {
    return (Platform.isIOS
        ? 'Mozilla/5.0 (iPad; CPU iPhone OS 13_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) KinescopePlayerFlutter/0.2.3'
        : 'Mozilla/5.0 (Android 9.0; Mobile; rv:59.0) Gecko/59.0 Firefox/59.0 KinescopePlayerFlutter/0.2.3');
  }

  // ignore: member-ordering-extended
  String get _player => '''
<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8" />
    <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
    <style>
        html, body {
            padding: 0;
            margin: 0;
            width: 100%;
            height: 100%;
        }
        #player {
            position: fixed;
            width: 100%;
            height: 100%;
            left: 0;
            top: 0;
        }
    </style>

    <script>
        function _kLog(kind, payload) {
            try {
                KinescopeLog.postMessage(JSON.stringify({
                    kind: kind,
                    payload: payload,
                    ts: Date.now(),
                    href: (window && window.location) ? window.location.href : null,
                    ua: (navigator && navigator.userAgent) ? navigator.userAgent : null
                }));
            } catch (e) { /* noop */ }
        }

        (function () {
            try {
                var methods = ['log', 'info', 'warn', 'error', 'debug'];
                for (var i = 0; i < methods.length; i++) {
                    (function (m) {
                        var orig = console[m];
                        console[m] = function () {
                            try { _kLog('console.' + m, Array.prototype.slice.call(arguments)); } catch (e) {}
                            if (orig) return orig.apply(console, arguments);
                        };
                    })(methods[i]);
                }
            } catch (e) { /* noop */ }
        })();

        window.onerror = function (message, source, lineno, colno, error) {
            _kLog('window.onerror', {
                message: message,
                source: source,
                lineno: lineno,
                colno: colno,
                stack: (error && error.stack) ? error.stack : null
            });
        };

        window.onunhandledrejection = function (event) {
            try {
                var reason = event && event.reason;
                _kLog('unhandledrejection', {
                    reason: reason ? (reason.stack || reason.message || String(reason)) : null
                });
            } catch (e) { /* noop */ }
        };

        window.addEventListener("flutterInAppWebViewPlatformReady", function (event) {
            Events.postMessage('ready');
        });

        let kinescopePlayerFactory = null;

        let kinescopePlayer = null;

        let initialVideoUri = '${UriBuilder.buildVideoUri(videoId: videoId)}';

        function onKinescopeIframeAPIReady(playerFactory) {
            kinescopePlayerFactory = playerFactory;

            loadVideo(initialVideoUri);
        }

        function loadVideo(videoUri) {
            if (kinescopePlayer != null) {
                kinescopePlayer.destroy();
                kinescopePlayer = null;
            }

            if (kinescopePlayerFactory != null) {
                var devElement = document.createElement("div");
                devElement.id = "player";
                document.body.append(devElement);

                kinescopePlayerFactory
                    .create('player', {
                        url: videoUri,
                        size: { width: '100%', height: '100%' },
                        settings: {
                          externalId: '$externalId'
                        },
                        behaviour: {
                            ...${UriBuilder.parametersToBehavior(widget.controller.parameters)},
                            fullscreenFallback: '${widget.controller.parameters.fullscreenFallback.name}',
                        },
                        ui: ${UriBuilder.parametersToUI(widget.controller.parameters)}
                    })
                    .then(function (player) {
                        kinescopePlayer = player;
                        Events.postMessage('init');

                        player.once(player.Events.Ready, function (event) {
                          var time = ${UriBuilder.parameterSeekTo(widget.controller.parameters)};
                          if(time > 0 || time === 0) {
                             event.target.seekTo(time);
                          }
                        });
                        player.on(player.Events.Ready, function (event) { Events.postMessage('ready'); });
                        player.on(player.Events.Playing, function (event) { Events.postMessage('playing'); });
                        player.on(player.Events.Waiting, function (event) { Events.postMessage('waiting'); });
                        player.on(player.Events.Pause, function (event) { Events.postMessage('pause'); });
                        player.on(player.Events.Ended, function (event) { Events.postMessage('ended'); });
                        player.on(player.Events.FullscreenChange, onFullScreen);
                        player.on(player.Events.PlaybackRateChange, onPlaybackRateChange);
                        player.on(player.Events.PipChange, onPipChange);
                        player.on(player.Events.TimeUpdate, onTimeUpdate); 
                    });
            }
        }

        function play() {
            if (kinescopePlayer != null)
              kinescopePlayer.play();
        }

        function pause() {
            if (kinescopePlayer != null)
              kinescopePlayer.pause();
        }

        function stop() {
            if (kinescopePlayer != null)
              kinescopePlayer.stop();
        }

        function getCurrentTime() {
            if (kinescopePlayer != null)
              return kinescopePlayer.getCurrentTime();
        }

        function seekTo(seconds) {
            if (kinescopePlayer != null)
              kinescopePlayer.seekTo(seconds);
        }

        function getCurrentTime() {
            if (kinescopePlayer != null)
              kinescopePlayer.getCurrentTime().then((value) => {
                CurrentTime.postMessage(value);
              });
        }

        function getDuration() {
            if (kinescopePlayer != null)
              kinescopePlayer.getDuration().then((value) => {
                Duration.postMessage(value);
              });
        }
        
        function getPlaybackRate() {
            if (kinescopePlayer != null)
              kinescopePlayer.getPlaybackRate().then((value) => {
                  PlayBackRate.postMessage(value);
              });
        }
        
        function isPaused() {
            if (kinescopePlayer != null)
              kinescopePlayer.isPaused().then((value) => {
                 CheckPaused.postMessage(value);
              });
        }      

        function setVolume(value) {
            if (kinescopePlayer != null)
              kinescopePlayer.setVolume(value);
        }    
        
        function setFullscreen(value) {
            if (kinescopePlayer != null)
              kinescopePlayer.setFullscreen(value);
        }

        function mute() {
            if (kinescopePlayer != null)
              kinescopePlayer.mute();
        }

        function unmute() {
            if (kinescopePlayer != null)
              kinescopePlayer.unmute();
        }

        function onFullScreen(arg) {
            FullScreen.postMessage(arg.data.isFullscreen);           
        }  
        
        function onPipChange(arg) {
            PipChange.postMessage(arg.data.isPip);
        }
    
        function onPlaybackRateChange(arg) {
          PlaybackRateChange.postMessage(arg.data.playbackRate);
        }

        function onTimeUpdate(arg) {
          TimeUpdate.postMessage(JSON.stringify(arg.data));
        }
    </script>
</head>

<body>
    <script>
        var tag = document.createElement('script');

        tag.src = 'https://player.kinescope.io/latest/iframe.player.js';
        tag.onerror = function (e) {
            _kLog('script.onerror', { src: tag.src, error: e ? String(e) : null });
        };
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
    </script>
</body>

</html>
''';
}
