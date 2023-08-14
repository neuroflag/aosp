/*
 * Copyright (C) 2016 The Android Open Source Project
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

package com.android.settings.connecteddevice;

import android.content.Context;
import android.os.SystemProperties;
import android.text.TextUtils;
import android.util.Log;

import androidx.preference.Preference;
import androidx.preference.PreferenceScreen;

import com.android.settings.R;
import com.android.settings.RestrictedListPreference;
import com.android.settings.Utils;
import com.android.settings.core.PreferenceControllerMixin;
import com.android.settingslib.core.AbstractPreferenceController;
import com.android.settingslib.core.lifecycle.LifecycleObserver;
import com.android.settingslib.core.lifecycle.events.OnPause;
import com.android.settingslib.core.lifecycle.events.OnResume;

import java.util.ArrayList;

public class M2SsdPreferenceController extends AbstractPreferenceController
        implements PreferenceControllerMixin, Preference.OnPreferenceChangeListener,
        LifecycleObserver, OnResume, OnPause {

    private static final String TAG = "M2SsdPreferenceController";
    private static final String KEY_M2_SSD = "m2_ssd_type";
    private static final String PROPERTY_DTO_CONFIGS = "persist.vendor.dto.configs";

    private RestrictedListPreference mSSDscreen;
    private int mSSDscreenSelectedValue;

    public M2SsdPreferenceController(Context context) {
        super(context);
    }

    @Override
    public void displayPreference(PreferenceScreen screen) {
        super.displayPreference(screen);
        Log.d(TAG, "displayPreference");
        mSSDscreen = screen.findPreference(KEY_M2_SSD);
        if (mSSDscreen == null) {
            Log.i(TAG, "Preference not found: " + KEY_M2_SSD);
            return;
        }

        String value = SystemProperties.get(PROPERTY_DTO_CONFIGS, "");
        if ((-1 == value.indexOf("sata")) && (-1 == value.indexOf("pcie"))) {
            screen.removePreference(mSSDscreen);
        } else {
            initDisplay();
        }
    }

    private void initDisplay() {
        ArrayList<CharSequence> entries = new ArrayList<>();
        ArrayList<CharSequence> values = new ArrayList<>();

        String summaryShowEntry = mContext.getString(R.string.m2_ssd_sata);
        String summaryShowEntryValue = Integer.toString(R.string.m2_ssd_sata);

        entries.add(summaryShowEntry);
        values.add(summaryShowEntryValue);

        entries.add(mContext.getString(R.string.m2_ssd_pcie));
        values.add(Integer.toString(R.string.m2_ssd_pcie));

        mSSDscreen.setEntries(entries.toArray(new CharSequence[entries.size()]));
        mSSDscreen.setEntryValues(values.toArray(new CharSequence[values.size()]));

        updateScreen();

        if (mSSDscreen.getEntries().length > 1) {
            mSSDscreen.setOnPreferenceChangeListener(this);
        } else {
            // There is one or less option for the user, disable the drop down.
            mSSDscreen.setEnabled(false);
        }
    }

    @Override
    public String getPreferenceKey() {
        return null;
    }

    @Override
    public boolean isAvailable() {
        return false;
    }

    @Override
    public void onResume() {
    }

    @Override
    public void onPause() {
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        final String key = preference.getKey();
        if (TextUtils.equals(KEY_M2_SSD, key)) {
            String oldValue = SystemProperties.get(PROPERTY_DTO_CONFIGS, "");
            final int val = Integer.parseInt((String) newValue);
            if (val == R.string.m2_ssd_sata) {
                String value = oldValue.replace("pcie", "sata");
                SystemProperties.set(PROPERTY_DTO_CONFIGS, value);
            } else if (val == R.string.m2_ssd_pcie) {
                String value = oldValue.replace("sata", "pcie");
                SystemProperties.set(PROPERTY_DTO_CONFIGS, value);
            }
            mSSDscreenSelectedValue = val;
            return true;
        }

        return false;
    }

    public static int getSummaryResource(Context context) {
        final boolean enabled = isPCIe();
        return (!enabled ? R.string.m2_ssd_sata : R.string.m2_ssd_pcie);
    }

    private void updateScreen() {
        if (mSSDscreen == null) {
            return;
        }

        mSSDscreenSelectedValue = getSummaryResource(mContext);
        mSSDscreen.setSummary("%s");
        mSSDscreen.setValue(Integer.toString(mSSDscreenSelectedValue));
    }

    public static boolean isPCIe() {
        String value = SystemProperties.get(PROPERTY_DTO_CONFIGS, "");
        if ((-1 != value.indexOf("pcie"))) {
            return true;
        }

        return false;
    }
}
