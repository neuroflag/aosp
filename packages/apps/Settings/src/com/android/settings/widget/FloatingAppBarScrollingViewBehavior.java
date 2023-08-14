/*
 * Copyright (C) 2018 The Android Open Source Project
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

package com.android.settings.widget;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;

import androidx.annotation.VisibleForTesting;
import androidx.coordinatorlayout.widget.CoordinatorLayout;

import com.google.android.material.appbar.AppBarLayout;

/**
 * This scrolling view behavior will set the background of the {@link AppBarLayout} as
 * transparent and without the elevation. Also make header overlapped the scrolling child view.
 */
public class FloatingAppBarScrollingViewBehavior extends AppBarLayout.ScrollingViewBehavior {
    private boolean initialized;

    // 列表顶部和title底部重合时，列表的滑动距离。
    private float deltaY;
    private AppBarLayout appBarLayout;

    public FloatingAppBarScrollingViewBehavior(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @Override
    public boolean onDependentViewChanged(CoordinatorLayout parent, View child, View dependency) {
        if (appBarLayout == null) {
            appBarLayout = (AppBarLayout) dependency;
            if(!initialized){
                initialized = true;
                setAppBarLayoutTransparent(appBarLayout);
            }
         }

        final boolean result = super.onDependentViewChanged(parent, child, dependency);
        final int bottomPadding = calculateBottomPadding(appBarLayout);
        final boolean paddingChanged = bottomPadding != child.getPaddingBottom();
        if (paddingChanged) {

            child.setPadding(
                    child.getPaddingLeft(),
                    child.getPaddingTop() ,
                    child.getPaddingRight(),
                    bottomPadding);
            child.requestLayout();

        }
        return paddingChanged || result;
    }

    private int calculateBottomPadding(AppBarLayout dependency) {
        final int totalScrollRange = dependency.getTotalScrollRange();
        return totalScrollRange + dependency.getTop();
    }

    @VisibleForTesting
    void setAppBarLayoutTransparent(AppBarLayout appBarLayout) {
        appBarLayout.setBackgroundColor(Color.TRANSPARENT);
        appBarLayout.setTargetElevation(0);
    }

    @Override
    protected boolean shouldHeaderOverlapScrollingChild() {
        return true;
    }
}
