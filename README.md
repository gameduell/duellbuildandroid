## Description

Use this plugin to build for the android platform.
## Usage:
`$ duell build android -emulator -debug`
## Arguments:
* `-ndkgdb` &ndash; Use this argument if you want to launch gdb on the running app. Debug is option is automatically set for this.

* `-armv7` &ndash; Use this if you want to build for armv7.

* `-x86` &ndash; Use this argument if you want to build specifically for x86 platforms.

* `-fulllogcat` &ndash; Use this argument if you want to see the complete logcat as opposed to seeing a filtered one. The default filters are "duell", "Main", "DuellActivity", "GLThread" and "trace"

* `-emulatorname` &ndash; Specify the name of the emulator that you want to run when the build starts.

* `-debug` &ndash; Use this argument if you want to build in debug.

* `-signedrelease` &ndash; Use this argument if you want to sign the resulting apk.

* `-armv6` &ndash; Use this if you want to build for armv6.

* `-emulator` &ndash; Use the emulator to run the app. If x86 is specified, the x86 will launch, otherwise the armv7 will run. If the emulator is already running this will fail. If that is the case, then run without this option, as the emulator counts as a normal device. The default emulators that this uses are called "duellarmv7a" and "duellx86".

## Project Configuration Documentation:
* `<minimum-sdk>` &ndash; Use this to specify a minimum android sdk. By default it is 14. E.g.: `<minimum-sdk value="16" />`.

* `<supports-screen>` &ndash; Use this to specify that your app supports a specific screen type. E.g.: `<supports-screen name="smallScreens" value="true" />`.

* `<manifest-main-activity-section>` &ndash; This is an advanced android configuration possibility. The xml that is contained inside this element will be directly copied into the manifest in main activity section. Use this if none of the previous configuration elements allow the setting you need.

* `<raw-permission>` &ndash; Use this to specify permissions for your app (using permission). E.g.: `<raw-permission name="com.gameduell.test.permission.C2D_MESSAGE" level="signature" />`.

* `<app-icon>` &ndash; Use this to specify the icon name, as if you were inputting it as `@drawable/icon`. By default it is specified as `"icon"`. E.g.: `<app-icon drawable="app_icon" />`.

* `<permission>` &ndash; Use this to specify permissions for your app (using uses-permission). E.g.: `<permission name="android.permission.RECEIVE_SMS" />`.

* `<jar>` &ndash; Use this to add a jar. E.g.: `<jar path="path/to/jar" />`.

* `<application-parameter>` &ndash; Use this to specify an android manifest application parameter. E.g.: `<application-parameter name="largeHeap" value="true" />`.

* `<key-store>` &ndash; Use this to specify the keystore you want to use to sign your app. This configuration should mostly be in the duell_user.xml folder since it is private information and should not be committed with your project. E.g.: `<key-store path="androidkey/debug.keystore" alias="MyDebugKey" password="password" aliaspassword="password" />`.

* `<uses>` &ndash; Use this to specify that your app uses additional android features. E.g.: `<uses name="glEsVersion" value="0x00020000" required="true" />`.

* `<string-resource>` &ndash; Use this to add a string resource. E.g.: `<string-resource name="facebook_app_id" value="1234567" />`.

* `<install-location>` &ndash; Use this to specify the install location. By default it is auto. E.g.: `<install-location value="preferExternal" />`.

* `<java-source>` &ndash; Use this to add a folder that contains java sources to be compiled. This should be the top level folder in case the sources are organized in packages. E.g.: `<java-source path="path/to/lib" />`.

* `<fullscreen>` &ndash; Use this to use the new android immersive mode which hides the android back/home/etc buttons. By default it is false. E.g.: `<fullscreen value="true" />`.

* `<hxcpp-compilation-arg>` &ndash; Use this tag if you want to pass an additional compilation argument to the hxcpp compilation of the generated c++ code. E.g.: `<hxcpp-compilation-arg value="-DSOMETHING" />`.

* `<target-sdk>` &ndash; Use this to specify a target android sdk. By default it is 21. Please don't change :( E.g.: `<target-sdk value="20" />`.

* `<icon>` &ndash; Use this to configure where the icon files are. By default they are searched in current_project_path/Icons/android. The naming and sizing is strict. To know them, just do a "duell create emptyProject" and see the icons that are on the default project. E.g.: `<icon path="Iconys/android" />`.

* `<manifest-main-activity-intent-filter-section>` &ndash; This is an advanced android configuration possibility. The xml that is contained inside this element will be directly copied into the manifest in intent filter section. Use this if none of the previous configuration elements allow the setting you need.

* `<manifest-application-section>` &ndash; This is an advanced android configuration possibility. The xml that is contained inside this element will be directly copied into the manifest in application section. Use this if none of the previous configuration elements allow the setting you need.

* `<activity-extension>` &ndash; Use this to specify a class as being an activity extension that will then receive Activity callbacks. This is used together with inserting java classes into the final app. E.g.: `<activity-extension name="com.superlib.SuperLibDelegate" />`.

* `<activity-parameter>` &ndash; Use this to specify an android manifest activity parameter. E.g.: `<activity-parameter name="theme" value="@android:style/Theme.NoTitleBar.Fullscreen" />`.

* `<gradle-repository>` &ndash; Use this to specify a gradle repository. E.g.: `<gradle-repository name="jcenter" url="www.someurl.com" />`.

* `<gradle-dependency>` &ndash; Use this to specify a gradle dependency. E.g.: `<gradle-dependency value="com.google.android.gms:play-services-base:8.1.0" />`.
