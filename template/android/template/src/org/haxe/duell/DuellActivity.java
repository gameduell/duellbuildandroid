package org.haxe.duell;


import android.app.Activity;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import dalvik.system.DexClassLoader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.Math;
import java.lang.Runnable;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.List;
import org.haxe.duell.Extension;
import org.haxe.HXCPP;

public class DuellActivity extends Activity { 
	
	private static WeakReference<DuellActivity> activity = new WeakReference<DuellActivity>(null);
	public static DuellActivity getInstance () { 
		return activity.get(); 
	}

	private static List<Extension> extensions;
	
	protected void onCreate (Bundle state) {
		
		super.onCreate (state);
		
		activity = new WeakReference<DuellActivity>(this);
		
		requestWindowFeature (Window.FEATURE_NO_TITLE);
		
		::if PLATFORM.FULLSCREEN::
			::if (PLATFORM.TARGET_SDK_VERSION < 19)::
				getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
					| WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
			::end::
		::end::

	   	::foreach NDLLS::
			System.loadLibrary("::NAME::");
	   	::end::
		HXCPP.run ("HaxeApplication");
		
		if (extensions == null) {
			
			extensions = new ArrayList<Extension> ();
			::foreach PLATFORM.ACTIVITY_EXTENSIONS::
			extensions.add(new ::NAME:: ());::end::
			
		}
		
		for (Extension extension : extensions) {
			
			extension.onCreate(state);
			
		}
		
	}
	
	// IMMERSIVE MODE SUPPORT
	::if (PLATFORM.FULLSCREEN)::
	::if (PLATFORM.TARGET_SDK_VERSION >= 19)::
	
	@Override
	public void onWindowFocusChanged(boolean hasFocus) {
		super.onWindowFocusChanged(hasFocus);
		
		if(hasFocus) {
			hideSystemUi();
		}
	}

	private void hideSystemUi() {
		View decorView = this.getWindow().getDecorView();
		
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
	
	@Override protected void onActivityResult (int requestCode, int resultCode, Intent data) {
		
		for (Extension extension : extensions) {
			
			if (!extension.onActivityResult (requestCode, resultCode, data)) {
				
				return;
				
			}
			
		}
		
		super.onActivityResult (requestCode, resultCode, data);
		
	}
	
	
	@Override protected void onDestroy () {
		
		for (Extension extension : extensions) {
			
			extension.onDestroy ();
			
		}
		
		activity = null;
		super.onDestroy ();
	}
	
	
	@Override public void onLowMemory () {
		
		super.onLowMemory ();
		
		for (Extension extension : extensions) {
			
			extension.onLowMemory ();
			
		}
		
	}
	
	
	@Override protected void onNewIntent (final Intent intent) {
		
		for (Extension extension : extensions) {
			
			extension.onNewIntent (intent);
			
		}
		
		super.onNewIntent (intent);
		
	}
	
	
	@Override protected void onPause () {
		
		super.onPause ();
		
		for (Extension extension : extensions) {
			
			extension.onPause ();
			
		}
		
	}
	
	
	@Override protected void onRestart () {
		
		super.onRestart ();
		
		for (Extension extension : extensions) {
			
			extension.onRestart ();
			
		}
		
	}
	
	
	@Override protected void onResume () {
		
		super.onResume();
		
		for (Extension extension : extensions) {
			
			extension.onResume ();
			
		}
		
	}
	

	@Override protected void onStart () {
		
		super.onStart();
		
		::if PLATFORM.FULLSCREEN::::if (PLATFORM.ANDROID_TARGET_SDK_VERSION >= 16)::
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
			
			getWindow().getDecorView().setSystemUiVisibility (View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LOW_PROFILE | View.SYSTEM_UI_FLAG_FULLSCREEN);
			
		}
		::end::::end::
		
		for (Extension extension : extensions) {

			extension.onStart ();
			
		}
		
	}
	
	
	@Override protected void onStop () {
		
		super.onStop ();
		
		for (Extension extension : extensions) {
			
			extension.onStop ();
			
		}
		
	}
	
	
	::if (PLATFORM.TARGET_SDK_VERSION >= 14)::
	@Override public void onTrimMemory (int level) {
		
		super.onTrimMemory (level);
		
		for (Extension extension : extensions) {
			
			extension.onTrimMemory (level);
			
		}
		
	}
	::end::
	
	
	public static void registerExtension (Extension extension) {
		
		if (extensions.indexOf (extension) == -1) {
			
			extensions.add (extension);
			
		}
		
	}
	
	
}
