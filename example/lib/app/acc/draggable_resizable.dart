import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:hycop/common/util/logger.dart';
import 'acc_const.dart';
import 'draggable_point.dart';
import 'floating_action_icon.dart';
import 'resize_point.dart';

/// {@template drag_update}
/// Drag update model which includes the position and size.
/// {@endtemplate}
class DragUpdate {
  /// {@macro drag_update}
  const DragUpdate({
    required this.angle,
    required this.position,
    required this.size,
    required this.constraints,
  });

  /// The angle of the draggable asset.
  final double angle;

  /// The position of the draggable asset.
  final Offset position;

  /// The size of the draggable asset.
  final Size size;

  /// The constraints of the parent view.
  final Size constraints;
}

/// {@template draggable_resizable}
/// A widget which allows a user to drag and resize the provided [child].
/// {@endtemplate}
class DraggableResizable extends StatefulWidget {
  /// {@macro draggable_resizable}
  DraggableResizable({
    Key? key,
    required this.mid,
    required this.child,
    required this.size,
    required this.position,
    required this.angle,
    BoxConstraints? constraints,
    this.onUpdate,
    this.onLayerTapped,
    this.onEdit,
    this.onDelete,
    this.canTransform = false,
  })  : constraints = constraints ?? BoxConstraints.loose(Size.infinite),
        super(key: key);

  /// The child which will be draggable/resizable.
  final Widget child;

  // final VoidCallback? onTap;

  /// Drag/Resize value setter.
  //final ValueSetter<DragUpdate>? onUpdate;
  final void Function(DragUpdate value, String mid)? onUpdate;

  /// Delete callback
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLayerTapped;

  /// Whether or not the asset can be dragged or resized.
  /// Defaults to false.
  final bool canTransform;

  /// The child's original size.
  final String mid;
  final Size size;
  final Offset position;
  final double angle;

  /// The child's constraints.
  /// Defaults to [BoxConstraints.loose(Size.infinite)].
  final BoxConstraints constraints;

  @override
  // ignore: library_private_types_in_public_api
  _DraggableResizableState createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  late Size size;
  late Offset position;
  late BoxConstraints constraints;
  late double angle;
  late double angleDelta;
  late double baseAngle;

  bool get isTouchInputSupported => true;

  @override
  void initState() {
    logger.finest('_DraggableResizableState.initState()');
    super.initState();
    size = widget.size;
    constraints = const BoxConstraints.expand(width: 1, height: 1);
    angle = widget.angle;
    position = widget.position;
    baseAngle = 0;
    angleDelta = 0;
  }

  @override
  Widget build(BuildContext context) {
    // size = widget.size;
    // angle = widget.angle;
    // position = widget.position;

    final aspectRatio = widget.size.width / widget.size.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        position = (position == Offset.zero)
            ? Offset(
                constraints.maxWidth / 2 - (size.width / 2),
                constraints.maxHeight / 2 - (size.height / 2),
              )
            : position;

        final normalizedWidth = size.width;
        final normalizedHeight = normalizedWidth / aspectRatio;
        final newSize = Size(normalizedWidth, normalizedHeight);

        if (widget.constraints.isSatisfiedBy(newSize)) {
          logger.info(
              'size updated old=(${size.width},${size.height}), new=(${newSize.width},${newSize.height})');
          size = newSize;
        } else {
          logger.info('size not updated');
          //size = newSize;
        }

        final normalizedLeft = position.dx;
        final normalizedTop = position.dy;

        void onUpdate(String hint, {bool save = true}) {
          logger.info('onUpdate($hint)');
          final normalizedPosition = Offset(
            normalizedLeft + (floatingActionPadding / 2) + (cornerDiameter / 2),
            normalizedTop + (floatingActionPadding / 2) + (cornerDiameter / 2),
          );

          if (save) {
            logger.info(
                'onUpdate($angle, ${normalizedPosition.dx},${normalizedPosition.dy}, ${size.width}, ${size.height})');
            widget.onUpdate?.call(
              DragUpdate(
                //position: normalizedPosition,
                position: position,
                size: size,
                constraints: Size(constraints.maxWidth, constraints.maxHeight),
                angle: angle,
              ),
              widget.mid,
            );
          }

          //save data here !!!
        }

        // void onDragTopLeft(Offset details) {
        //   final mid = (details.dx + details.dy) / 2;
        //   final newHeight = math.max((size.height - (2 * mid)), 0.0);
        //   final newWidth = math.max(size.width - (2 * mid), 0.0);
        //   final updatedSize = Size(newWidth, newHeight);

        //   if (!widget.constraints.isSatisfiedBy(updatedSize)) return;

        //   final updatedPosition = Offset(position.dx + mid, position.dy + mid);

        //   setState(() {
        //     size = updatedSize;
        //     position = updatedPosition;
        //   });

        //   onUpdate();
        // }

        // ignore: unused_element
        void onDragTopRight(Offset details) {
          final mid = (details.dx + (details.dy * -1)) / 2;
          final newHeight = math.max(size.height + (2 * mid), 0.0);
          final newWidth = math.max(size.width + (2 * mid), 0.0);
          final updatedSize = Size(newWidth, newHeight);

          if (!widget.constraints.isSatisfiedBy(updatedSize)) return;

          final updatedPosition = Offset(position.dx - mid, position.dy - mid);

          setState(() {
            size = updatedSize;
            position = updatedPosition;
          });

          onUpdate('onDragTopRight');
        }

        // ignore: unused_element
        void onDragBottomLeft(Offset details) {
          final mid = ((details.dx * -1) + details.dy) / 2;

          final newHeight = math.max(size.height + (2 * mid), 0.0);

          final newWidth = math.max(size.width + (2 * mid), 0.0);

          final updatedSize = Size(newWidth, newHeight);

          // if (!widget.constraints.isSatisfiedBy(updatedSize)) return;

          final updatedPosition = Offset(position.dx - mid, position.dy - mid);

          // if (updatedSize > Size(100, 100)) {
          setState(() {
            size = updatedSize;
            position = updatedPosition;
          });
          // }

          onUpdate('onDragBottomLeft');
        }

        void onDragBottomRight(Offset details) {
          final mid = (details.dx + details.dy) / 2;
          final newHeight = math.max(size.height + (2 * mid), 0.0);
          final newWidth = math.max(size.width + (2 * mid), 0.0);
          final updatedSize = Size(newWidth, newHeight);

          // if (!widget.constraints.isSatisfiedBy(updatedSize)) return;

          final updatedPosition = Offset(position.dx - mid, position.dy - mid);
          // minimum size of the sticker should be Size(50,50)
          if (updatedSize > const Size(50, 50)) {
            setState(() {
              size = updatedSize;
              position = updatedPosition;
            });
          }

          onUpdate('onDragBottomRight');
        }

        final decoratedChild = Container(
          key: const Key('draggableResizable_child_container'),
          alignment: Alignment.center,
          height: normalizedHeight + cornerDiameter + floatingActionPadding,
          width: normalizedWidth + cornerDiameter + floatingActionPadding,
          child: Container(
            height: normalizedHeight,
            width: normalizedWidth,
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: widget.canTransform ? Colors.blue : Colors.transparent,
              ),
            ),
            child: Center(child: widget.child),
          ),
        );
        final topLeftCorner = FloatingActionIcon(
          key: const Key('draggableResizable_edit_floatingActionIcon'),
          iconData: Icons.edit,
          onTap: widget.onEdit,
        );

        final topCenter = FloatingActionIcon(
          key: const Key('draggableResizable_layer_floatingActionIcon'),
          iconData: Icons.layers,
          onTap: widget.onLayerTapped,
        );
        // final topLeftCorner = ResizePoint(
        //   key: const Key('draggableResizable_topLeft_resizePoint'),
        //   type: ResizePointType.topLeft,
        //   onDrag: onDragTopLeft,
        // );

        // final topRightCorner = ResizePoint(
        //   key: const Key('draggableResizable_topRight_resizePoint'),
        //   type: ResizePointType.topRight,
        //   onDrag: onDragTopRight,
        // );

        // final bottomLeftCorner = ResizePoint(
        //   key: const Key('draggableResizable_bottomLeft_resizePoint'),
        //   type: ResizePointType.bottomLeft,
        //   onDrag: onDragBottomLeft,
        //   // iconData: Icons.zoom_out_map,
        // );

        final bottomRightCorner = ResizePoint(
          key: const Key('draggableResizable_bottomRight_resizePoint'),
          type: ResizePointType.bottomRight,
          onDrag: onDragBottomRight,
          iconData: Icons.zoom_out_map,
        );

        final deleteButton = FloatingActionIcon(
          key: const Key('draggableResizable_delete_floatingActionIcon'),
          iconData: Icons.delete,
          onTap: widget.onDelete,
        );

        final center = Offset(
          -((normalizedHeight / 2) +
              (floatingActionDiameter / 2) +
              (cornerDiameter / 2) +
              (floatingActionPadding / 2)),
          // (floatingActionDiameter + cornerDiameter) / 2,
          (normalizedHeight / 2) +
              (floatingActionDiameter / 2) +
              (cornerDiameter / 2) +
              (floatingActionPadding / 2),
        );

        final rotateAnchor = GestureDetector(
          key: const Key('draggableResizable_rotate_gestureDetector'),
          onScaleStart: (details) {
            final offsetFromCenter = details.localFocalPoint - center;
            setState(
                () => angleDelta = baseAngle - offsetFromCenter.direction - floatingActionDiameter);
          },
          onScaleUpdate: (details) {
            final offsetFromCenter = details.localFocalPoint - center;

            setState(
              () {
                angle = offsetFromCenter.direction + angleDelta * 0.5;
              },
            );
            onUpdate('onScaleUpdate');
          },
          onScaleEnd: (_) => setState(() => baseAngle = angle),
          child: FloatingActionIcon(
            key: const Key('draggableResizable_rotate_floatingActionIcon'),
            iconData: Icons.rotate_90_degrees_ccw,
            onTap: () {},
          ),
        );

        if (this.constraints != constraints) {
          this.constraints = constraints;
          onUpdate('default', save: false);
        }

        return Stack(
          children: <Widget>[
            Positioned(
              top: normalizedTop,
              left: normalizedLeft,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(1.0)
                  ..rotateZ(angle),
                child: DraggablePoint(
                  key: const Key('draggableResizable_child_draggablePoint'),
                  onTap: () {
                    onUpdate('onTap', save: false);
                  },
                  onDrag: (d) {
                    setState(() {
                      position = Offset(position.dx + d.dx, position.dy + d.dy);
                    });
                    onUpdate('onDrag');
                  },
                  onScale: (s) {
                    final updatedSize = Size(
                      widget.size.width * s,
                      widget.size.height * s,
                    );

                    if (!widget.constraints.isSatisfiedBy(updatedSize)) return;

                    final midX = position.dx + (size.width / 2);
                    final midY = position.dy + (size.height / 2);
                    final updatedPosition = Offset(
                      midX - (updatedSize.width / 2),
                      midY - (updatedSize.height / 2),
                    );

                    setState(() {
                      size = updatedSize;
                      position = updatedPosition;
                    });
                    onUpdate('onScale');
                  },
                  onRotate: (a) {
                    setState(() => angle = a * 0.5);
                    onUpdate('onRotate');
                  },
                  child: Stack(
                    children: [
                      decoratedChild,
                      if (widget.canTransform && isTouchInputSupported) ...[
                        Positioned(
                          top: floatingActionPadding / 2,
                          left: floatingActionPadding / 2,
                          child: topLeftCorner,
                        ),
                        Positioned(
                          right: (normalizedWidth / 2) -
                              (floatingActionDiameter / 2) +
                              (cornerDiameter / 2) +
                              (floatingActionPadding / 2),
                          child: topCenter,
                        ),
                        Positioned(
                          bottom: floatingActionPadding / 2,
                          left: floatingActionPadding / 2,
                          child: deleteButton,
                        ),
                        Positioned(
                          top: normalizedHeight + floatingActionPadding / 2,
                          left: normalizedWidth + floatingActionPadding / 2,
                          child: bottomRightCorner,
                        ),
                        Positioned(
                          top: floatingActionPadding / 2,
                          right: floatingActionPadding / 2,
                          child: rotateAnchor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
