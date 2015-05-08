/*
 * Copyright (c) 2003-2015, GameDuell GmbH
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

import android.content.Intent;
import android.os.Bundle;
import android.view.KeyEvent;


public class Extension
{
    /**
     * Called when an activity you launched exits, giving you the requestCode you started it with, the resultCode it
     * returned, and any additional data from it.
     */
    public boolean onActivityResult(int requestCode, int resultCode, Intent data)
    {
        return true;
    }

    /**
     * Called when the activity is starting.
     */
    public void onCreate(Bundle savedInstanceState)
    {

    }

    /**
     * Perform any final cleanup before an activity is destroyed.
     */
    public void onDestroy()
    {

    }

    /**
     * Called when the overall system is running low on memory, and actively running processes should trim their memory
     * usage. This is a backwards compatibility method as it is called at the same time as
     * onTrimMemory(TRIM_MEMORY_COMPLETE).
     */
    public void onLowMemory()
    {

    }

    /**
     * Called when the a new Intent is received
     */
    public void onNewIntent(Intent intent)
    {

    }

    /**
     * Called as part of the activity lifecycle when an activity is going into the background, but has not (yet) been
     * killed.
     */
    public void onPause()
    {

    }

    /**
     * Called after {@link #onStop} when the current activity is being re-displayed to the user (the user has navigated
     * back to it).
     */
    public void onRestart()
    {

    }

    /**
     * Called after {@link #onRestart}, or {@link #onPause}, for your activity to start interacting with the user.
     */
    public void onResume()
    {

    }

    /**
     * Called after {@link #onCreate} &mdash; or after {@link #onRestart} when the activity had been stopped, but is now
     * again being displayed to the user.
     */
    public void onStart()
    {

    }

    /**
     * Called when the activity is no longer visible to the user, because another activity has been resumed and is
     * covering this one.
     */
    public void onStop()
    {

    }

    /**
     * This method is called before an activity may be killed so that when it comes back some time in the future it can
     * restore its state.
     * <p/>
     * If called, this method will occur before onStop(). There are no guarantees about whether it will occur before or
     * after onPause().
     *
     * @param outState Bundle in which to place your saved state.
     */
    public void onSaveInstanceState(Bundle outState)
    {

    }

    /**
     * Called when the operating system has determined that it is a good time for a process to trim unneeded memory from
     * its process.
     * <p/>
     * See http://developer.android.com/reference/android/content/ComponentCallbacks2.html for the level explanation.
     */
    public void onTrimMemory(int level)
    {

    }

    /**
     * Called when a key was pressed down and not handled by any of the views inside of the activity.
     *
     * @param keyCode The value in event.getKeyCode().
     * @param event Description of the key event.
     */
    public void onKeyDown(int keyCode, KeyEvent event)
    {

    }

    /**
     * Called when a key was released and not handled by any of the views inside of the activity
     *
     * @param keyCode The value in event.getKeyCode().
     * @param event Description of the key event.
     */
    public void onKeyUp(int keyCode, KeyEvent event)
    {

    }
}
