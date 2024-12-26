import 'dart:io';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/news/model/news_post_color_data.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _log = Logger('a3::news::utils');

class NewsUtils {
  static ImagePicker imagePicker = ImagePicker();

  static Future<File?> getThumbnailData(XFile videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final videoName = p.basenameWithoutExtension(videoFile.path);
      final destPath = p.join(tempDir.path, '$videoName.jpg');
      final destFile = File(destPath);

      if (await destFile.exists()) {
        return destFile;
      }

      final thumbnailGenerated =
          await FcNativeVideoThumbnail().getVideoThumbnail(
        srcFile: videoFile.path,
        destFile: destPath,
        width: 128,
        height: 128,
        format: 'jpeg',
        quality: 90,
      );

      if (thumbnailGenerated) {
        return destFile;
      }
    } catch (e, s) {
      // Handle platform errors.
      _log.severe('Failed to extract video thumbnail', e, s);
    }
    return null;
  }

  //Add text slide
  static void addTextSlide({
    required WidgetRef ref,
    RefDetails? refDetails,
  }) {
    final clr = getRandomElement(newsPostColors);
    NewsSlideItem textSlide = NewsSlideItem(
      type: NewsSlideType.text,
      text: '',
      backgroundColor: clr,
      refDetails: refDetails,
    );
    ref.read(newsStateProvider.notifier).addSlide(textSlide);
  }

  //Add image slide
  static Future<void> addImageSlide({
    required WidgetRef ref,
    RefDetails? refDetails,
  }) async {
    final clr = getRandomElement(newsPostColors);
    XFile? imageFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (imageFile != null) {
      final slide = NewsSlideItem(
        type: NewsSlideType.image,
        mediaFile: imageFile,
        backgroundColor: clr,
        refDetails: refDetails,
      );
      ref.read(newsStateProvider.notifier).addSlide(slide);
    }
  }

  //Add video slide
  static Future<void> addVideoSlide({
    required WidgetRef ref,
    RefDetails? refDetails,
  }) async {
    final clr = getRandomElement(newsPostColors);
    XFile? videoFile = await imagePicker.pickVideo(
      source: ImageSource.gallery,
    );
    if (videoFile != null) {
      final slide = NewsSlideItem(
        type: NewsSlideType.video,
        mediaFile: videoFile,
        backgroundColor: clr,
        refDetails: refDetails,
      );
      ref.read(newsStateProvider.notifier).addSlide(slide);
    }
  }

  static Color getBackgroundColor(BuildContext context, NewsSlide newsSlide) {
    final color = newsSlide.colors();
    return convertColor(
      color?.background(),
      Theme.of(context).colorScheme.surface,
    );
  }

  static Color getForegroundColor(BuildContext context, NewsSlide newsSlide) {
    final color = newsSlide.colors();
    return convertColor(
      color?.color(),
      Theme.of(context).colorScheme.onPrimary,
    );
  }
}
