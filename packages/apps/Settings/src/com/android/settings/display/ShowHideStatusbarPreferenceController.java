package com.android.settings.display;

import android.content.Context;
import android.provider.Settings;
import androidx.preference.SwitchPreference;
import androidx.preference.Preference;

import com.android.settings.core.PreferenceControllerMixin;
import com.android.settingslib.core.AbstractPreferenceController;
import android.content.Intent;


public class ShowHideStatusbarPreferenceController extends AbstractPreferenceController implements
        PreferenceControllerMixin, Preference.OnPreferenceChangeListener {

    private static final String KEY_TAP_TO_WAKE = "show_hide_statusbar";

    public ShowHideStatusbarPreferenceController(Context context) {
        super(context);
    }

    @Override
    public String getPreferenceKey() {
        return KEY_TAP_TO_WAKE;
    }

    @Override
    public boolean isAvailable() {
        return true;
    }

    @Override
    public void updateState(Preference preference) {
        int value = Settings.System.getInt(
                mContext.getContentResolver(), Settings.System.ALWAYS_HIDE_BAR, 0);
        ((SwitchPreference) preference).setChecked(value != 0);
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        boolean value = (Boolean) newValue;
        Settings.System.putInt(
                mContext.getContentResolver(), Settings.System.ALWAYS_HIDE_BAR, value ? 1 : 0);
        Intent intent = new Intent(Intent.ACTION_ALWAYS_HIDE_BAR_CHANGE);
        mContext.sendBroadcast(intent);
        return true;
    }
}
