import 'package:flutter/material.dart';
import 'package:scan_app/models/listmodels/slideable/slideable_side.dart';

enum SlideableAction { see, share, delete, selectForMerge }

extension SlideableActionExtension on SlideableAction {
  static const slideSideData = {
    SlideableAction.selectForMerge: SlideSide.right,
    SlideableAction.see: SlideSide.right,
    SlideableAction.share: SlideSide.right,
    SlideableAction.delete: SlideSide.left
  };

  SlideSide get side => slideSideData[this];

  static const needsCallbackFunctionData = {
    SlideableAction.selectForMerge: false,
    SlideableAction.see: true,
    SlideableAction.share: true,
    SlideableAction.delete: true
  };

  bool get needsCallbackFunction => needsCallbackFunctionData[this];

  static const iconData = {
    SlideableAction.selectForMerge: Icons.add,
    SlideableAction.see: Icons.remove_red_eye,
    SlideableAction.share: Icons.share,
    SlideableAction.delete: Icons.delete
  };

  IconData get icon => iconData[this];

  static const captionData = {
    SlideableAction.selectForMerge: "Hinzufügen",
    SlideableAction.see: "Anzeigen",
    SlideableAction.share: "Teilen",
    SlideableAction.delete: "Löschen"
  };

  String get caption => captionData[this];

  static const iconColorData = {
    SlideableAction.selectForMerge: Colors.black,
    SlideableAction.see: Colors.black,
    SlideableAction.share: Colors.black,
    SlideableAction.delete: Colors.black
  };

  Color get iconColor => iconColorData[this];

  static const tileColorData = {
    SlideableAction.selectForMerge: Colors.green,
    SlideableAction.see: Colors.orange,
    SlideableAction.share: Colors.blue,
    SlideableAction.delete: Colors.red
  };

  Color get tileColor => tileColorData[this];
}
