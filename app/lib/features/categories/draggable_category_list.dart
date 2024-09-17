import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/categories/actions/save_categories.dart';
import 'package:acter/features/categories/model/CategoryModelLocal.dart';
import 'package:acter/features/categories/providers/categories_providers.dart';
import 'package:acter/features/categories/utils/category_utils.dart';
import 'package:acter/features/categories/widgets/add_edit_category.dart';
import 'package:acter/features/categories/widgets/category_header_view.dart';
import 'package:acter/features/spaces/providers/space_list_provider.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class DraggableCategoryList extends ConsumerStatefulWidget {
  final String spaceId;
  final CategoriesFor categoriesFor;

  const DraggableCategoryList({
    super.key,
    required this.spaceId,
    required this.categoriesFor,
  });

  @override
  ConsumerState<DraggableCategoryList> createState() =>
      _DraggableCategoriesListState();
}

class _DraggableCategoriesListState
    extends ConsumerState<DraggableCategoryList> {
  List<DragAndDropList>? dragAndDropList;
  late List<CategoryModelLocal> categoryList;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setDragAndDropList());
  }

  void setDragAndDropList() async {
    final categoriesManager = await ref.read(
      categoryManagerProvider(
        (spaceId: widget.spaceId, categoriesFor: widget.categoriesFor),
      ).future,
    );
    final subSpaceList =
        await ref.read(subSpacesListProvider(widget.spaceId).future);
    categoryList = getCategorisedSubSpaces(
      categoriesManager.categories().toList(),
      subSpaceList,
    );
    setDragAndDropListData();
  }

  void setDragAndDropListData() {
    dragAndDropList = List.generate(categoryList.length, (indexCategory) {
      return DragAndDropList(
        canDrag: categoryList[indexCategory].title != 'Un-categorized',
        header: CategoryHeaderView(
          categoryModelLocal: categoryList[indexCategory],
          isShowDragHandle: true,
          headerBackgroundColor:
              Theme.of(context).unselectedWidgetColor.withOpacity(0.7),
          onClickDeleteCategory: () async {
            categoryList.removeAt(indexCategory);
            await saveCategories(
              context,
              ref,
              widget.spaceId,
              CategoriesFor.spaces,
              categoryList,
            );
            setDragAndDropListData();
          },
        ),
        children: List<DragAndDropItem>.generate(
          categoryList[indexCategory].entries.length,
          (indexEntry) => DragAndDropItem(
            child: SpaceCard(
              roomId:
                  categoryList[indexCategory].entries[indexEntry].toString(),
              margin: const EdgeInsets.symmetric(vertical: 6),
              leading: Icon(PhosphorIcons.dotsSixVertical()),
            ),
          ),
        ),
      );
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
        child: Column(
          children: [
            _buildAppBarUI(),
            const Divider(endIndent: 0, indent: 0),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildSubSpacesUIWithDrag()),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarUI() {
    return Row(
      children: [
        Text(
          L10n.of(context).organized,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Spacer(),
        IconButton(
          icon: Icon(PhosphorIcons.x()),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final buttonStyle = OutlinedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.8),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton(
              style: buttonStyle,
              onPressed: () => showAddEditCategoryBottomSheet(
                context: context,
                onSave: (title, color, icon) {
                  setState(() {
                    categoryList.insert(
                      categoryList.length - 1,
                      CategoryModelLocal(
                        title: title,
                        color: color,
                        icon: icon,
                        entries: [],
                      ),
                    );
                  });
                  setDragAndDropListData();
                },
              ),
              child: Text(L10n.of(context).createCategory),
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: OutlinedButton(
              style: buttonStyle,
              onPressed: () async {
                await saveCategories(
                  context,
                  ref,
                  widget.spaceId,
                  widget.categoriesFor,
                  categoryList,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(L10n.of(context).save),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSpacesUIWithDrag() {
    return dragAndDropList == null
        ? const SizedBox.shrink()
        : DragAndDropLists(
            children: dragAndDropList!,
            onItemReorder: _onItemReorder,
            onListReorder: _onListReorder,
          );
  }

  Future<void> _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) async {
    if (dragAndDropList == null) return;
    setState(() {
      var movedItem =
          dragAndDropList![oldListIndex].children.removeAt(oldItemIndex);
      dragAndDropList![newListIndex].children.insert(newItemIndex, movedItem);

      var movedEntryItem =
          categoryList[oldListIndex].entries.removeAt(oldItemIndex);
      categoryList[newListIndex].entries.insert(newItemIndex, movedEntryItem);
    });
  }

  Future<void> _onListReorder(
    int oldListIndex,
    int newListIndex,
  ) async {
    if (dragAndDropList == null) return;
    setState(() {
      var movedList = dragAndDropList!.removeAt(oldListIndex);
      dragAndDropList!.insert(newListIndex, movedList);

      var movedCategoryList = categoryList.removeAt(oldListIndex);
      categoryList.insert(newListIndex, movedCategoryList);
    });
  }
}
