import 'dart:async';
import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/theme/colors/colors_extension.dart';
import 'package:expense_tracker/core/theme/text/app_text_style.dart';
import 'package:expense_tracker/res.dart';

import 'CustomDropDown.dart';
import 'ScrollBarProps.dart';
import 'TextFieldProps.dart';

class SelectDialog<T> extends StatefulWidget {
  final T? selectedValue;
  final List<T>? items;
  final bool showSearchBox;
  final bool isFilteredOnline;
  final ValueChanged<T>? onChanged;
  final DropdownSearchOnFind<T>? onFind;
  final DropdownSearchPopupItemBuilder<T>? itemBuilder;

  @Deprecated('Use `searchFieldProps` instead')
  final InputDecoration? searchBoxDecoration;
  final DropdownSearchItemAsString<T>? itemAsString;
  final DropdownSearchFilterFn<T>? filterFn;
  final String? hintText;

  @Deprecated('Use `searchFieldProps` instead')
  final TextStyle? searchBoxStyle;
  final double? maxHeight;
  final double? dialogMaxWidth;
  final Widget? popupTitle;
  final bool showSelectedItem;
  final DropdownSearchCompareFn<T>? compareFn;
  final DropdownSearchPopupItemEnabled<T>? itemDisabled;

  ///custom layout for empty results
  final EmptyBuilder? emptyBuilder;

  ///custom layout for loading items
  final LoadingBuilder? loadingBuilder;

  ///custom layout for error
  final ErrorBuilder? errorBuilder;

  ///the search box will be focused if true
  @Deprecated('Use `searchFieldProps` instead')
  final bool autoFocusSearchBox;

  ///text controller to set default search word for example
  @Deprecated('Use `searchFieldProps` instead')
  final TextEditingController? searchBoxController;

  ///delay before searching
  final Duration? searchDelay;

  ///show or hide favorites items
  final bool showFavoriteItems;

  ///build favorites chips
  final FavoriteItemsBuilder<T>? favoriteItemBuilder;

  ///favorite items alignment
  final MainAxisAlignment? favoriteItemsAlignment;

  ///favorites item
  final FavoriteItems<T>? favoriteItems;

  /// object that passes all props to search field
  final TextFieldProps? searchFieldProps;

  /// scrollbar properties
  final ScrollbarProps? scrollbarProps;

  const SelectDialog({
    super.key,
    this.popupTitle,
    this.items,
    this.maxHeight,
    this.showSearchBox = false,
    this.isFilteredOnline = false,
    this.onChanged,
    this.selectedValue,
    this.onFind,
    this.itemBuilder,
    this.searchBoxDecoration,
    this.hintText,
    this.itemAsString,
    this.filterFn,
    this.showSelectedItem = false,
    this.compareFn,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.autoFocusSearchBox = false,
    this.dialogMaxWidth,
    this.itemDisabled,
    this.searchBoxController,
    this.searchDelay,
    this.favoriteItemBuilder,
    this.favoriteItems,
    this.showFavoriteItems = false,
    this.favoriteItemsAlignment = MainAxisAlignment.start,
    this.searchBoxStyle,
    this.searchFieldProps,
    this.scrollbarProps,
  });

  @override
  _SelectDialogState<T> createState() => _SelectDialogState<T>();
}

class _SelectDialogState<T> extends State<SelectDialog<T>> {
  final FocusNode focusNode = new FocusNode();
  final StreamController<List<T>> _itemsStream = StreamController<List<T>>.broadcast();
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);
  final List<T> _items = <T>[];
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(delay: widget.searchDelay);

    Future.delayed(
      Duration.zero,
      () => manageItemsByFilter(widget.searchFieldProps?.controller?.text ?? widget.searchBoxController?.text ?? '', isFistLoad: true),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.searchFieldProps?.autofocus ?? widget.autoFocusSearchBox) {
      FocusScope.of(context).requestFocus(focusNode);
    }
  }

  @override
  void dispose() {
    _itemsStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    bool isTablet = deviceSize.width > deviceSize.height;
    double maxHeight = deviceSize.height * (isTablet ? .8.h : .6.h);
    double maxWidth = deviceSize.width * (isTablet ? .7.w : .9.w);

    return Container(
      width: widget.dialogMaxWidth ?? maxWidth,
      constraints: BoxConstraints(maxHeight: widget.maxHeight ?? maxHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _searchField(),
          if (widget.showFavoriteItems == true) _favoriteItemsWidget(),
          Expanded(
            child: Stack(
              children: <Widget>[
                StreamBuilder<List<T>>(
                  stream: _itemsStream.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _errorWidget(snapshot.error);
                    } else if (!snapshot.hasData) {
                      return _loadingWidget();
                    } else if (snapshot.data!.isEmpty) {
                      if (widget.emptyBuilder != null) {
                        return widget.emptyBuilder!(
                          context,
                          widget.searchFieldProps?.controller?.text ?? widget.searchBoxController?.text,
                        );
                      } else {
                        return const Center(
                          child: Text("No data found"),
                        );
                      }
                    }
                    return Scrollbar(
                      controller: widget.scrollbarProps?.controller,
                      // isAlwaysShown: widget.scrollbarProps?.isAlwaysShown,
                      // showTrackOnHover: widget.scrollbarProps?.showTrackOnHover,
                      // hoverThickness: widget.scrollbarProps?.hoverThickness,
                      thickness: widget.scrollbarProps?.thickness,
                      radius: widget.scrollbarProps?.radius,
                      notificationPredicate: widget.scrollbarProps?.notificationPredicate,
                      interactive: widget.scrollbarProps?.interactive,
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          var item = snapshot.data![index];
                          return _itemWidget(item);
                        },
                      ),
                    );
                  },
                ),
                _loadingWidget()
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(dynamic error) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error while getting online items"),
          content: _errorWidget(error),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            )
          ],
        );
      },
    );
  }

  Widget _errorWidget(dynamic error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(
        context,
        widget.searchFieldProps?.controller?.text ?? widget.searchBoxController?.text,
        error,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          error?.toString() ?? 'Error',
        ),
      );
    }
  }

  Widget _loadingWidget() {
    return ValueListenableBuilder(
        valueListenable: _loadingNotifier,
        builder: (context, bool isLoading, wid) {
          if (isLoading) {
            if (widget.loadingBuilder != null) {
              return widget.loadingBuilder!(
                context,
                widget.searchFieldProps?.controller?.text ?? widget.searchBoxController?.text,
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }
          return Container();
        });
  }

  void _onTextChanged(String filter) async {
    manageItemsByFilter(filter);
  }

  ///Function that filter item (online and offline) base on user filter
  ///[filter] is the filter keyword
  ///[isFirstLoad] true if it's the first time we load data from online, false other wises
  void manageItemsByFilter(String filter, {bool isFistLoad = false}) async {
    _loadingNotifier.value = true;

    List<T> applyFilter(String filter) {
      return _items.where((i) {
        if (widget.filterFn != null) {
          return (widget.filterFn!(i, filter));
        } else if (i.toString().toLowerCase().contains(filter.toLowerCase()))
          return true;
        else if (widget.itemAsString != null) {
          return (widget.itemAsString!(i)).toLowerCase().contains(filter.toLowerCase());
        }
        return false;
      }).toList();
    }

    //load offline data for the first time
    if (isFistLoad && widget.items != null) _items.addAll(widget.items!);

    //manage offline items
    if (widget.onFind != null && (widget.isFilteredOnline || isFistLoad)) {
      try {
        final List<T> onlineItems = [];
        onlineItems.addAll(await widget.onFind!(filter));

        //Remove all old data
        _items.clear();
        //add offline items
        if (widget.items != null) {
          _items.addAll(widget.items!);
          //if filter online we filter only local list based on entered keyword (filter)
          if (widget.isFilteredOnline == true) {
            var filteredLocalList = applyFilter(filter);
            _items.clear();
            _items.addAll(filteredLocalList);
          }
        }
        //add new online items to list
        _items.addAll(onlineItems);

        //don't filter data , they are already filtred online and local data are already filtered
        if (widget.isFilteredOnline == true) {
          _addDataToStream(_items);
        } else {
          _addDataToStream(applyFilter(filter));
        }
      } catch (e) {
        _addErrorToStream(e);
        //if offline items count > 0 , the error will be not visible for the user
        //As solution we show it in dialog
        if (widget.items != null && widget.items!.isNotEmpty) {
          _showErrorDialog(e);
          _addDataToStream(applyFilter(filter));
        }
      }
    } else {
      _addDataToStream(applyFilter(filter));
    }

    _loadingNotifier.value = false;
  }

  void _addDataToStream(List<T> data) {
    if (_itemsStream.isClosed) return;
    _itemsStream.add(data);
  }

  void _addErrorToStream(Object error, [StackTrace? stackTrace]) {
    if (_itemsStream.isClosed) return;
    _itemsStream.addError(error, stackTrace);
  }

  Widget _itemWidget(T item) {
    if (widget.itemBuilder != null) {
      return InkWell(
        // ignore pointers in itemBuilder
        onTap: widget.itemDisabled != null && (widget.itemDisabled!(item)) == true ? null : () => _handleSelectItem(item),
        // ignore pointers in itemBuilder
        child: IgnorePointer(
          ignoring: true,
          child: widget.itemBuilder!(
            context,
            item,
            _manageSelectedItemVisibility(item),
          ),
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
            border: Border.all(width: (widget.selectedValue == item ? 1 : 1).w, color: widget.selectedValue == item ? context.colors.lightGreen : const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(10.r)),
        child: ListTile(
            leading: widget.selectedValue == item
                ? SvgPicture.asset(
                    Res.selectedIcon,
                    width: 22.w,
                    height: 22.w,
                  )
                : Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E5E5)), color: context.colors.white),
                    child: Center(
                      child: Image.asset(
                        Res.rightIcon,
                        width: 10.w,
                        height: 10.h,
                      ),
                    ),
                  ),
            title: Text(
              _selectedItemAsString(item),
              style: AppTextStyle.s14_w400(color: context.colors.black),
            ),
            selected: _manageSelectedItemVisibility(item),
            onTap: widget.itemDisabled != null && (widget.itemDisabled!(item)) == true
                ? null
                : () {
                    _handleSelectItem(item);
                  },
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w)),
      );
    }
  }

  /// selected item will be highlighted only when [widget.showSelectedItem] is true,
  /// if our object is String [widget.compareFn] is not required , other wises it's required
  bool _manageSelectedItemVisibility(T? item) {
    if (!widget.showSelectedItem) return false;

    if (item is String?) {
      return item == widget.selectedValue;
    } else {
      return widget.compareFn!(item, widget.selectedValue);
    }
  }

  Widget _searchField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: <Widget>[
      widget.popupTitle ?? const SizedBox.shrink(),
      if (widget.showSearchBox)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            style: widget.searchFieldProps?.style ?? widget.searchBoxStyle,
            controller: widget.searchFieldProps?.controller ?? widget.searchBoxController,
            focusNode: focusNode,
            onChanged: (f) => _debouncer(() {
              _onTextChanged(f);
            }),
            decoration: widget.searchFieldProps?.decoration ??
                widget.searchBoxDecoration ??
                InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
            keyboardType: widget.searchFieldProps?.keyboardType,
            textInputAction: widget.searchFieldProps?.textInputAction,
            textCapitalization: widget.searchFieldProps?.textCapitalization ?? TextCapitalization.none,
            strutStyle: widget.searchFieldProps?.strutStyle,
            textAlign: widget.searchFieldProps?.textAlign ?? TextAlign.start,
            textAlignVertical: widget.searchFieldProps?.textAlignVertical,
            textDirection: widget.searchFieldProps?.textDirection,
            readOnly: widget.searchFieldProps?.readOnly ?? false,
            toolbarOptions: widget.searchFieldProps?.toolbarOptions,
            showCursor: widget.searchFieldProps?.showCursor,
            obscuringCharacter: widget.searchFieldProps?.obscuringCharacter ?? '•',
            obscureText: widget.searchFieldProps?.obscureText ?? false,
            autocorrect: widget.searchFieldProps?.autocorrect ?? true,
            smartDashesType: widget.searchFieldProps?.smartDashesType,
            smartQuotesType: widget.searchFieldProps?.smartQuotesType,
            enableSuggestions: widget.searchFieldProps?.enableSuggestions ?? true,
            maxLines: widget.searchFieldProps?.maxLines ?? 1,
            minLines: widget.searchFieldProps?.minLines,
            expands: widget.searchFieldProps?.expands ?? false,
            maxLengthEnforcement: widget.searchFieldProps?.maxLengthEnforcement,
            maxLength: widget.searchFieldProps?.maxLength,
            onAppPrivateCommand: widget.searchFieldProps?.onAppPrivateCommand,
            inputFormatters: widget.searchFieldProps?.inputFormatters,
            enabled: widget.searchFieldProps?.enabled,
            cursorWidth: widget.searchFieldProps?.cursorWidth ?? 2.0,
            cursorHeight: widget.searchFieldProps?.cursorHeight,
            cursorRadius: widget.searchFieldProps?.cursorRadius,
            cursorColor: widget.searchFieldProps?.cursorColor,
            selectionHeightStyle: widget.searchFieldProps?.selectionHeightStyle ?? ui.BoxHeightStyle.tight,
            selectionWidthStyle: widget.searchFieldProps?.selectionWidthStyle ?? ui.BoxWidthStyle.tight,
            keyboardAppearance: widget.searchFieldProps?.keyboardAppearance,
            scrollPadding: widget.searchFieldProps?.scrollPadding ?? const EdgeInsets.all(20.0),
            dragStartBehavior: widget.searchFieldProps?.dragStartBehavior ?? DragStartBehavior.start,
            enableInteractiveSelection: widget.searchFieldProps?.enableInteractiveSelection ?? true,
            selectionControls: widget.searchFieldProps?.selectionControls,
            onTap: widget.searchFieldProps?.onTap,
            mouseCursor: widget.searchFieldProps?.mouseCursor,
            buildCounter: widget.searchFieldProps?.buildCounter,
            scrollController: widget.searchFieldProps?.scrollController,
            scrollPhysics: widget.searchFieldProps?.scrollPhysics,
            autofillHints: widget.searchFieldProps?.autofillHints,
            restorationId: widget.searchFieldProps?.restorationId,
          ),
        )
    ]);
  }

  Widget _favoriteItemsWidget() {
    return StreamBuilder<List<T>>(
        stream: _itemsStream.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildFavoriteItems(widget.favoriteItems!(snapshot.data!));
          } else {
            return Container();
          }
        });
  }

  Widget _buildFavoriteItems(List<T>? favoriteItems) {
    if (favoriteItems != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: widget.favoriteItemsAlignment ?? MainAxisAlignment.start,
                  children: favoriteItems
                      .map(
                        (f) => InkWell(
                          onTap: () => _handleSelectItem(f),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: widget.favoriteItemBuilder != null ? widget.favoriteItemBuilder!(context, f) : _favoriteItemDefaultWidget(f),
                          ),
                        ),
                      )
                      .toList()),
            ),
          );
        }),
      );
    } else {
      return Container();
    }
  }

  void _handleSelectItem(T selectedItem) {
    Navigator.pop(context, selectedItem);
    if (widget.onChanged != null) widget.onChanged!(selectedItem);
  }

  Widget _favoriteItemDefaultWidget(T? item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Theme.of(context).primaryColorLight),
      child: Text(
        _selectedItemAsString(item),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  ///function that return the String value of an object
  String _selectedItemAsString(T? data) {
    if (data == null) {
      return "";
    } else if (widget.itemAsString != null) {
      return widget.itemAsString!(data);
    } else {
      return data.toString();
    }
  }
}

class Debouncer {
  final Duration? delay;
  Timer? _timer;

  Debouncer({this.delay});

  void call(Function action) {
    _timer?.cancel();
    _timer = Timer(delay ?? const Duration(milliseconds: 500), action as void Function());
  }
}
