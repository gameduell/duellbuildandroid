package org.haxe.duell;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.KeyEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import org.haxe.HXCPP;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;


public class DuellActivity extends Activity
{
    private static WeakReference<DuellActivity> activity = new WeakReference<DuellActivity>(null);

    private final Handler mainJavaThreadHandler;
    private MainHaxeThreadHandler mainHaxeThreadHandler;

    /** Exposes the parent so that it can be used to set the content view instead */
    public FrameLayout parent;

    /// libraries that initialize a view, may choose to set this, so that other libraries can act upon this
    public WeakReference<View> mainView;

    private final List<Extension> extensions;

    public DuellActivity()
    {
        DuellActivity.activity = new WeakReference<DuellActivity>(this);

        mainView = new WeakReference<View>(null);
        mainJavaThreadHandler = new Handler();

        // default handler
        mainHaxeThreadHandler = new MainHaxeThreadHandler()
        {
            @Override
            public void queueRunnableOnMainHaxeThread(Runnable runObj)
            {
                mainJavaThreadHandler.post(runObj);
            }
        };

        extensions = new ArrayList<Extension>();

        ::foreach PLATFORM.ACTIVITY_EXTENSIONS::;
        extensions.add(new ::__current__:: ());::end::
    }

    public static DuellActivity getInstance()
    {
        return activity.get();
    }

    protected void onCreate(Bundle state)
    {
        super.onCreate(state);

        requestWindowFeature(Window.FEATURE_NO_TITLE);

        ::if PLATFORM.FULLSCREEN::
        ::if (PLATFORM.TARGET_SDK_VERSION < 19)::
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        ::end::
        ::end::

        ::foreach NDLLS::
        System.loadLibrary("::NAME::");::end::

        ;parent = new FrameLayout(this);
        super.setContentView(parent);

        HXCPP.run("HaxeApplication");

        for (Extension extension : extensions)
        {
            extension.onCreate(state);
        }
    }

    ::if (PLATFORM.FULLSCREEN)::
    ::if (PLATFORM.TARGET_SDK_VERSION >= 19)::
    // IMMERSIVE MODE SUPPORT
    @Override
    public void onWindowFocusChanged(boolean hasFocus)
    {
        super.onWindowFocusChanged(hasFocus);

        if (hasFocus)
        {
            hideSystemUi();
        }
    }

    private void hideSystemUi()
    {
        View decorView = getWindow().getDecorView();

        decorView.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    }
    ::end::
    ::end::

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        for (Extension extension : extensions)
        {
            if (!extension.onActivityResult(requestCode, resultCode, data))
            {
                return;
            }
        }

        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onDestroy()
    {
        for (Extension extension : extensions)
        {
            extension.onDestroy();
        }

        activity = null;
        super.onDestroy();
    }

    @Override
    public void onLowMemory()
    {
        super.onLowMemory();

        for (Extension extension : extensions)
        {
            extension.onLowMemory();
        }
    }

    @Override
    protected void onNewIntent(final Intent intent)
    {
        for (Extension extension : extensions)
        {
            extension.onNewIntent(intent);
        }

        super.onNewIntent(intent);
    }

    @Override
    protected void onPause()
    {
        super.onPause();

        for (Extension extension : extensions)
        {
            extension.onPause();
        }
    }

    @Override
    protected void onRestart()
    {
        super.onRestart();

        for (Extension extension : extensions)
        {
            extension.onRestart();
        }
    }

    @Override
    protected void onResume()
    {
        super.onResume();

        for (Extension extension : extensions)
        {
            extension.onResume();
        }
    }

    @Override
    protected void onStart()
    {
        super.onStart();

        ::if PLATFORM.FULLSCREEN::::if (PLATFORM.ANDROID_TARGET_SDK_VERSION >= 16)::
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN)
        {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LOW_PROFILE | View.SYSTEM_UI_FLAG_FULLSCREEN);
        }
        ::end::::end::

        for (Extension extension : extensions)
        {
            extension.onStart();
        }
    }

    @Override
    protected void onStop()
    {
        super.onStop();

        for (Extension extension : extensions)
        {
            extension.onStop();
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState)
    {
        super.onSaveInstanceState(outState);

        for (Extension extension : extensions)
        {
            extension.onSaveInstanceState(outState);
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event)
    {
        for (Extension extension : extensions)
        {
            extension.onKeyDown(keyCode, event);
        }

        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event)
    {
        for (Extension extension : extensions)
        {
            extension.onKeyUp(keyCode, event);
        }

        return super.onKeyUp(keyCode, event);
    }

    ::if (PLATFORM.TARGET_SDK_VERSION >= 14)::
    @Override
    public void onTrimMemory(int level)
    {
        super.onTrimMemory(level);

        for (Extension extension : extensions)
        {
            extension.onTrimMemory(level);
        }
    }
    ::end::

    public void registerExtension(Extension extension)
    {
        if (extensions.indexOf(extension) == -1)
        {
            extensions.add(extension);
        }
    }

    /// post to this queue any java to haxe communication on the main thread.
    /// may be set by extension to be something else, for example, the opengl library can setMainThreadHandler
    /// to be processed in the gl thread because it is generally preferable to communicate with haxe by that.
    /// defaults to itself
    public void queueOnHaxeThread(Runnable run)
    {
        mainHaxeThreadHandler.queueRunnableOnMainHaxeThread(run);
    }

    /// if you want to force some callback to be executed on the main thread
    public void queueOnMainThread(Runnable run)
    {
        mainJavaThreadHandler.post(run);
    }

    public void setMainHaxeThreadHandler(MainHaxeThreadHandler handler)
    {
        mainHaxeThreadHandler = handler;
    }

    @Override
    public void setContentView(View view)
    {
        throw new IllegalStateException("Callers should interact with the parent FrameLayout instead of with the view directly");
    }
}
