import 'package:hycop/common/util/logger.dart';
import '../data_io/book_manager.dart';
import 'package:flutter/material.dart';

import '../model/book_model.dart';
import 'constants.dart';

class BookListWidget extends StatefulWidget {
  final BookModel item;
  final Animation<double> animation;
  final VoidCallback onDeleteClicked;
  final VoidCallback onSaveClicked;
  const BookListWidget({
    Key? key,
    required this.item,
    required this.animation,
    required this.onDeleteClicked,
    required this.onSaveClicked,
  }) : super(key: key);

  @override
  State<BookListWidget> createState() => _BookListWidgetState();
}

class _BookListWidgetState extends State<BookListWidget> {
  static final Map<String, bool> _editModeMap = {};

  final TextEditingController _controller = TextEditingController();

  static int randomindex = 0;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      key: ValueKey(widget.item.mid),
      sizeFactor: widget.animation,
      child: Container(
        margin: const EdgeInsets.all(8),
        //width: 800,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white30,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          visualDensity: VisualDensity.compact,
          leading: CircleAvatar(
            radius: 32,
            backgroundImage: getImage(widget.item),
          ),
          title: (_editModeMap[widget.item.mid] ?? false)
              ? TextFormField(
                  onEditingComplete: () {
                    if (_controller.text.isNotEmpty) {
                      widget.item.name.set(_controller.text);
                      widget.onSaveClicked.call();
                    }
                    setState(() {
                      _editModeMap.clear();
                    });
                  },
                  controller: _controller,
                  decoration: InputDecoration(hintText: widget.item.name.value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Cannot be empty';
                    }
                    return null;
                  })
              : Text(
                  '${widget.item.name.value},   ${widget.item.mid},   ${widget.item.updateTime.toIso8601String()}',
                  style: const TextStyle(fontSize: 20, color: Colors.black),
                ),
          subtitle: Text(
            widget.item.hashTag.value,
            style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
          ),
          trailing: IconButton(
              onPressed: widget.onDeleteClicked,
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 32,
              )),
          onTap: () {
            _editModeMap.clear();
            bookManagerHolder!.notify();
          },
          onLongPress: () {
            setState(() {
              _editModeMap.clear();
              _editModeMap[widget.item.mid] = true;
            });
            bookManagerHolder!.notify();
          },
        ),
      ),
    );
  }

  ImageProvider<Object> getImage(BookModel item) {
    if (item.thumbnailUrl.value.isNotEmpty) {
      logger.finest('thumbnail=${item.thumbnailUrl.value}');
      return NetworkImage(item.thumbnailUrl.value);
    }
    return AssetImage(sampleImageList[(++randomindex) % sampleImageList.length]);
  }
}
