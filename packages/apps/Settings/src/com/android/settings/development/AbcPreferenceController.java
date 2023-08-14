/*
 * Copyright (C) 2017 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.android.settings.development;

import android.content.Context;
import android.os.UserManager;
import android.provider.Settings;

import androidx.annotation.VisibleForTesting;
import androidx.preference.Preference;
import androidx.preference.SwitchPreference;

import com.android.settings.core.PreferenceControllerMixin;
import com.android.settingslib.development.DeveloperOptionsPreferenceController;
import android.os.SystemProperties;
import android.util.Log;


public class AbcPreferenceController extends
        DeveloperOptionsPreferenceController implements Preference.OnPreferenceChangeListener,
        PreferenceControllerMixin {

    private static final String KEY_ENABLE_ABC = "enable_abc";

    public static final int ABC_SETTING_ON = 1;
    public static final int ABC_SETTING_OFF = 0;


    public AbcPreferenceController(Context context) {
        super(context);
    }

    @Override
    public boolean isAvailable() {
        return true;
    }

    @Override
    public String getPreferenceKey() {
        return KEY_ENABLE_ABC;
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        final boolean isEnabled = (Boolean) newValue;
        if(isEnabled)
        {
            SystemProperties.set("persist.abc_switch", "1");
        }else{
            SystemProperties.set("persist.abc_switch", "0");
        }
        return true;
    }

    @Override
    public void updateState(Preference preference) {
        final int mode = SystemProperties.getInt("persist.abc_switch", 0);
        ((SwitchPreference) mPreference).setChecked(mode != ABC_SETTING_OFF);
    }

    @Override
    protected void onDeveloperOptionsSwitchDisabled() {
        super.onDeveloperOptionsSwitchDisabled();
        SystemProperties.set("persist.abc_switch", "0");
        ((SwitchPreference) mPreference).setChecked(false);
}
    }