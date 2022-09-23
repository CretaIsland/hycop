import 'package:flutter/material.dart';
import 'package:hycop/common/util/logger.dart';
import 'draggable_resizable.dart';
import 'stickerview.dart';

class DraggableStickers extends StatefulWidget {
  //List of stickers (elements)
  final List<Sticker> stickerList;
  final void Function(DragUpdate, String) onUpdate;
  final void Function(String) onDelete;

  // ignore: use_key_in_widget_constructors
  const DraggableStickers(
      {required this.stickerList, required this.onUpdate, required this.onDelete});
  @override
  State<DraggableStickers> createState() => _DraggableStickersState();
}

String? selectedAssetId;

class _DraggableStickersState extends State<DraggableStickers> {
  // initial scale of sticker
  final _initialStickerScale = 5.0;

  List<Sticker> stickers = [];
  @override
  void initState() {
    // setState(() {
    //   stickers = widget.stickerList ?? [];
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    stickers = widget.stickerList;
    return stickers.isNotEmpty && stickers != []
        ? Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('stickersView_background_gestureDetector'),
                  onTap: () {
                    logger.info('GestureDetector.onTap');
                  },
                ),
              ),
              for (final sticker in stickers)
                // Main widget that handles all features like rotate, resize, edit, delete, layer update etc.
                DraggableResizable(
                  key: UniqueKey(),
                  mid: sticker.id,
                  angle: sticker.angle,
                  position: sticker.position,
                  // Size of the sticker
                  size: sticker.isText == true
                      ? Size(64 * _initialStickerScale / 3, 64 * _initialStickerScale / 3)
                      //: Size(64 * _initialStickerScale, 64 * _initialStickerScale),
                      : sticker.size,

                  canTransform: selectedAssetId == sticker.id ? true : false

                  //  true
                  /*sticker.id == state.selectedAssetId*/,
                  onUpdate: (update, mid) {
                    logger.info(
                        "oldposition=${sticker.position.toString()}, new=${update.position.toString()}");

                    sticker.angle = update.angle;
                    sticker.size = update.size;
                    sticker.position = update.position;
                    widget.onUpdate.call(update, mid);
                    logger.info("saved");
                  },

                  // To update the layer (manage position of widget in stack)
                  onLayerTapped: () {
                    var listLength = stickers.length;
                    var ind = stickers.indexOf(sticker);
                    stickers.remove(sticker);
                    if (ind == listLength - 1) {
                      stickers.insert(0, sticker);
                    } else {
                      stickers.insert(listLength - 1, sticker);
                    }

                    selectedAssetId = sticker.id;
                    logger.info('onLayerTapped');
                    setState(() {});
                  },

                  // To edit (Not implemented yet)
                  onEdit: () {},

                  // To Delete the sticker
                  onDelete: () async {
                    {
                      stickers.remove(sticker);
                      widget.onDelete.call(sticker.id);
                      setState(() {});
                    }
                  },

                  // Constraints of the sticker
                  constraints: sticker.isText == true
                      ? BoxConstraints.tight(
                          Size(
                            64 * _initialStickerScale / 3,
                            64 * _initialStickerScale / 3,
                          ),
                        )
                      : BoxConstraints.tight(
                          Size(
                            64 * _initialStickerScale,
                            64 * _initialStickerScale,
                          ),
                        ),

                  // Child widget in which sticker is passed
                  child: InkWell(
                    splashColor: Colors.transparent,
                    onTap: () {
                      // To update the selected widget
                      selectedAssetId = sticker.id;
                      logger.info('onTap...');
                      setState(() {});
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: sticker.isText == true ? FittedBox(child: sticker) : sticker,
                    ),
                  ),
                ),
            ],
          )
        : Container();
  }
}
