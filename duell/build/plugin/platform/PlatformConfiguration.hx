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

package duell.build.plugin.platform;

import haxe.io.Path;
import duell.helpers.PathHelper;

import duell.objects.Haxelib;

typedef KeyValueArray = Array<{NAME : String, VALUE : String}>;

typedef PlatformConfigurationData = {
	PLATFORM_NAME : String,
	ARCHS : Array<String>,
	ICON_PATH : String,
    APP_ICON : String,
	HXCPP_COMPILATION_ARGS : Array<String>, /// not yet used
	ACTIVITY_EXTENSIONS : Array<String>,
	JAVA_SOURCES : Array<{NAME : String, PATH : String}>,
	JARS : Array<String>,
	FULLSCREEN : Bool,
	TARGET_SDK_VERSION : Int,
	USES : Array<{ NAME : String, VALUE : String, REQUIRED : Bool }>,
	PERMISSIONS : Array<String>,
    RAW_PERMISSIONS: Array<{ NAME : String, LEVEL : String}>,
	SUPPORTS_SCREENS : KeyValueArray,
	MINIMUM_SDK_VERSION : Int,
	DEBUG : Bool,
	STRING_RESOURCES : KeyValueArray,
	ACTIVITY_PARAMETERS : KeyValueArray,
	APPLICATION_PARAMETERS : KeyValueArray,
	INSTALL_LOCATION : String,
	KEY_STORE : String,
	KEY_STORE_ALIAS : String,
	KEY_STORE_PASSWORD : String,
	KEY_STORE_ALIAS_PASSWORD : String,
	PROJECT_PROPERTIES: Array<String>,
	PROGUARD_PATHS: Array<String>,
	GRADLE_REPOSITORIES: Array<{NAME: String, URL: String}>,
	GRADLE_DEPENDENCIES: Array<String>,

	/// THESE ARE PURE XML STRINGS THAT ARE EMBEDDED IN THE MANIFEST
	MANIFEST_MAIN_ACTIVITY_INTENT_FILTER_SECTIONS : Array<String>,
	MANIFEST_MAIN_ACTIVITY_SECTIONS : Array<String>,
	MANIFEST_APPLICATION_SECTIONS : Array<String>,

	/// generated
	ARCH_ABIS : Array<String>,
	NDK_PATH : String,
	PROGUARD_CONTENT : Array<String>,
	PROGUARD_ENABLED : Bool,

	/// generated from publish
	PUBLISHED_APK_PATH: String,
	PUBLISHED_MAPPING_PATH: String
}

class PlatformConfiguration
{
	private static var _configuration : PlatformConfigurationData = null;
	public static function getData() : PlatformConfigurationData
	{
		if (_configuration == null)
			_configuration = getDefaultConfig();
		return _configuration;
	}

	public static function getConfigParsingDefines() : Array<String>
	{
		return ["android", "cpp"];
	}

	private static function getDefaultConfig() : PlatformConfigurationData
	{
		return  {
					PLATFORM_NAME : "android",
					ICON_PATH : "Icons/android",
                    APP_ICON : "icon",
					ARCHS : ["armv7"],
					HXCPP_COMPILATION_ARGS : [],
					ACTIVITY_EXTENSIONS : [],
					JARS : [],
					JAVA_SOURCES : [{ NAME : "HXCPP",
									  PATH : haxe.io.Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "java"])
									  }],
					FULLSCREEN : false,
					TARGET_SDK_VERSION : 23,
					INSTALL_LOCATION : "auto",
					SUPPORTS_SCREENS : [
									{NAME : "smallScreens", VALUE : "true"},
									{NAME : "normalScreens", VALUE : "true"},
									{NAME : "largeScreens", VALUE : "true"},
									{NAME : "xlargeScreens", VALUE : "true"}
									],
					USES : [],
                    RAW_PERMISSIONS: [],
					PERMISSIONS : [],
					MINIMUM_SDK_VERSION : 15,
					DEBUG : false,
					STRING_RESOURCES : [],
					ACTIVITY_PARAMETERS : [
									{NAME : "launchMode", VALUE : "singleTask"},
									{NAME : "configChanges", VALUE : "keyboard|keyboardHidden|orientation|screenSize"}
													],
					APPLICATION_PARAMETERS : [],
					KEY_STORE : Path.join([PathHelper.getHomeFolder(), ".android", "debug.keystore"]),
					KEY_STORE_ALIAS : "androiddebugkey",
					KEY_STORE_PASSWORD : "android",
					KEY_STORE_ALIAS_PASSWORD : "android",
					PROGUARD_PATHS : [],
					GRADLE_REPOSITORIES: [],
					GRADLE_DEPENDENCIES: [],

					MANIFEST_MAIN_ACTIVITY_INTENT_FILTER_SECTIONS : [],
					MANIFEST_MAIN_ACTIVITY_SECTIONS : [],
					MANIFEST_APPLICATION_SECTIONS : [],

					PROJECT_PROPERTIES : [],
					PROGUARD_CONTENT: [],
					PROGUARD_ENABLED: false,

					ARCH_ABIS : [],
					NDK_PATH : "",

					PUBLISHED_APK_PATH : "",
					PUBLISHED_MAPPING_PATH : ""
				};
	}
}
