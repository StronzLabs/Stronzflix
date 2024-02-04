import 'package:flutter/material.dart';
import 'package:stronzflix/components/stronzflix_player/stronzflix_player_controller.dart';
import 'package:video_player/video_player.dart';

class StronzflixPlayerProgressBar extends StatefulWidget {
    
    final StronzflixPlayerController controller;
    final Function()? onDragStart;
    final Function()? onDragEnd;
    final Function()? onDragUpdate;
    final Function(Duration)? onSeek;

    const StronzflixPlayerProgressBar({
        super.key,
        required this.controller,
        this.onDragStart,
        this.onDragEnd,
        this.onDragUpdate,
        this.onSeek
    });

    @override
    State<StronzflixPlayerProgressBar> createState() => _StronzflixPlayerProgressBarState();
}

class _StronzflixPlayerProgressBarState extends State<StronzflixPlayerProgressBar> {
    
    StronzflixPlayerController get _controller => widget.controller;

    Offset? _latestDraggableOffset;
    late bool _controllerWasPlaying;

    @override
    void initState() {
        super.initState();
        this._controllerWasPlaying = false;
        this._controller.addListener(this._listener);
    }

    @override
    void dispose() {
        this._controller.removeListener(this._listener);
        super.dispose();
    }
    
    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onHorizontalDragStart: (DragStartDetails details) {
                this._controllerWasPlaying = this._controller.isPlaying;
                if (this._controllerWasPlaying)
                    this._controller.pause();
                super.widget.onDragStart?.call();
            },
            onHorizontalDragUpdate: (DragUpdateDetails details) {
                this._latestDraggableOffset = details.globalPosition;
                this._listener();

                if (this._latestDraggableOffset != null) {
                    this._seekToRelativePosition(this._latestDraggableOffset!);
                    this. _latestDraggableOffset = null;
                }
                super.widget.onDragUpdate?.call();
            },
            onHorizontalDragEnd: (DragEndDetails details) {
                if (this._controllerWasPlaying)
                    this._controller.play();

                if (this._latestDraggableOffset != null) {
                    this._seekToRelativePosition(this._latestDraggableOffset!);
                    this._latestDraggableOffset = null;
                }
                super.widget.onDragEnd?.call();
            },
            onTapDown: (TapDownDetails details) {
                this._seekToRelativePosition(details.globalPosition);
            },
            child: Center(
                child: StaticProgressBar(
                    value: this._controller.value,
                    barHeight: 10,
                    handleHeight: 6,
                    drawShadow: true,
                )
            )
        );
    }

    void _seekToRelativePosition(Offset globalPosition) {
        Duration positon = super.context.calcRelativePosition(
            this._controller.value.duration,
            globalPosition,
        );
        this._controller.seekTo(positon);
        super.widget.onSeek?.call(positon);
    }

    void _listener() => super.setState(() {});
}

class StaticProgressBar extends StatelessWidget {
    
    final Offset? latestDraggableOffset;
    final VideoPlayerValue value;

    final double barHeight;
    final double handleHeight;
    final bool drawShadow;
    
    const StaticProgressBar({
        super.key,
        required this.value,
        required this.barHeight,
        required this.handleHeight,
        required this.drawShadow,
        this.latestDraggableOffset,
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.transparent,
            child: CustomPaint(
                painter: _ProgressBarPainter(
                    value: value,
                    draggableValue: context.calcRelativePosition(
                        value.duration,
                        latestDraggableOffset,
                    ),
                    barHeight: barHeight,
                    handleHeight: handleHeight,
                    drawShadow: drawShadow,
                    colors: _ProgressBarColors(
                        playedColor: Theme.of(context).colorScheme.secondary,
                        handleColor: Theme.of(context).colorScheme.secondary,
                        bufferedColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
                        backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
                    )
                )
            )
        );
    }
}

class _ProgressBarColors {
    final Paint playedPaint;
    final Paint bufferedPaint;
    final Paint handlePaint;
    final Paint backgroundPaint;

    _ProgressBarColors({
        required Color playedColor,
        required Color bufferedColor,
        required Color handleColor,
        required Color backgroundColor,
    }) : 
        this.playedPaint = Paint()..color = playedColor,
        this.bufferedPaint = Paint()..color = bufferedColor,
        this.handlePaint = Paint()..color = handleColor,
        this.backgroundPaint = Paint()..color = backgroundColor;
}

class _ProgressBarPainter extends CustomPainter {
    
    VideoPlayerValue value;

    final double barHeight;
    final double handleHeight;
    final bool drawShadow;
    final Duration draggableValue;
    final _ProgressBarColors colors;
    
    _ProgressBarPainter({
        required this.value,
        required this.barHeight,
        required this.handleHeight,
        required this.drawShadow,
        required this.draggableValue,
        required this.colors
    });

    @override
    bool shouldRepaint(CustomPainter painter) => true;

    @override
    void paint(Canvas canvas, Size size) {
        final double baseOffset = size.height / 2 - this.barHeight / 2;

        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromPoints(
                    Offset(0.0, baseOffset),
                    Offset(size.width, baseOffset + this.barHeight),
                ),
                const Radius.circular(4.0),
            ),
            this.colors.backgroundPaint
        );

        if(!this.value.isInitialized)
            return;

        final double playedPartPercent = (this.draggableValue != Duration.zero
            ? this.draggableValue.inMilliseconds
            : this.value.position.inMilliseconds) /
        this.value.duration.inMilliseconds;
        final double playedPart = playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
        for (final DurationRange range in this.value.buffered) {
            final double start = range.startFraction(this.value.duration) * size.width;
            final double end = range.endFraction(this.value.duration) * size.width;
            canvas.drawRRect(
                RRect.fromRectAndRadius(
                Rect.fromPoints(
                    Offset(start, baseOffset),
                    Offset(end, baseOffset + this.barHeight),
                ),
                const Radius.circular(4.0),
                ),
                this.colors.bufferedPaint,
            );
        }

        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromPoints(
                Offset(0.0, baseOffset),
                Offset(playedPart, baseOffset + this.barHeight),
                ),
                const Radius.circular(4.0),
            ),
            this.colors.playedPaint,
        );

        if (this.drawShadow) {
            final Path shadowPath = Path()..addOval(
                Rect.fromCircle(
                    center: Offset(playedPart, baseOffset + this.barHeight / 2),
                    radius: this.handleHeight,
                ),
            );

            canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
        }

        canvas.drawCircle(
            Offset(playedPart, baseOffset + this.barHeight / 2),
            this.handleHeight,
            this.colors.handlePaint,
        );
    }
}

extension _RelativePositionExtensions on BuildContext {
    Duration calcRelativePosition(Duration videoDuration, Offset? globalPosition) {
        if (globalPosition == null)
            return Duration.zero;
        final box = findRenderObject()! as RenderBox;
        final Offset tapPos = box.globalToLocal(globalPosition);
        final double relative = tapPos.dx / box.size.width;
        final Duration position = videoDuration * relative;
        return position;
    }
}
