enum FullscreenFallback { video, pseudo }

extension FullscreenFallbackExtension on FullscreenFallback {
  String get name {
    switch (this) {
      case FullscreenFallback.video:
        return 'video';
      case FullscreenFallback.pseudo:
        return 'pseudo';
    }
  }
}
