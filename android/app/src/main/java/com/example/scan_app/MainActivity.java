package com.example.scan_app;

import android.os.StrictMode;

import java.util.ArrayList;

import androidx.annotation.NonNull;
import data.packages.implementations.PackageDataDelete;
import data.packages.implementations.PackageDataList;
import data.packages.implementations.PackageDataMerge;
import data.packages.implementations.PackageDataScan;
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
                            default:
                                result.notImplemented();
                                return;
                        }
                        new Thread(runnable).start();
                    }
            );
  }

  private Runnable mergeRequestRunnable(MethodCall call, MethodChannel.Result result)
  {
      Runnable r = () -> {
      String resultFileName = call.argument("FileName");
      ArrayList<String> mergeFileNames = call.argument("FileNames");
      String mergeResult = new PackageDataMerge(resultFileName, mergeFileNames).Execute();
      System.out.println("MergeResult: " + mergeResult);
        runOnUiThread(() -> result.success(mergeResult));
      };
      return r;
  }

  private Runnable deleteRequestRunnable(MethodCall call, MethodChannel.Result result)
  {
    Runnable r = () -> {
        ArrayList<String> deleteFileNames = call.argument("FileNames");
        String mergeResult = new PackageDataDelete(deleteFileNames).Execute();
        System.out.println("DeleteResult: " + mergeResult);
          runOnUiThread(() -> result.success(mergeResult));
        };
    return r;
  }

  private Runnable listRequestRunnable(MethodChannel.Result result) {
      Runnable r = () -> {
          String resultString = new PackageDataList().Execute();
      String resultList = resultString == null ? "" : resultString;
          runOnUiThread(() -> result.success(resultList));
      };
      return r;
  }

    private Runnable scanRequestRunnable(MethodCall call, MethodChannel.Result result) {
        Runnable r = () -> {
            String fileName = call.argument("FileName");
            int scanQuality = call.argument("ScanQuality");
            PackageDataScan packageData = new PackageDataScan(scanQuality, fileName);
            String scanResult = packageData.Execute();
            System.out.println("ScanResult: " + scanResult);
            runOnUiThread(() -> result.success(scanResult));
        };

        return r;
    }
}