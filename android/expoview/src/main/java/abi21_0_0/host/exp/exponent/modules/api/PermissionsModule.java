// Copyright 2015-present 650 Industries. All rights reserved.

package abi21_0_0.host.exp.exponent.modules.api;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.support.v4.content.ContextCompat;

import org.json.JSONObject;

import abi21_0_0.com.facebook.react.bridge.Arguments;
import abi21_0_0.com.facebook.react.bridge.Promise;
import abi21_0_0.com.facebook.react.bridge.ReactApplicationContext;
import abi21_0_0.com.facebook.react.bridge.ReactContextBaseJavaModule;
import abi21_0_0.com.facebook.react.bridge.ReactMethod;
import abi21_0_0.com.facebook.react.bridge.WritableMap;

import abi21_0_0.host.exp.exponent.modules.ExpoKernelServiceConsumerBaseModule;
import host.exp.exponent.ExponentManifest;
import host.exp.exponent.kernel.ExperienceId;
import host.exp.exponent.kernel.services.PermissionsKernelService;
import host.exp.expoview.Exponent;

public class PermissionsModule  extends ExpoKernelServiceConsumerBaseModule {
  private static String PERMISSION_EXPIRES_NEVER = "never";

  private JSONObject mManifest;
  private PermissionsKernelService mPermissionsKernelService;

  public PermissionsModule(ReactApplicationContext reactContext, ExperienceId experienceId, JSONObject manifest) {
    super(reactContext, experienceId);
    mPermissionsKernelService = mKernelServiceRegistry.getPermissionsKernelService();
    mManifest = manifest;
  }

  @Override
  public String getName() {
        return "ExponentPermissions";
    }

  @ReactMethod
  public void getAsync(final String type, final Promise promise) {
    WritableMap result = getPermissions(type);
    if (result != null) {
      promise.resolve(result);
    } else {
      promise.reject("E_PERMISSION_UNKNOWN", String.format("Unrecognized permission %s", type));
    }
  }

  @ReactMethod
  public void askAsync(final String type, final Promise promise) {
    WritableMap existingPermissions = getPermissions(type);
    if (existingPermissions != null &&
        existingPermissions.getString("status") != null &&
        existingPermissions.getString("status").equals("granted")) {
      // if we already have permission granted, resolve immediately with that
      promise.resolve(existingPermissions);
    } else {
      switch (type) {
        case "remoteNotifications": {
          // nothing to ask for, always granted
          promise.resolve(getAlwaysGrantedPermissions());
          break;
        }
        case "location": {
          askForLocationPermissions(promise);
          break;
        }
        case "camera": {
          askForSimplePermission(Manifest.permission.CAMERA, promise);
          break;
        }
        case "contacts": {
          askForSimplePermission(Manifest.permission.READ_CONTACTS, promise);
          break;
        }
        case "audioRecording": {
          askForSimplePermission(Manifest.permission.RECORD_AUDIO, promise);
          break;
        }
        case "systemBrightness": {
          askForWriteSettingsPermission(promise);
          break;
        }
        default:
          promise.reject("E_PERMISSION_UNSUPPORTED", String.format("Cannot request permission: %s", type));
      }
    }
  }

  private WritableMap getPermissions(final String type) {
    switch (type) {
      case "remoteNotifications": {
        // these permissions are always the same
        return getAlwaysGrantedPermissions();
      }
      case "location": {
        return getLocationPermissions();
      }
      case "camera": {
        return getSimplePermission(android.Manifest.permission.CAMERA);
      }
      case "contacts": {
        return getSimplePermission(Manifest.permission.READ_CONTACTS);
      }
      case "audioRecording": {
        return getSimplePermission(Manifest.permission.RECORD_AUDIO);
      }
      case "systemBrightness": {
        return getWriteSettingsPermission();
      }
      default:
        return null;
    }
  }

  private WritableMap getAlwaysGrantedPermissions() {
    WritableMap response = Arguments.createMap();
    response.putString("status", "granted");
    response.putString("expires", PERMISSION_EXPIRES_NEVER);
    return response;
  }

  private WritableMap getLocationPermissions() {
    WritableMap response = Arguments.createMap();
    Boolean isGranted = false;
    String scope = "none";

    int globalFinePermission = PackageManager.PERMISSION_GRANTED;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      globalFinePermission = ContextCompat.checkSelfPermission(getReactApplicationContext(),
          Manifest.permission.ACCESS_FINE_LOCATION);
    }
    boolean experienceFinePermission = mPermissionsKernelService
        .hasGrantedPermissions(Manifest.permission.ACCESS_FINE_LOCATION, this.experienceId);
    if (globalFinePermission == PackageManager.PERMISSION_GRANTED && experienceFinePermission) {
      response.putString("status", "granted");
      scope = "fine";
      isGranted = true;
    } else {
      int globalCoarsePermission = PackageManager.PERMISSION_GRANTED;
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        globalCoarsePermission = ContextCompat.checkSelfPermission(getReactApplicationContext(),
            Manifest.permission.ACCESS_COARSE_LOCATION);
      }
      boolean experienceCoarsePermission = mPermissionsKernelService
          .hasGrantedPermissions(Manifest.permission.ACCESS_COARSE_LOCATION, this.experienceId);
      if (globalCoarsePermission == PackageManager.PERMISSION_GRANTED  && experienceCoarsePermission) {
        response.putString("status", "granted");
        scope = "coarse";
        isGranted = true;
      }
    }

    if (!isGranted) {
      response.putString("status", "denied");
    }
    response.putString("expires", PERMISSION_EXPIRES_NEVER);
    WritableMap platformMap = Arguments.createMap();
    platformMap.putString("scope", scope);
    response.putMap("android", platformMap);

    return response;
  }

  // checkSelfPermission does not return accurate status of WRITE_SETTINGS
  private WritableMap getWriteSettingsPermission() {
    WritableMap response = Arguments.createMap();

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      if (Settings.System.canWrite(getReactApplicationContext())) {
        response.putString("status", "granted");
      } else {
        response.putString("status", "denied");
      }
    } else {
      response.putString("status", "granted");
    }
    response.putString("expires", PERMISSION_EXPIRES_NEVER);

    return response;
  }

  private void askForWriteSettingsPermission(final Promise promise) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      if (!Settings.System.canWrite(getReactApplicationContext())) {
        try {
          // Launch systems dialog for write settings
          Intent intent = new Intent(android.provider.Settings.ACTION_MANAGE_WRITE_SETTINGS);
          intent.setData(Uri.parse("package:" + getReactApplicationContext().getPackageName()));
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
          getReactApplicationContext().startActivity(intent);

          // Action returns nothing so we return unknown status
          // https://stackoverflow.com/questions/44389632/proper-way-to-handle-action-manage-write-settings-activity
          com.facebook.react.bridge.WritableMap response = com.facebook.react.bridge.Arguments.createMap();
          response.putString("status", "unknown");
          promise.resolve(response);
        } catch (Exception e) {
          promise.reject("Error launching write settings activity:", e.getMessage());
        }
      } else {
        Exponent.getInstance().requestExperiencePermissions(new Exponent.PermissionsListener() {
          @Override
          public void permissionsGranted() {
            promise.resolve(getWriteSettingsPermission());
          }

          @Override
          public void permissionsDenied() {
            promise.resolve(getWriteSettingsPermission());
          }
        }, new String[] { android.provider.Settings.ACTION_MANAGE_WRITE_SETTINGS }, this.experienceId,
            mManifest.optString(ExponentManifest.MANIFEST_NAME_KEY));
      }
    }
  }

  private WritableMap getSimplePermission(String permission) {
    WritableMap response = Arguments.createMap();

    int globalResult = PackageManager.PERMISSION_GRANTED;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      globalResult = ContextCompat.checkSelfPermission(getReactApplicationContext(), permission);
    }
    if (globalResult == PackageManager.PERMISSION_GRANTED &&
        mPermissionsKernelService.hasGrantedPermissions(permission, this.experienceId)) {
      response.putString("status", "granted");
    } else {
      response.putString("status", "denied");
    }
    response.putString("expires", PERMISSION_EXPIRES_NEVER);

    return response;
  }

  private void askForSimplePermission(final String permission, final Promise promise) {
    boolean gotPermissions = Exponent.getInstance().requestPermissions(new Exponent.PermissionsListener() {
      @Override
      public void permissionsGranted() {
        promise.resolve(getSimplePermission(permission));
      }

      @Override
      public void permissionsDenied() {
        promise.resolve(getSimplePermission(permission));
      }
    }, new String[] { permission }, this.experienceId, mManifest.optString(ExponentManifest.MANIFEST_NAME_KEY));

    if (!gotPermissions) {
      promise.reject("E_ACTIVITY_DOES_NOT_EXIST", "No visible activity. Must request " +
          permission + " when visible.");
    }
  }

  private void askForLocationPermissions(final Promise promise) {
    final String[] permissions = new String[]{
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION
    };
    boolean gotPermissions = Exponent.getInstance().requestPermissions(new Exponent.PermissionsListener() {
      @Override
      public void permissionsGranted() {
        promise.resolve(getLocationPermissions());
      }

      @Override
      public void permissionsDenied() {
        promise.resolve(getLocationPermissions());
      }
    }, permissions, this.experienceId, mManifest.optString(ExponentManifest.MANIFEST_NAME_KEY));

    if (!gotPermissions) {
      promise.reject("E_ACTIVITY_DOES_NOT_EXIST", "No visible activity. Must request location when visible.");
    }
  }
}
