package com.android.settings;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.SystemClock;
import android.util.Log;
import android.os.SystemProperties; 

public class BootReceiver extends BroadcastReceiver{

  @Override
  public void onReceive(Context arg0, Intent arg1) {

      String action = arg1.getAction();
      if(action.equals(Intent.ACTION_BOOT_COMPLETED)){ 
        
      }else if("android.fireflyapi.action.run_power_off".equals(action)){
        fireShutDown(arg0);
      }else if("android.fireflyapi.action.run_power_reboot".equals(action)){
      	fireReboot(arg0); 
      }
  }


  private void fireShutDown(Context context) {
    String action = "com.android.internal.intent.action.REQUEST_SHUTDOWN";
    
    Intent intent = new Intent(action);
    intent.putExtra("android.intent.extra.KEY_CONFIRM", false);
    intent.setFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    context.startActivity(intent);
  }

  private void fireReboot(Context context){
    Intent intent=new Intent(Intent.ACTION_REBOOT);
    intent.putExtra("nowait", 1);
    intent.putExtra("interval", 1);
    intent.putExtra("window", 0);
    context.sendBroadcast(intent);
  }
}