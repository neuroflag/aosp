/*
 * Copyright (C) 2017 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package com.android.settings.display;

import android.content.Context;

import android.os.RemoteException;
import android.os.ServiceManager;
import android.os.UserHandle;
import androidx.preference.ListPreference;
import androidx.preference.Preference;
import android.text.TextUtils;

import com.android.settings.R;
import com.android.settings.core.PreferenceControllerMixin;
import com.android.settingslib.core.AbstractPreferenceController;

import java.util.ArrayList;
import java.util.List;

import android.view.IWindowManager;
import android.view.WindowManagerGlobal;
import android.content.Intent;
import android.view.Surface;
import android.util.Log;


import android.provider.Settings;


public class RotationPreferenceController extends AbstractPreferenceController implements
        PreferenceControllerMixin, Preference.OnPreferenceChangeListener {

    private static final String TAG = "screen_orientation";
    private static final String KEY_ROTATION = "screen_orientation";

    public RotationPreferenceController(Context context) {
        super(context);
    }


    @Override
    public String getPreferenceKey() {
        return KEY_ROTATION;
    }

    // @Override
    // public boolean handlePreferenceTreeClick(Preference preference) {

    //     return false;
    // }

    @Override
    public void updateState(Preference preference) {
        ListPreference pref = (ListPreference) preference;
        updateScreenOrientation(pref);
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        if (KEY_ROTATION.equals(preference.getKey())) {
            int value = Integer.parseInt((String) newValue);
            try {
                Log.w(TAG, "freezeRotation :"+value);
                IWindowManager wm = WindowManagerGlobal.getWindowManagerService();
                if(value == ROTATION_FREE)
                {
                    wm.thawRotation();
                }else{
                    wm.freezeRotation(value);
                }
                setScreenOrientationSummary((ListPreference) preference,value);
            } catch (Exception exc) {
                Log.w(TAG, "Unable to Rotation");
            }
        }
        return true;
    }



    @Override
    public boolean isAvailable() {
        return Settings.System.getInt(mContext.getContentResolver(),Settings.System.ENABLE_ROTATION_BY_USER,1) != 0;
    }

    private static final int ROTATION_FREE = -1;
    private void updateScreenOrientation(ListPreference pref){
       int rotation = 1;
        try {
                IWindowManager wm = WindowManagerGlobal.getWindowManagerService();

                if(wm.isRotationFrozen())
                     rotation = wm.getDefaultDisplayRotation();
                else 
                     rotation = ROTATION_FREE;
        } catch (Exception exc) {
        }
        if(pref != null) {
            pref.setValue(String.valueOf(rotation));
            setScreenOrientationSummary(pref,rotation);
        }       
    }

    private void setScreenOrientationSummary(ListPreference pref,int value)
    { 
        String[] set_screen_orientation_entries = mContext.getResources().getStringArray(R.array.set_screen_orientation_entries);
        switch(value)
        {
            case ROTATION_FREE:
                pref.setSummary(set_screen_orientation_entries[0]);
                break;
            case Surface.ROTATION_0:
                pref.setSummary(set_screen_orientation_entries[1]);
                break;
            case Surface.ROTATION_90:
                pref.setSummary(set_screen_orientation_entries[2]);
                break;
            case Surface.ROTATION_180:
                pref.setSummary(set_screen_orientation_entries[3]);
                break;
            case Surface.ROTATION_270:
                pref.setSummary(set_screen_orientation_entries[4]);
                break;
        }
    }
  
}
