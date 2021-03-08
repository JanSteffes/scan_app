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

import data.Config;
import data.packages.implementations.PackageData.*;
import data.packages.interfaces.*;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "flutter.native/scanHelper";
  private static final IStreamListener _streamListener = null;

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
                            case "listFoldersRequest":
                                runnable = listFoldersRequestRunnable(result);
                                break;
                            case "listFilesRequest":
                                runnable = listFilesRequestRunnable(call, result);
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
                            case "checkUpdateRequest":
                                runnable = checkUpdateRequestRunnable(call, result);
                                break;
                            case "updateRequest":
                                runnable = updateRequestRunnable(call, result);
                                break;
                            case "switchEndpointRequest":
                                runnable = switchEndpointRunnable(call, result);
                                break;
                            case "switchEnvironmentRequest":
                                runnable = switchEnvironmentRunnable(call, result);
                                break;
                            default:
                                System.out.println("No implementation for " + call.method);
                                result.notImplemented();
                                return;
                        }
                        new Thread(runnable).start();
                    }
            );
  }

  private Runnable switchEnvironmentRunnable(MethodCall call, MethodChannel.Result result) {
     Runnable r = () -> {
        Config.switchDebug();
        boolean debug = Config.getDebug();
        runOnUiThread(() -> result.success(debug));
    };
    return r;
  }

  private Runnable switchEndpointRunnable(MethodCall call, MethodChannel.Result result) {
    Runnable r = () -> {
        Config.switchServer();
        String newEndpoint = Config.getServer();
        runOnUiThread(() -> result.success(newEndpoint));
    };
    return r;
  }

  private Runnable checkUpdateRequestRunnable(MethodCall call, MethodChannel.Result result) {
    Runnable r = () -> {
      String version = getVersion(call);
      try
      {
        boolean updateCheckResult = new PackageDataUpdateCheck(version).execute(_streamListener);        
        runOnUiThread(() -> result.success(updateCheckResult));
      }
      catch(Exception e)
      {
        runOnUiThread(() -> result.error("checkUpdateRequestRunnable", null, null));
      }
    };
    return r;
  }

  private Runnable updateRequestRunnable(MethodCall call, MethodChannel.Result result) {
    Runnable r = () -> {
      String version = getVersion(call);
      try
      {
        byte[] fileResult = new PackageDataUpdate(version).execute(_streamListener);
        runOnUiThread(() -> result.success(fileResult));
      }
      catch(Exception e)
      {
        System.out.println("UpdateRequestResult Error!");
        runOnUiThread(() -> result.error("updateRequestRunnable", null, null));
      }
    };
    return r;
  }


  private Runnable getRequestRunnable(MethodCall call, MethodChannel.Result result){
    Runnable r = () -> {
        String folderName = getFolderName(call);
        String fileName = getFileName(call);
      try
      {
        byte[] fileResult = new PackageDataGetFile(folderName, fileName).execute(_streamListener);
        runOnUiThread(() -> result.success(fileResult));
      }
      catch(Exception e)
      {
        runOnUiThread(() -> result.error("getRequestRunnable", null, null));
      }
    };
    return r;
  }

    private Runnable mergeRequestRunnable(MethodCall call, MethodChannel.Result result)
    {
      Runnable r = () -> {
        String folderName = getFolderName(call);
        String resultFileName = getFileName(call);
        ArrayList<String> mergeFileNames = getFileNames(call);
        try
        {
          boolean mergeResult = new PackageDataMerge(folderName, resultFileName, mergeFileNames).execute(_streamListener);
            runOnUiThread(() -> result.success(mergeResult));
        }
        catch(Exception e)
        {
          runOnUiThread(() -> result.error("mergeRequestRunnable", null, null));
        }
      };
      return r;
    }

    private Runnable deleteRequestRunnable(MethodCall call, MethodChannel.Result result)
    {
      Runnable r = () -> {
        String folderName = getFolderName(call);
        ArrayList<String> deleteFileNames = getFileNames(call);
        try
        {
          boolean mergeResult = new PackageDataDelete(folderName, deleteFileNames).execute(_streamListener);
          runOnUiThread(() -> result.success(mergeResult));      
        }
        catch(Exception e)
        {
          runOnUiThread(() -> result.error("deleteRequestRunnable", null, null));
        }
      };
    return r;
    }

    private Runnable listFoldersRequestRunnable(MethodChannel.Result result) {
      Runnable r = () -> {
        try
        {
          String[] listResult = new PackageDataListFolders().execute(_streamListener);
          ProcessListResult(result, listResult);          
        }
        catch(Exception e)
        {
          runOnUiThread(() -> result.error("listRequestRunnable", null, null));
        }
      };
      return r;
    }

     private Runnable listFilesRequestRunnable(MethodCall call, MethodChannel.Result result) {
      Runnable r = () -> {
        try
        {
          String folderName = getFolderName(call);
          String[] listResult = new PackageDataListFiles(folderName).execute(_streamListener);
          ProcessListResult(result, listResult);
        }
        catch(Exception e)
        {
          runOnUiThread(() -> result.error("listRequestRunnable", null, null));
        }
      };
      return r;
    }    

    private Runnable scanRequestRunnable(MethodCall call, MethodChannel.Result result) {
        Runnable r = () -> {
            String folderName = getFolderName(call);
            String fileName = getFileName(call);
            int scanQuality = call.argument("ScanQuality");
            try
            {
              PackageDataScan packageData = new PackageDataScan(folderName, scanQuality, fileName);
              boolean scanResult = packageData.execute(_streamListener);
              runOnUiThread(() -> result.success(scanResult));
            }
            catch(Exception e)
            {
              runOnUiThread(() -> result.error("scanRequestRunnable", null, null));
            }
        };

        return r;
    }

    
    /**
    * Process result of list request
    */
    private void ProcessListResult(MethodChannel.Result result, String[] listResult)
    {
        if (listResult == null)
        {
            listResult = new String[0];
        }
        List<String> resultValue = new ArrayList<>(Arrays.asList(listResult));
        runOnUiThread(() -> result.success(resultValue)); 
    }    

    

  private String getFolderName(MethodCall call)
  {
    return call.argument("FolderName");
  }

  private String getFileName(MethodCall call)
  {
    return call.argument("FileName");
  }

  private ArrayList<String> getFileNames(MethodCall call)
  {
    return call.argument("FileNames");
  }

  private String getVersion(MethodCall call)
  {
    return call.argument("Version");
  }
}