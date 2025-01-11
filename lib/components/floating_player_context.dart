import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sutils/utils.dart';

class FloatingPlayerContext extends StatefulWidget {
    final Widget? child;

    const FloatingPlayerContext({
        required this.child,
        super.key
    });

    @override
    State<FloatingPlayerContext> createState() => FloatingPlayerContextState();

    static FloatingPlayerContextState of(BuildContext context) {
        return context.findAncestorStateOfType<FloatingPlayerContextState>()!;
    }

    static Widget navigatorGuard(BuildContext context, {required Widget child}) {
        if (FloatingPlayerContext.of(context).visible)
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => FloatingPlayerContext.of(context).close()
            );
        return child;
    }
}

class FloatingPlayerContextState extends State<FloatingPlayerContext> {

    late Offset _position;
    late Offset _initialPosition;
    late Size _initialSize = this._size;
    Offset _dragOffset = Offset.zero;

    final Size _minSize = const Size(16 * 10, 9 * 10);
    late Size _size = this._minSize;
    final double _padding = 20.0;

    bool _visible = false;
    bool _showControls = false;
    bool _resizing = false;
    bool _panning = false;

    Widget Function(BuildContext)? _buildContent;
    void Function()? _onClose;
    void Function()? _onExpand;

    Timer? _timer;
    
    bool get visible => this._visible;

    void show(Widget Function(BuildContext)? buildContent, {void Function()? onClose, void Function()? onExpand}) {
        super.setState(() {
            final screenSize = MediaQuery.of(context).size;
            final isMobile = EPlatform.isMobile;

            final double xPos = isMobile 
                ? screenSize.height - this._size.width - this._padding 
                : screenSize.width - this._size.width - this._padding;

            final double yPos = isMobile 
                ? screenSize.width - this._size.height - this._padding 
                : screenSize.height - this._size.height - this._padding;

            this._position = Offset(xPos, yPos);

            this._buildContent = buildContent;
            this._onClose = onClose;
            this._onExpand = onExpand;
            this._visible = true;
        });
    }

    void close() {
        this._onClose?.call();
        this._onClose = null;
        this._onExpand = null;
        this._buildContent = null;
        super.setState(() => this._visible = false);
    }

    Widget _buildTopGradient(BuildContext context) {
        return Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [
                        0.0,
                        0.2,
                    ],
                    colors: [
                        Color(0x61000000),
                        Color(0x00000000),
                    ],
                )
            )
        );
    }

    Widget _buildBottomGradient(BuildContext context) {
        return Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [
                        0.5,
                        1.0,
                    ],
                    colors: [
                        Color(0x00000000),
                        Color(0x61000000),
                    ],
                )
            )
        );
    }

    Widget _buildControls(BuildContext context) {
        return Stack(
            children: [
                this._buildTopGradient(context),
                this._buildBottomGradient(context),
                Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: this.close,
                    ),
                ),
                Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                        icon: const Icon(Icons.fullscreen),
                        onPressed: () {
                            this._onExpand?.call();
                            super.setState(() => this._visible = false);
                        },
                    ),
                ),
                if(EPlatform.isDesktop)
                    Align(
                        alignment: Alignment.bottomLeft,
                        child: GestureDetector(
                            onPanStart: (_) => super.setState(() => this._resizing = true),
                            onPanEnd: (_) => super.setState(() => this._resizing = false),
                            onPanDown: (details) {
                                this._initialSize = this._size;
                                this._initialPosition = this._position;
                            },
                            onPanUpdate: (details) {
                                super.setState(() {
                                    double delta = details.localPosition.dx;

                                    if (this._initialPosition.dx + delta < this._padding)
                                        delta = this._padding - this._initialPosition.dx;

                                    this._resize(this._initialSize.width - delta);
                                    this._moveTo(
                                        this._initialPosition.dx + (this._initialSize.width - this._size.width),
                                        this._position.dy
                                    );
                                });
                            },
                            child: const MouseRegion(
                                cursor: SystemMouseCursors.resizeUpRightDownLeft,
                                child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                        Icons.drag_handle,
                                    ),
                                )
                            )
                        ),
                    ),
            ],
        );
    }

    Widget _buildFloatintPlayer(BuildContext context) {
        return Positioned(
            left: this._position.dx,
            top: this._position.dy,
            child: MouseRegion(
                onEnter: (_) => super.setState(() => this._showControls = true),
                onExit: (_) => super.setState(() => this._showControls = this._resizing || false),
                child: GestureDetector(
                    onTap: this._restartTimer,
                    onScaleStart: (details) {
                        if(details.pointerCount == 1) {
                            this._dragOffset = details.localFocalPoint;
                            this._initialPosition = this._position;
                            this._panning = true;
                        } else if (details.pointerCount == 2) {
                            this._initialSize = this._size;
                            this._initialPosition = this._position;
                            this._resizing = true;
                        }
                    },
                    onScaleEnd: (_) {
                        this._panning = false;
                        this._resizing = false;
                    },
                    onScaleUpdate: (details) {
                        if(this._panning)
                            super.setState(() {
                                this._moveTo(
                                    this._initialPosition.dx + details.localFocalPoint.dx - this._dragOffset.dx,
                                    this._initialPosition.dy + details.localFocalPoint.dy - this._dragOffset.dy
                                );
                            });
                        else
                            super.setState(() {
                                this._resize(this._initialSize.width * details.scale);
                                this._moveTo(
                                    this._initialPosition.dx - (this._size.width) / 2 + details.localFocalPoint.dx,
                                    this._initialPosition.dy - (this._size.height) / 2 + details.localFocalPoint.dy
                                );
                            });
                    },
                    child: Container(
                        width: this._size.width,
                        height: this._size.height,
                        decoration: BoxDecoration(
                            color: Colors.black,
                            boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                                children: [
                                    this._buildContent!.call(context),
                                    if (this._showControls || this._resizing)
                                        this._buildControls(context)
                                ],
                            ),
                        ),
                    )
                )
            )
        );
    }

    @override
    Widget build(BuildContext context) {
        return Stack(
            children: [
                if(super.widget.child != null)
                    super.widget.child!,
                if(this.visible)
                    this._buildFloatintPlayer(context)
            ],
        );
    }

    void _moveTo(double x, double y) {
        Size screenSize = MediaQuery.of(context).size;
        double maxX = screenSize.width - this._size.width - this._padding;
        double maxY = screenSize.height - this._size.height - this._padding;

        this._position = Offset(
            x.clamp(this._padding, maxX),
            y.clamp(this._padding, maxY)
        );
    }

    void _resize(double width) {
        double aspectRatio = this._initialSize.aspectRatio;
        Size screenSize = MediaQuery.of(context).size;

        width = width.clamp(this._minSize.width, screenSize.width - this._position.dx - this._padding);

        double height = width / aspectRatio;
        height = height.clamp(this._minSize.height, screenSize.height - this._position.dy - this._padding);
        
        width = (height * aspectRatio).clamp(this._minSize.width, double.infinity);

        this._size = Size(width, height);
    }

    void _restartTimer() {
        this._timer?.cancel();
        super.setState(() => this._showControls = !this._showControls);
        this._timer = Timer(const Duration(seconds: 3), () {
            super.setState(() => this._showControls = false);
        });
    }
}
