import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:themed/themed.dart';

class CustomChatInput extends StatelessWidget {
  static const List<List<String>> _attachmentNameList = [
    ['camera', 'Camera'],
    ['gif', 'GIF'],
    ['document', 'File'],
    ['location', 'Location'],
  ];

  final Function()? onButtonPressed;
  final bool isChatScreen;
  final String roomName;

  const CustomChatInput({
    Key? key,
    required this.isChatScreen,
    this.onButtonPressed,
    required this.roomName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        GetBuilder<ChatRoomController>(
          builder: (ChatRoomController controller) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: AppCommonTheme.backgroundColorLight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentButton(controller),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _buildTextEditor(context, controller),
                        ),
                      ),
                      if (controller.isSendButtonVisible || !isChatScreen)
                        _buildSendButton(),
                      if (!controller.isSendButtonVisible && isChatScreen)
                        _buildImageButton(context, controller),
                      if (!controller.isSendButtonVisible && isChatScreen)
                        const SizedBox(width: 10),
                      if (!controller.isSendButtonVisible && isChatScreen)
                        _buildAudioButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        EmojiPickerWidget(size: size),
        AttachmentWidget(
          attachmentNameList: _attachmentNameList,
          roomName: roomName,
          size: size,
        ),
      ],
    );
  }

  Widget _buildAttachmentButton(ChatRoomController controller) {
    if (isChatScreen != true) {
      return const SizedBox();
    }
    return Obx(
      () => InkWell(
        onTap: () {
          controller.isEmojiVisible.value = false;
          controller.isAttachmentVisible.value =
              !controller.isAttachmentVisible.value;
          controller.focusNode.unfocus();
          controller.focusNode.canRequestFocus = true;
        },
        child: _buildAttachmentIcon(controller),
      ),
    );
  }

  Widget _buildAttachmentIcon(ChatRoomController controller) {
    if (controller.isAttachmentVisible.value != true) {
      return SvgPicture.asset('assets/images/add.svg', fit: BoxFit.none);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppCommonTheme.backgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: SvgPicture.asset('assets/images/add_rotate.svg', fit: BoxFit.none),
    );
  }

  Widget _buildTextEditor(BuildContext context, ChatRoomController controller) {
    return TextField(
      onChanged: (value) async {
        controller.sendButtonUpdate();
        await controller.typingNotice(true);
      },
      maxLines:
          MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 2,
      minLines: 1,
      controller: controller.textEditingController,
      focusNode: controller.focusNode,
      style: const TextStyleRef(
        TextStyle(color: ChatTheme01.chatInputTextColor),
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        suffixIcon: InkWell(
          onTap: () {
            controller.isAttachmentVisible.value = false;
            controller.isEmojiVisible.value = !controller.isEmojiVisible.value;
            controller.focusNode.unfocus();
            controller.focusNode.canRequestFocus = true;
          },
          child: SvgPicture.asset('assets/images/emoji.svg', fit: BoxFit.none),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
        filled: true,
        fillColor: AppCommonTheme.backgroundColor,
        hintText: isChatScreen
            ? AppLocalizations.of(context)!.newMessage
            : '${AppLocalizations.of(context)!.messageTo} $roomName',
        contentPadding: const EdgeInsets.all(15),
        hintStyle: ChatTheme01.chatInputPlaceholderStyle,
        hintMaxLines: 1,
      ),
    );
  }

  Widget _buildSendButton() {
    return InkWell(
      onTap: onButtonPressed,
      child: SvgPicture.asset('assets/images/sendIcon.svg'),
    );
  }

  Widget _buildImageButton(
    BuildContext context,
    ChatRoomController controller,
  ) {
    return InkWell(
      onTap: () {
        controller.handleMultipleImageSelection(context, roomName);
      },
      child: SvgPicture.asset('assets/images/camera.svg', fit: BoxFit.none),
    );
  }

  Widget _buildAudioButton() {
    return SvgPicture.asset('assets/images/microphone-2.svg', fit: BoxFit.none);
  }
}

class AttachmentWidget extends StatelessWidget {
  final List<List<String>> attachmentNameList;
  final String roomName;
  final Size size;
  final ChatRoomController _roomController = Get.find<ChatRoomController>();

  AttachmentWidget({
    Key? key,
    required this.attachmentNameList,
    required this.roomName,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Offstage(
        offstage: !_roomController.isAttachmentVisible.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          width: double.infinity,
          height: size.height * 0.3,
          color: AppCommonTheme.backgroundColorLight,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: size.height * 0.172,
                decoration: BoxDecoration(
                  color: AppCommonTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _buildSettingButton(context),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (List<String> item in attachmentNameList)
                        _buildItem(context, item),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingButton(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            AppLocalizations.of(context)!.grantAccessText,
            style: ChatTheme01.chatTitleStyle + FontWeight.w400,
          ),
        ),
        ElevatedButton(
          onPressed: () {},
          child: Text(AppLocalizations.of(context)!.settings),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              AppCommonTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, List<String> item) {
    return InkWell(
      onTap: () {
        switch (item[0]) {
          case 'camera':
            _roomController.isAttachmentVisible.value = false;
            _roomController.handleMultipleImageSelection(context, roomName);
            break;
          case 'gif':
            //gif handle
            break;
          case 'document':
            _roomController.handleFileSelection(context);
            break;
          case 'location':
            //location handle
            break;
        }
      },
      child: Container(
        width: 85,
        decoration: BoxDecoration(
          color: AppCommonTheme.backgroundColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/${item[0]}.svg', fit: BoxFit.none),
            const SizedBox(height: 6),
            Text(item[1], style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class EmojiPickerWidget extends StatelessWidget {
  final Size size;
  final ChatRoomController _roomController = Get.find<ChatRoomController>();

  EmojiPickerWidget({Key? key, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Offstage(
        offstage: !_roomController.isEmojiVisible.value,
        child: SizedBox(
          height: size.height * 0.3,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              _roomController.textEditingController.text += emoji.emoji;
              _roomController.sendButtonUpdate();
            },
            onBackspacePressed: () {
              _roomController.textEditingController.text = _roomController
                  .textEditingController.text.characters
                  .skipLast(1)
                  .string;
              if (_roomController.textEditingController.text.isEmpty) {
                _roomController.sendButtonUpdate();
              }
            },
            config: Config(
              columns: 7,
              verticalSpacing: 0,
              backspaceColor: AppCommonTheme.primaryColor,
              horizontalSpacing: 0,
              initCategory: Category.SMILEYS,
              bgColor: AppCommonTheme.backgroundColor,
              indicatorColor: AppCommonTheme.primaryColor,
              iconColor: AppCommonTheme.dividerColor,
              iconColorSelected: AppCommonTheme.primaryColor,
              progressIndicatorColor: AppCommonTheme.primaryColor,
              showRecentsTab: true,
              recentsLimit: 28,
              noRecents: Text(
                AppLocalizations.of(context)!.noRecents,
                style: ChatTheme01.chatBodyStyle,
              ),
              tabIndicatorAnimDuration: kTabScrollDuration,
              categoryIcons: const CategoryIcons(),
              buttonMode: ButtonMode.MATERIAL,
            ),
          ),
        ),
      ),
    );
  }
}