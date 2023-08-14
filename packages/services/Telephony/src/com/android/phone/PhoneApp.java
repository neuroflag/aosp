/*
 * Copyright (C) 2012 The Android Open Source Project
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

package com.android.phone;

import android.app.Application;
import android.os.UserHandle;
import android.os.Looper;
import android.util.Log;

import com.android.services.telephony.TelecomAccountRegistry;
import android.os.Handler;

/**
 * Top-level Application class for the Phone app.
 */
public class PhoneApp extends Application {
    PhoneGlobals mPhoneGlobals;

    public PhoneApp() {
    }

    @Override
    public void onCreate() {
        if (UserHandle.myUserId() == 0) {
            new Thread(new Runnable() {

                @Override
                public void run() {
                    Looper.prepare(); 
                    mPhoneGlobals = new PhoneGlobals(PhoneApp.this);
                    mPhoneGlobals.onCreate();
                    Looper.loop();
                    Handler handler = new Handler(Looper.getMainLooper());
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            TelecomAccountRegistry.getInstance(getApplicationContext()).setupOnBoot();
                        }
                    });                   
                }
            }).start();
        }
    }
}
