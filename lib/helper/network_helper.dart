import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:scan_app/models/enums/request_type.dart';

class NetworkHelper {
  /// Method used to do all native commands (e.g mostly network requests in this case)
  static Future<dynamic> _sendNativeCommandRequest(MethodChannel methodChannel,
      BuildContext callingContext, RequestType requestType,
      [dynamic arguments]) async {
    try {
      var result = await methodChannel.invokeMethod(
          requestType.toString().split('.').last, arguments);
      return result;
    } on Exception catch (e) {
      log("Exception while executing request $requestType: $e");
      return null;
    }
  }

  /// return list of folders
  static Future<List<String>> listFolders(
      MethodChannel methodChannel, BuildContext callingContext) async {
    List<dynamic> requestResult = await _sendNativeCommandRequest(
        methodChannel, callingContext, RequestType.listFoldersRequest);
    var result = requestResult.cast<String>();
    return result;
  }

  /// return files in folder
  static Future<List<String>> listFiles(MethodChannel methodChannel,
      BuildContext callingContext, String folderName) async {
    List<dynamic> rawResult = await _sendNativeCommandRequest(
        methodChannel,
        callingContext,
        RequestType.listFilesRequest,
        {"FolderName": folderName});
    var result = rawResult.cast<String>();
    return result;
  }

  /// scan
  static Future<bool> scan(
      MethodChannel methodChannel,
      BuildContext callingContext,
      int scanQuality,
      String folderName,
      String fileName) async {
    bool result = await _sendNativeCommandRequest(
        methodChannel, callingContext, RequestType.scanRequest, {
      "FolderName": folderName,
      "FileName": fileName,
      "ScanQuality": scanQuality
    });
    return result;
  }

  /// load single file
  static Future<List<int>> getFileBytes(MethodChannel methodChannel,
      BuildContext callingContext, String folderName, String fileName) async {
    List<int> rawResult = await _sendNativeCommandRequest(
        methodChannel,
        callingContext,
        RequestType.getRequest,
        {"FolderName": folderName, "FileName": fileName});
    return rawResult;
  }

  /// delete single file
  static Future<bool> deleteFile(MethodChannel methodChannel,
      BuildContext callingContext, String folderName, String fileName) async {
    var fileNames = <String>[];
    fileNames.add(fileName);
    return await deleteFiles(
        methodChannel, callingContext, folderName, fileNames);
  }

  /// delete files
  static Future<bool> deleteFiles(
      MethodChannel methodChannel,
      BuildContext callingContext,
      String folderName,
      List<String> fileNames) async {
    bool deleteResult = await _sendNativeCommandRequest(
        methodChannel,
        callingContext,
        RequestType.deleteRequest,
        {"FolderName": folderName, "FileNames": fileNames});
    return deleteResult;
  }

  // merge files
  static Future<bool> mergeFiles(
      MethodChannel methodChannel,
      BuildContext callingContext,
      String folderName,
      String resultFileName,
      List<String> filesToMerge) async {
    bool result = await _sendNativeCommandRequest(
        methodChannel, callingContext, RequestType.mergeRequest, {
      "FolderName": folderName,
      "FileName": resultFileName,
      "FileNames": filesToMerge
    });
    return result;
  }

  // check for update
  static Future<bool> checkUpdate(MethodChannel methodChannel,
      BuildContext callingContext, String version) async {
    bool result = await _sendNativeCommandRequest(methodChannel, callingContext,
        RequestType.checkUpdateRequest, {"Version": version});
    return result;
  }

  // load update file
  static Future<List<int>> loadUpdate(MethodChannel methodChannel,
      BuildContext callingContext, String version) async {
    List<int> result = await _sendNativeCommandRequest(methodChannel,
        callingContext, RequestType.updateRequest, {"Version": version});
    return result;
  }
}
