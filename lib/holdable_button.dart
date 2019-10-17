import 'package:flutter/material.dart';
import 'dart:math' as math;

class HoldableButton extends StatefulWidget {
  /// Function when held for the set duration (ms)
  final Function onHeld;

  /// Function when tapped (can be omitted)
  final Function onTapped;

  /// Duration until onHeld is called
  final int duration;

  /// Duration until its no longer a tap
  final int tapDuration;

  /// Interval between updates (ms)
  final int interval;

  /// Size of the button
  final double size;

  /// Initial color of the progress bar
  final Color progressColorFrom;

  /// Final color of the progress bar
  final Color progressColorTo;

  /// Background color of the progress bar
  final Color progressBackgroundColor;

  /// Controls if the button should change size when pressed or held.
  final bool grow;

  /// If you want the progress bar to grow in a counter clockwise direction.
  final bool counterClockwiseProgress;

  final Widget child;

  /// A button which expands as it is held, confirming the action and activating after being held for [duration] milliseconds.
  /// The button also holds a [CircularProgressIndicator] for feedback.
  const HoldableButton({
    Key key,
    this.onTapped,
    @required this.onHeld,
    this.duration = 750,
    this.tapDuration = 200,
    this.interval = 10,
    this.size = 128.0,
    this.progressColorFrom = Colors.blue,
    this.progressColorTo = Colors.blue,
    this.progressBackgroundColor = Colors.transparent,
    this.grow = true,
    this.counterClockwiseProgress = false,
    @required this.child,
  })  : assert(duration > tapDuration,
            'The duration of the button press must be longer than a tap'),
        super(key: key);

  @override
  _HoldableButtonState createState() => _HoldableButtonState();
}

class _HoldableButtonState extends State<HoldableButton>
    with TickerProviderStateMixin {
  AnimationController _scaleController;
  AnimationController _fadeController;
  AnimationController _colorController;
  num _timeHeld = 0.0;
  bool _buttonPressed = false;
  bool _loopActive = false;

  @override
  void initState() {
    _scaleController = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: (widget.duration - widget.tapDuration) * 2),
      lowerBound: 0.75,
      upperBound: 1.0,
      reverseDuration: Duration(milliseconds: 200),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _colorController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration * 2),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(
        widget.size,
      ),
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(
          widget.size,
        ),
        onTapDown: (t) => _handleDown(),
        onTap: _handleUp,
        onTapCancel: _handleUp,
        child: Stack(
          children: <Widget>[
            Center(
              child: ScaleTransition(
                  scale: (widget.grow)
                      ? Tween(begin: 0.0, end: 1.0).animate(_scaleController)
                      : Tween(begin: 1.0, end: 1.0).animate(_scaleController),
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: ClipOval(
                      child: Container(
                        child: Center(
                          child: widget.child,
                        ),
                      ),
                    ),
                  )),
            ),
            Center(
              child: SizedBox(
                height: widget.size,
                width: widget.size,
                child: FadeTransition(
                  opacity: TweenSequence([
                    TweenSequenceItem(
                      tween: Tween(begin: 0.0, end: 0.0),
                      weight: 1.0,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 0.0, end: 1.0),
                      weight: 2.0,
                    ),
                  ]).animate(_fadeController),
                  child: Transform(
                    transform: widget.counterClockwiseProgress
                        ? (Matrix4.identity()
                          ..rotateY(math.pi)
                          ..translate(-widget.size))
                        : Matrix4.identity(),
                    child: CircularProgressIndicator(
                      backgroundColor: widget.progressBackgroundColor,
                      valueColor: ColorTween(
                              begin: widget.progressColorFrom,
                              end: widget.progressColorTo)
                          .animate(_colorController),
                      strokeWidth: widget.size / 16.0,
                      value: _timeHeld / widget.duration,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDown() async {
    if (_loopActive) return;
    setState(() {
      _loopActive = true;
      _buttonPressed = true;
    });
    _fadeController.animateTo(1.0);
    _colorController.forward(from: 0);
    while (_buttonPressed) {
      setState(() {
        _timeHeld = _timeHeld + widget.interval;
      });
      if (_timeHeld >= widget.tapDuration &&
          _scaleController.velocity == 0 &&
          _timeHeld != widget.tapDuration) {
        _scaleController.forward(from: 0);
      }
      if (_timeHeld >= widget.duration) _handleHeld();
      await Future.delayed(Duration(milliseconds: widget.interval));
    }
    setState(() {
      _loopActive = false;
    });
  }

  void _handleUp() {
    if (_buttonPressed) {
      _scaleController.animateBack(0.0,
          curve: Curves.bounceOut, duration: Duration(milliseconds: 350));
      _handleTap();
      setState(() {
        _buttonPressed = false;
        _timeHeld = 0.0;
      });
      _fadeController.value = 0.0;
    }
  }

  void _handleTap() async {
    if (_timeHeld < widget.tapDuration && widget.onTapped != null) {
      widget.onTapped();
      await _scaleController.animateTo(0.825,
          duration: Duration(milliseconds: 100));
      _scaleController.animateBack(0.0, duration: Duration(milliseconds: 50));
    }
  }

  void _handleHeld() async {
    _handleUp();
    if (widget.onHeld != null) {
      widget.onHeld();
    }
  }
}
