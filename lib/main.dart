import 'dart:math';

import 'package:flutter/material.dart';
import 'bottom_control.dart';
import 'theme.dart';
import 'package:fluttery/gestures.dart';
import 'package:fluttery_audio/fluttery_audio.dart';

import 'songs.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: MusicApp(),
    );
  }
}

class MusicApp extends StatefulWidget {
  @override
  _MusicAppState createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  @override
  Widget build(BuildContext context) {
    return AudioPlaylist(
      playlist: demoPlaylist.songs.map((DemoSong song) {
        return song.audioUrl;
      }).toList(growable: false),
      playbackState: PlaybackState.paused,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Color(0xFFDDDDDD),
            ),
            onPressed: () {},
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.menu,
                color: Color(0xFFDDDDDD),
              ),
              onPressed: () {},
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: <Widget>[
            // Seek Bar
            Expanded(
              child: AudioPlaylistComponent(playlistBuilder:
                  (BuildContext context, Playlist playlist, Widget child) {
                String albumArtUrl =
                    demoPlaylist.songs[playlist.activeIndex].albumArtUrl;

                return AudioRadialSeekBar(albumArtUrl: albumArtUrl);
              }),
            ),
            // Visualizer
            Container(
              width: double.infinity,
              height: 125.0,
              child: Visualizer(
                builder: (BuildContext context, List<int> fft) {
                  return CustomPaint(
                    painter: VisualizerPainter(
                      fft: fft,
                      height: 125.0,
                      color: accentColor,
                    ),
                  );
                },
              ),
            ),

            // Song title, artist name and controls
            new BottomControls()
          ],
        ),
      ),
    );
  }
}

class VisualizerPainter extends CustomPainter {
  final List<int> fft;
  final double height;
  final Color color;
  final Paint wavePaint;

  VisualizerPainter({
    this.fft,
    this.height,
    this.color,
  }) : wavePaint = new Paint()
          ..color = color.withOpacity(0.75)
          ..style = PaintingStyle.fill;
  @override
  void paint(Canvas canvas, Size size) {
    _renderWaves(canvas, size);
  }

  void _renderWaves(Canvas canvas, Size size) {
    final histogramLow =
        _createHistogram(fft, 16, 12, ((fft.length - 2) / 4).floor() + 10);
    final histogramHigh = _createHistogram(
        fft, 16, ((fft.length - 2) / 4).ceil() + 10, ((fft.length - 2) / 2).floor());

    _renderHistogram(canvas, size, histogramLow);
    _renderHistogram(canvas, size, histogramHigh);
  }

  void _renderHistogram(Canvas canvas, Size size, List<int> histogram) {
    if (histogram.length == 0) {
      return;
    }

    final pointsToGraph = histogram.length;
    final widthPerSample = (size.width / (pointsToGraph - 2)).floor();

    final points = new List<double>.filled(pointsToGraph * 4, 0.0);

    for (int i = 0; i < histogram.length - 1; ++i) {
      points[i * 4] = (i * widthPerSample).toDouble();
      points[i * 4 + 1] = size.height - histogram[i].toDouble();

      points[i * 4 + 2] = ((i + 1) * widthPerSample).toDouble();
      points[i * 4 + 3] = size.height - (histogram[i + 1].toDouble());
    }

    Path path = new Path();
    path.moveTo(0.0, size.height);
    path.lineTo(points[0], points[1]);
    for (int i = 2; i < points.length - 4; i += 2) {
      path.cubicTo(points[i - 2] + 10.0, points[i - 1], points[i] - 10.0,
          points[i + 1], points[i], points[i + 1]);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  List<int> _createHistogram(List<int> samples, int bucketCount,
      [int start, int end]) {
    if (start == end) {
      return const [];
    }

    // Make sure we are not starting in the middle of an imaginary pair!
    assert(start > 1 && start % 2 ==0);

    start = start ?? 0;
    end = end ?? samples.length - 1;
    final sampleCount = end - start + 1;

    final samplesPerBucket = (sampleCount / bucketCount).floor();

    if (samplesPerBucket == 0) {
      return const [];
    }

    final actualSampleCount = sampleCount - (sampleCount % samplesPerBucket);

    List<double> histogram = new List<double>.filled(bucketCount + 1, 0);

    
    for (int i = start; i <= start + actualSampleCount; ++i) {

      if ((i - start) % 2 == 1) {
        continue;
      }
      
            // Calculate the magnitude of the FFT result for the bin while removing
      // the phase correlation information by calculating the raw magnitude
      double magnitude = sqrt((pow(samples[i], 2) + pow(samples[i + 1], 2)));
      // Convert the raw magnitude to Decibels Full Scale (dBFS) assuming an 8 bit value
      // and clamp it to get rid of astronomically small numbers and -Infinity when array is empty.
      // We are assuming the values are already normalized
      double magnitudeDb = (10 * (log(magnitude / 256) / ln10));

      int bucketIndex = ((i - start) / samplesPerBucket).floor();
      histogram[bucketIndex] += (magnitudeDb == -double.infinity) ? 0 : magnitudeDb;
    }

    // Massage the data for visualization.

    return histogram.map((double d) {
      return (-10 * d / samplesPerBucket).round();
    }).toList();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class AudioRadialSeekBar extends StatefulWidget {
  final String albumArtUrl;

  AudioRadialSeekBar({
    this.albumArtUrl,
  });
  @override
  _AudioRadialSeekBarState createState() => _AudioRadialSeekBarState();
}

class _AudioRadialSeekBarState extends State<AudioRadialSeekBar> {
  double _seekPercent;
  @override
  Widget build(BuildContext context) {
    return AudioComponent(
      updateMe: [
        WatchableAudioProperties.audioSeeking,
        WatchableAudioProperties.audioPlayhead,
      ],
      playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
        double playBackProgress = 0.0;
        if (player.audioLength != null && player.position != null) {
          playBackProgress = player.position.inMilliseconds /
              player.audioLength.inMilliseconds;
        }

        _seekPercent = player.isSeeking ? _seekPercent : null;

        return RadialSeekBar(
          progress: playBackProgress,
          seekPercent: _seekPercent,
          onSeekRequested: (double seekPercent) {
            setState(() {
              _seekPercent = seekPercent;
            });

            final seekMillis =
                (player.audioLength.inMilliseconds * seekPercent).round();
            player.seek(Duration(milliseconds: seekMillis));
          },
          child: ClipOval(
            clipper: CircleClipper(),
            child: Container(
              color: accentColor,
              child: Image.network(
                widget.albumArtUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

class RadialSeekBar extends StatefulWidget {
  final progress;
  final double seekPercent;
  final Function(double) onSeekRequested;
  final Widget child;

  RadialSeekBar({
    this.child,
    this.seekPercent = 0.0,
    this.progress = 0.0,
    this.onSeekRequested,
  });
  @override
  _RadialSeekBarState createState() => _RadialSeekBarState();
}

class _RadialSeekBarState extends State<RadialSeekBar> {
  double _progress = 0.0;
  PolarCoord _startDragCoord;
  double _startDragPercent;
  double _currentDragPercent;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
  }

  @override
  void didUpdateWidget(RadialSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progress = widget.progress;
  }

  void _onDragStart(PolarCoord coord) {
    _startDragCoord = coord;
    _startDragPercent = _progress;
  }

  void _onDragUpdate(PolarCoord coord) {
    final dragAngle = coord.angle - _startDragCoord.angle;
    final dragPercent = dragAngle / (2 * pi);
    setState(() {
      _currentDragPercent = (_startDragPercent + dragPercent) % 1.0;
    });
  }

  void _onDragEnd() {
    if (widget.onSeekRequested != null) {
      widget.onSeekRequested(_currentDragPercent);
    }

    setState(() {
      _currentDragPercent = null;
      _startDragCoord = null;
      _startDragPercent = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double thumbPosition = _progress;

    if (_currentDragPercent != null) {
      thumbPosition = _currentDragPercent;
    } else if (widget.seekPercent != null) {
      thumbPosition = widget.seekPercent;
    }

    return RadialDragGestureDetector(
      onRadialDragStart: _onDragStart,
      onRadialDragUpdate: _onDragUpdate,
      onRadialDragEnd: _onDragEnd,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors
            .transparent, //This color is given because in absence of a color, touch
        // events are not processed.
        child: Center(
          child: Container(
            width: 140.0,
            height: 140.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(62.5),
            ),
            child: RadialProgressBar(
              trackColor: Color(0xFFDDDDDD),
              //use _currentDragPercent if it's not null. Other wise use _seekPercent
              progressPercent: _progress,
              //use _currentDragPercent if it's not null. Other wise use _seekPercent
              thumbPosition: thumbPosition,
              progressColor: accentColor,
              thumbColor: lightAccentColor,
              innerPadding: const EdgeInsets.all(10.0),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class RadialProgressBar extends StatefulWidget {
  final double trackWidth;
  final Color trackColor;
  final double progressWidth;
  final Color progressColor;
  final double progressPercent;
  final double thumbSize;
  final Color thumbColor;
  final double thumbPosition;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;
  final Widget child;

  RadialProgressBar({
    this.progressColor = Colors.black,
    this.progressWidth = 5.0,
    this.progressPercent = 0.0,
    this.thumbColor = Colors.black,
    this.thumbSize = 10.0,
    this.thumbPosition = 0.0,
    this.trackColor = Colors.grey,
    this.trackWidth = 3.0,
    this.innerPadding = const EdgeInsets.all(0.0),
    this.outerPadding = const EdgeInsets.all(0.0),
    this.child,
  });
  @override
  _RadialProgressBarState createState() => _RadialProgressBarState();
}

class _RadialProgressBarState extends State<RadialProgressBar> {
  EdgeInsets _insetsForPainter() {
    //Make room for painted track, progress and thumb. We divide by 2.0
    // because we want to allow flush painting against the track, so we
    // only need to account the thickness outside the track, not inside.

    final outerThickness = max(
          widget.trackWidth,
          max(
            widget.progressWidth,
            widget.thumbSize,
          ),
        ) /
        2.0;

    return EdgeInsets.all(outerThickness);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.outerPadding,
      child: CustomPaint(
        foregroundPainter: RadialSeekBarPainter(
          trackWidth: widget.trackWidth,
          trackColor: widget.trackColor,
          thumbColor: widget.thumbColor,
          progressWidth: widget.progressWidth,
          progressColor: widget.progressColor,
          thumbSize: widget.thumbSize,
          thumbPosition: widget.thumbPosition,
          progressPercent: widget.progressPercent,
        ),
        child: Padding(
          padding: _insetsForPainter() + widget.innerPadding,
          child: widget.child,
        ),
      ),
    );
  }
}

class RadialSeekBarPainter extends CustomPainter {
  final double trackWidth;

  final Paint trackPaint;
  final double progressWidth;

  final Paint progressPaint;
  final double progressPercent;
  final double thumbSize;

  final Paint thumbPaint;
  final double thumbPosition;

  RadialSeekBarPainter({
    progressColor,
    @required this.progressPercent,
    @required this.progressWidth,
    @required thumbColor,
    @required this.thumbPosition,
    @required this.thumbSize,
    @required trackColor,
    @required this.trackWidth,
  })  : trackPaint = Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackWidth,
        progressPaint = Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = progressWidth
          ..strokeCap = StrokeCap.round,
        thumbPaint = Paint()
          ..color = thumbColor
          ..style = PaintingStyle.fill;
  @override
  void paint(Canvas canvas, Size size) {
    final outerThickness = max(trackWidth, max(progressWidth, thumbSize));
    Size constrainedSize =
        Size(size.width - outerThickness, size.height - outerThickness);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(constrainedSize.width, constrainedSize.height) / 2;
    //Paint Track.
    canvas.drawCircle(
      center,
      radius,
      trackPaint,
    );

    final progressAngle = 2 * pi * progressPercent;
    //Paint Canvas.
    canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        -pi / 2,
        progressAngle,
        false,
        progressPaint);

    // Paint Thumb.
    final thumbAngle = 2 * pi * thumbPosition - (pi / 2);
    final thumbX = cos(thumbAngle) * radius;
    final thumbY = sin(thumbAngle) * radius;
    final thumbCenter = Offset(thumbX, thumbY) + center;
    final thumbRadius = thumbSize / 2.0;
    canvas.drawCircle(thumbCenter, thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
