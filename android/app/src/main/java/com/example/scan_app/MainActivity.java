package com.example.scan_app;

import android.os.StrictMode;
import android.text.TextUtils;
import android.content.Intent;

import java.io.File;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Stream;

import android.net.Uri;

import androidx.annotation.NonNull;
import data.packages.implementations.*;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "flutter.native/scanHelper";

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
      super.configureFlutterEngine(flutterEngine);

      StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
      StrictMode.setThreadPolicy(policy);

    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                    (call, result) -> {
                        Runnable runnable;
                        switch(call.method)
                        {
                            case "scanRequest":
                                runnable = scanRequestRunnable(call, result);
                                break;
                            case "listRequest":
                                runnable = listRequestRunnable(result);
                                break;
                            case "mergeRequest":
                                runnable = mergeRequestRunnable(call, result);
                                break;
                            case "deleteRequest":
                                runnable = deleteRequestRunnable(call, result);
                                break;
                            case "getRequest":
                                runnable = getRequestRunnable(call, result);
                                break;
                            // case "shareMailRequest":
                            //     runnable = shareMailRunnable(call, result);
                            //     break;
                            default:
                                result.notImplemented();
                                return;
                        }
                        new Thread(runnable).start();
                    }
            );
  }

  // private Runnable shareMailRunnable(MethodCall call, MethodChannel.Result result) {
  //    Runnable r = () -> {
  //      try
  //      {
  //         ArrayList<String> filePaths = call.argument("FilePaths");
  //         ArrayList<Uri> files = new ArrayList<Uri>();
  //         for(String path : filePaths)
  //         {
  //            File file = new File(path);
  //            Uri uri = Uri.fromFile(file);
  //            files.add(uri);
  //         }
  //         String shareMessage = call.argument("ShareMessage");
  //         Intent intent = new Intent(Intent.ACTION_SEND_MULTIPLE);
  //         intent.setType("message/rfc822");
  //         intent.putExtra(Intent.EXTRA_EMAIL, new String[0]);
  //         intent.putExtra(Intent.EXTRA_SUBJECT, "");
  //         intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, files);
  //         startActivity(Intent.createChooser(intent, shareMessage));
  //         runOnUiThread(() -> result.success(true));
  //      }
  //      catch(Exception e)
  //      {
  //         e.printStackTrace();
  //         System.out.println("failed to make intent: " + e.getMessage());
  //         runOnUiThread(() -> result.success(false));
  //      }
  //   };
  //   return r;
  // }

  private Runnable getRequestRunnable(MethodCall call, MethodChannel.Result result){
    Runnable r = () -> {
      String fileName = call.argument("FileName");
      byte[] fileResult = new PackageDataGetFile(fileName).Execute();
      System.out.println("GetResult: " + fileResult.length + " bytes");
      runOnUiThread(() -> result.success(fileResult));
    };
    return r;
  }

    private Runnable mergeRequestRunnable(MethodCall call, MethodChannel.Result result)
    {
      Runnable r = () -> {
      String resultFileName = call.argument("FileName");
      ArrayList<String> mergeFileNames = call.argument("FileNames");
      System.out.println("Files to merge: " + String.join(", ", mergeFileNames));
      boolean mergeResult = new PackageDataMerge(resultFileName, mergeFileNames).Execute();
      System.out.println("MergeResult: " + mergeResult);
        runOnUiThread(() -> result.success(mergeResult));
      };
      return r;
    }

    private Runnable deleteRequestRunnable(MethodCall call, MethodChannel.Result result)
    {
    Runnable r = () -> {
        ArrayList<String> deleteFileNames = call.argument("FileNames");
        boolean mergeResult = new PackageDataDelete(deleteFileNames).Execute();
        System.out.println("DeleteResult: " + mergeResult);
          runOnUiThread(() -> result.success(mergeResult));
        };
    return r;
    }

    private Runnable listRequestRunnable(MethodChannel.Result result) {
      Runnable r = () -> {
          String[] listResult = new PackageDataList().Execute();
          System.out.println("ListResult: " + TextUtils.join(", ", listResult));
          List<String> resultValue = new ArrayList<>(Arrays.asList(listResult));
          runOnUiThread(() -> result.success(resultValue));
      };
      return r;
    }

    private Runnable scanRequestRunnable(MethodCall call, MethodChannel.Result result) {
        Runnable r = () -> {
            String fileName = call.argument("FileName");
            int scanQuality = call.argument("ScanQuality");
            PackageDataScan packageData = new PackageDataScan(scanQuality, fileName);
            boolean scanResult = packageData.Execute();
            System.out.println("ScanResult: " + scanResult);
            runOnUiThread(() -> result.success(scanResult));
        };

        return r;
    }
}