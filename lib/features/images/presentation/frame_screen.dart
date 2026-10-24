import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/features/images/application/image_library.dart';
import 'package:visual_time_counter/features/images/application/my_images_controller.dart';
import 'package:visual_time_counter/features/images/domain/frame_spec.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// A picked file to frame: its bytes, for processing, and a decoded
/// [preview] to drag around.
@immutable
final class FrameRequest {
  /// Creates the request.
  const new({required this.bytes, required this.preview});

  /// The file as picked.
  final Uint8List bytes;

  /// The decoded picture shown while framing.
  final ui.Image preview;
}

/// Frame an own image in the dial's circle (contracts/ui/04 §4.2, FR-022);
/// pops the saved [UserImageSource], or null when cancelled.
class FrameScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [request].
  const new({required this.request, super.key = const Key('frame.screen')});

  /// What to frame.
  final FrameRequest request;

  @override
  ConsumerState<FrameScreen> createState() => _FrameScreenState();
}

class _FrameScreenState extends ConsumerState<FrameScreen> {
  static const _zoomStep = 0.1;
  static const _zoomDivisions = 30;
  static const _keyboardStep = 8.0;
  static const _overlayDelay = Duration(milliseconds: 300);
  static const _maxCanvasSize = 480.0;

  final _focusNode = FocusNode(debugLabel: 'FrameCanvas');
  final _name = TextEditingController();

  double _zoom = FrameSpec.minZoom;
  Offset _center = const Offset(0.5, 0.5);
  double _zoomAtGestureStart = FrameSpec.minZoom;

  /// The canvas side in logical pixels, from the last layout.
  double _canvasSize = 1;
  bool _isSaving = false;
  bool _showsPreparing = false;

  ui.Image get _preview => widget.request.preview;

  @override
  void dispose() {
    _focusNode.dispose();
    _name.dispose();
    super.dispose();
  }

  /// The side of the square under the circle, in image pixels.
  double get _cropSide => min(_preview.width, _preview.height) / _zoom;

  /// Screen pixels per image pixel.
  double get _scale => _canvasSize / _cropSide;

  /// Keeps the circle inside the picture.
  Offset _clampedCenter(Offset center) {
    final halfWidth = _cropSide / 2 / _preview.width;
    final halfHeight = _cropSide / 2 / _preview.height;
    return Offset(
      center.dx.clamp(halfWidth, 1 - halfWidth),
      center.dy.clamp(halfHeight, 1 - halfHeight),
    );
  }

  /// Moves the picture by [delta] screen pixels under the circle.
  void _moveBy(Offset delta) => setState(() {
    _center = _clampedCenter(
      _center -
          Offset(
            delta.dx / _scale / _preview.width,
            delta.dy / _scale / _preview.height,
          ),
    );
  });

  void _setZoom(double zoom) => setState(() {
    _zoom = zoom.clamp(FrameSpec.minZoom, FrameSpec.maxZoom);
    _center = _clampedCenter(_center);
  });

  /// One slider step, kept on the 0.1 grid.
  void _stepZoom(int steps) =>
      _setZoom(((_zoom + steps * _zoomStep) / _zoomStep).round() * _zoomStep);

  void _reset() => setState(() {
    _zoom = FrameSpec.minZoom;
    _center = const Offset(0.5, 0.5);
  });

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final move = switch (key) {
      LogicalKeyboardKey.arrowLeft => const Offset(-_keyboardStep, 0),
      LogicalKeyboardKey.arrowRight => const Offset(_keyboardStep, 0),
      LogicalKeyboardKey.arrowUp => const Offset(0, -_keyboardStep),
      LogicalKeyboardKey.arrowDown => const Offset(0, _keyboardStep),
      _ => null,
    };
    if (move != null) {
      _moveBy(move);
    } else if (key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.equal) {
      _stepZoom(1);
    } else if (key == LogicalKeyboardKey.numpadSubtract ||
        key == LogicalKeyboardKey.minus) {
      _stepZoom(-1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final overlayTimer = Timer(_overlayDelay, () {
      if (mounted) setState(() => _showsPreparing = true);
    });
    try {
      final processed = await ref
          .read(imageProcessorProvider)
          .process(
            widget.request.bytes,
            FrameSpec(centerX: _center.dx, centerY: _center.dy, zoom: _zoom),
          );
      final image = await ref
          .read(userImagesProvider.notifier)
          .add(processed, label: _name.text);
      if (mounted) context.pop(UserImageSource(image.id));
    } on Object catch (error) {
      debugPrint('Could not save the framed image: $error');
      if (mounted) _showError();
    } finally {
      overlayTimer.cancel();
      if (mounted) {
        setState(() {
          _isSaving = false;
          _showsPreparing = false;
        });
      }
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('frame.error'),
        content: Text(AppLocalizations.of(context).frameError),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final margin = ScreenLayout.of(MediaQuery.sizeOf(context)).margin;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              key: const Key('frame.cancel'),
              tooltip: l10n.commonCancel,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(l10n.frameTitle),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                // Filled: the text contrast guideline misreads text buttons.
                child: FilledButton(
                  key: const Key('frame.save'),
                  onPressed: _isSaving ? null : _save,
                  child: Text(l10n.frameSave),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(margin),
              children: [
                Center(child: _buildCanvas(l10n)),
                const SizedBox(height: 16),
                _buildZoomRow(l10n),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('frame.reset'),
                    onPressed: _reset,
                    icon: const Icon(Icons.center_focus_strong_outlined),
                    label: Text(l10n.frameCenter),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('frame.name'),
                  controller: _name,
                  maxLength: UserImageAsset.maxLabelLength,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: l10n.frameName),
                ),
              ],
            ),
          ),
        ),
        if (_showsPreparing) _PreparingOverlay(label: l10n.framePreparing),
      ],
    );
  }

  Widget _buildCanvas(AppLocalizations l10n) => LayoutBuilder(
    builder: (context, constraints) {
      _canvasSize = min(constraints.maxWidth, _maxCanvasSize);
      return Semantics(
        label: l10n.frameCanvasLabel,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _onKey,
          child: Listener(
            onPointerDown: (_) => _focusNode.requestFocus(),
            child: GestureDetector(
              key: const Key('frame.canvas'),
              onScaleStart: (_) => _zoomAtGestureStart = _zoom,
              onScaleUpdate: (details) {
                if (details.pointerCount > 1) {
                  _setZoom(_zoomAtGestureStart * details.scale);
                }
                _moveBy(details.focalPointDelta);
              },
              child: SizedBox.square(
                dimension: _canvasSize,
                child: ClipRect(
                  child: CustomPaint(
                    painter: _FramePainter(
                      image: _preview,
                      center: _center,
                      scale: _scale,
                      maskColor: Colors.black.withValues(alpha: 0.6),
                      ringColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _buildZoomRow(AppLocalizations l10n) => Row(
    children: [
      IconButton(
        tooltip: l10n.frameZoomOut,
        icon: const Icon(Icons.remove_rounded),
        onPressed: _zoom > FrameSpec.minZoom ? () => _stepZoom(-1) : null,
      ),
      Expanded(
        // One node: "Zoom, 150%".
        child: MergeSemantics(
          child: Semantics(
            label: l10n.frameZoom,
            child: Slider(
              key: const Key('frame.zoom'),
              value: _zoom,
              min: FrameSpec.minZoom,
              max: FrameSpec.maxZoom,
              divisions: _zoomDivisions,
              semanticFormatterCallback: (value) =>
                  l10n.frameZoomValue((value * 100).round()),
              onChanged: _setZoom,
            ),
          ),
        ),
      ),
      IconButton(
        tooltip: l10n.frameZoomIn,
        icon: const Icon(Icons.add_rounded),
        onPressed: _zoom < FrameSpec.maxZoom ? () => _stepZoom(1) : null,
      ),
    ],
  );
}

/// The picture positioned under the circle, darkened outside it.
class _FramePainter extends CustomPainter {
  const new({
    required this.image,
    required this.center,
    required this.scale,
    required this.maskColor,
    required this.ringColor,
  });

  final ui.Image image;
  final Offset center;
  final double scale;
  final Color maskColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = Size(image.width * scale, image.height * scale);
    final topLeft =
        size.center(Offset.zero) -
        Offset(center.dx * imageSize.width, center.dy * imageSize.height);
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      topLeft & imageSize,
      Paint()..filterQuality = FilterQuality.medium,
    );

    final circle = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2,
    );
    canvas
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addOval(circle),
        Paint()..color = maskColor,
      )
      ..drawOval(
        circle.deflate(1),
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.center != center ||
      oldDelegate.scale != scale ||
      oldDelegate.maskColor != maskColor ||
      oldDelegate.ringColor != ringColor;
}

/// Shown when saving takes longer than 300 ms.
class _PreparingOverlay extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: Card(
            key: const Key('frame.preparing'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
