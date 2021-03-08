import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_action.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_side.dart';

class SlidableWidget<T> extends StatelessWidget {
  final Function(BuildContext context, dynamic args) childBuildFunction;
  final int index;
  final Function(SlideableAction action, int index) handleSlideActionTap;
  final String infoText;
  final SlidableController slidableController;
  final dynamic childBuildFunctionArgs;

  const SlidableWidget({
    @required this.childBuildFunction,
    @required this.childBuildFunctionArgs,
    @required this.index,
    @required this.handleSlideActionTap,
    this.infoText,
    this.slidableController,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var leftChilds = SlideableAction.values
        .where((element) => element.side == SlideSide.left)
        .map((slideableAction) =>
            getIconSlideActionFromSlideableAction(slideableAction, index))
        .toList();
    var rightChilds = SlideableAction.values
        .where((element) => element.side == SlideSide.right)
        .map((slideableAction) =>
            getIconSlideActionFromSlideableAction(slideableAction, index))
        .toList();
    return Slidable(
        controller: slidableController,
        actionPane: SlidableDrawerActionPane(),
        closeOnScroll: false,
        child: Builder(builder: (BuildContext slideableBuildContext) {
          return childBuildFunction.call(
              slideableBuildContext, childBuildFunctionArgs);
        }),

        /// left side
        actions: leftChilds,

        /// right side
        secondaryActions: rightChilds);
  }

  IconSlideAction getIconSlideActionFromSlideableAction(
      SlideableAction slideableAction, int index) {
    return IconSlideAction(
        caption: slideableAction.caption,
        color: slideableAction.tileColor,
        foregroundColor: slideableAction.iconColor,
        icon: slideableAction.icon,
        onTap: () => handleSlideActionTap(slideableAction, index));
  }
}
