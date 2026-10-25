import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/autoplay.dart';
import '../../core/theme.dart';
import '../../data/stories.dart';
import 'data_saver.dart';

/// About 20 files keeps the device cache near the 50 MB budget.
final promoMediaCache = CacheManager(
  Config(
    'bloomPromoMedia',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 20,
  ),
);

/// The most visible promo (≥60%) is the only one that plays.
class BloomPlayback {
  static final active = ValueNotifier<String?>(null);
  static final _seen = <String, double>{};

  static void report(String id, double fraction) {
    if (fraction >= 0.6) {
      _seen[id] = fraction;
    } else {
      _seen.remove(id);
    }
    _pick();
  }

  static void forget(String id) {
    _seen.remove(id);
    _pick();
  }

  static void _pick() {
    String? best;
    var score = 0.0;
    for (final entry in _seen.entries) {
      if (entry.value > score) {
        score = entry.value;
        best = entry.key;
      }
    }
    if (active.value != best) active.value = best;
  }
}

class BloomMedia extends ConsumerStatefulWidget {
  const BloomMedia({required this.story, this.fit = BoxFit.cover, super.key});

  final Story story;
  final BoxFit fit;

  /// Widget tests leave this off so they never touch the video plugin.
  static bool enablePlayback = true;

  @override
  ConsumerState<BloomMedia> createState() => _BloomMediaState();
}

class _BloomMediaState extends ConsumerState<BloomMedia> {
  VideoPlayerController? _video;
  var _showPoster = true;
  var _wantsPlay = false;
  Timer? _startTimer;

  String get _id => widget.story.id;
  bool get _once => widget.story.placement == StoryPlacement.splash;

  @override
  void initState() {
    super.initState();
    BloomPlayback.active.addListener(_onActive);
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    BloomPlayback.active.removeListener(_onActive);
    BloomPlayback.forget(_id);
    _video?.removeListener(_onTick);
    _video?.dispose();
    super.dispose();
  }

  void _onActive() {
    _wantsPlay = BloomPlayback.active.value == _id;
    if (!mounted) return;
    if (_wantsPlay) {
      unawaited(_maybePlay());
    } else {
      _startTimer?.cancel();
      _video?.pause();
    }
  }

  void _onVisibility(VisibilityInfo info) {
    BloomPlayback.report(_id, info.visibleFraction);
    _onActive();
  }

  Future<bool> _allowed() async {
    if (!BloomMedia.enablePlayback) return false;
    if (!mounted) return false;
    if (MediaQuery.disableAnimationsOf(context)) return false;
    if (readSaveData()) return false;
    final choice = ref.read(autoplayProvider).choice;
    if (choice == AutoplayChoice.never) return false;
    if (choice == AutoplayChoice.wifi) {
      try {
        final links = await Connectivity().checkConnectivity();
        final wifi = links.contains(ConnectivityResult.wifi) ||
            links.contains(ConnectivityResult.ethernet);
        if (!wifi) return false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  Future<void> _maybePlay() async {
    if (!_wantsPlay) return;
    if (!await _allowed()) {
      if (mounted) setState(() => _showPoster = true);
      return;
    }
    if (!mounted || !_wantsPlay) return;
    final kind = widget.story.mediaKind;
    if (kind == StoryMediaKind.lottie) {
      setState(() => _showPoster = false);
      return;
    }
    if (kind != StoryMediaKind.video || widget.story.mediaUrl.isEmpty) return;
    _startTimer?.cancel();
    _startTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (!(_video?.value.isInitialized ?? false)) {
        setState(() => _showPoster = true);
        _video?.pause();
      }
    });
    try {
      _video ??= await _open(widget.story.mediaUrl);
      await _video!.setVolume(0);
      await _video!.setLooping(!_once);
      if (!_video!.value.isInitialized) {
        await _video!.initialize().timeout(const Duration(milliseconds: 1500));
      }
      if (!mounted || !_wantsPlay) return;
      _video!.addListener(_onTick);
      await _video!.play();
      _startTimer?.cancel();
      setState(() => _showPoster = false);
    } catch (_) {
      if (mounted) setState(() => _showPoster = true);
    }
  }

  void _onTick() {
    final video = _video;
    if (video == null || !_once || !mounted) return;
    final value = video.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;
    if (value.position < value.duration) return;
    video.pause();
    setState(() => _showPoster = true);
  }

  Future<VideoPlayerController> _open(String url) async {
    if (url.startsWith('assets/')) {
      return VideoPlayerController.asset(url);
    }
    if (kIsWeb) return VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      final file = await promoMediaCache.getSingleFile(url);
      return VideoPlayerController.file(file);
    } catch (_) {
      return VideoPlayerController.networkUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final playing = !_showPoster;
    final frame = Stack(
      fit: StackFit.expand,
      children: [
        _poster(story),
        if (playing && story.mediaKind == StoryMediaKind.lottie)
          _lottie(story.mediaUrl),
        if (playing && _video != null && _video!.value.isInitialized)
          FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: _video!.value.size.width,
              height: _video!.value.size.height,
              child: VideoPlayer(_video!),
            ),
          ),
      ],
    );
    if (!BloomMedia.enablePlayback) return frame;
    return VisibilityDetector(
      key: Key('bloom-media-${story.id}'),
      onVisibilityChanged: _onVisibility,
      child: frame,
    );
  }

  Widget _poster(Story story) {
    final poster = story.posterUrl;
    if (poster.startsWith('assets/')) {
      return Image.asset(
        poster,
        fit: widget.fit,
        errorBuilder: (_, _, _) => _wash(),
      );
    }
    if (poster.startsWith('http')) {
      return Image.network(
        poster,
        fit: widget.fit,
        errorBuilder: (_, _, _) => _wash(),
      );
    }
    return _wash();
  }

  Widget _wash() => ColoredBox(color: context.bloom.washVeg);

  Widget _lottie(String url) {
    final repeat = !_once;
    if (url.startsWith('assets/')) {
      return Lottie.asset(url, fit: widget.fit, repeat: repeat);
    }
    return Lottie.network(url, fit: widget.fit, repeat: repeat);
  }
}
