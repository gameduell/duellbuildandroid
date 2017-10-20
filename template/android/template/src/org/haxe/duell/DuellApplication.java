/*
 * Copyright (c) 2003-2016, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package org.haxe.duell;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

import android.app.Application;
import android.content.res.Configuration;
import android.support.multidex.MultiDexApplication;

import org.haxe.duell.DuellApplicationExtension;

public class DuellApplication extends MultiDexApplication
{
    private static final String TAG = "DuellApplication";

    private static WeakReference<DuellApplication> application = new WeakReference<DuellApplication>(null);

    public static DuellApplication getInstance()
    {
        return application.get();
    }

    private final List<DuellApplicationExtension> extensions;

    public DuellApplication()
    {
        application = new WeakReference<DuellApplication>(this);

        extensions = new ArrayList<DuellApplicationExtension>();

        ::foreach PLATFORM.APPLICATION_EXTENSIONS::
        extensions.add(new ::__current__:: ());::end::
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig)
    {
        super.onConfigurationChanged(newConfig);
        for (DuellApplicationExtension extension : extensions)
        {
            extension.onConfigurationChanged(newConfig);
        }
    }

    @Override
    public void onCreate()
    {
        super.onCreate();
        for (DuellApplicationExtension extension : extensions)
        {
            extension.onCreate();
        }
    }

    @Override
    public void onLowMemory()
    {
        super.onLowMemory();
        for (DuellApplicationExtension extension : extensions)
        {
            extension.onLowMemory();
        }
    }

    @Override
    public void onTerminate()
    {
        super.onTerminate();
        for (DuellApplicationExtension extension : extensions)
        {
            extension.onTerminate();
        }
    }

    ::if (PLATFORM.TARGET_SDK_VERSION >= 14)::
    @Override
    public void onTrimMemory(int level)
    {
        super.onTrimMemory(level);
        for (DuellApplicationExtension extension : extensions)
        {
            extension.onTrimMemory(level);
        }
    }
    ::end::
}
