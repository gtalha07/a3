import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum NewsSlideType {
  text,
  image,
  video,
}

class NewsSlideItem {
  NewsSlideType type;
  String? text;
  Color? textBackgroundColor;
  XFile? mediaFile;

  NewsSlideItem({
    required this.type,
    this.text,
    this.textBackgroundColor,
    this.mediaFile,
  });
}