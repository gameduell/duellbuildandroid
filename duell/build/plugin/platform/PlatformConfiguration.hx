/**
 * @autor rcam
 * @date 04.08.2014.
 * @company Gameduell GmbH
 */
package duell.build.plugin.platform;

import haxe.io.Path;

import duell.objects.Haxelib;

typedef KeyValueArray = Array<{NAME : String, VALUE : String}>;

typedef PlatformConfigurationData = {
	PLATFORM_NAME : String,
	ARCHS : Array<String>,
	ICON_PATH : String,
	HXCPP_COMPILATION_ARGS : Array<String>, /// not yet used
	ACTIVITY_EXTENSIONS : Array<String>,
	JAVA_LIBS : Array<{ NAME : String, PATH : String }>,
	JAVA_SOURCES : Array<{NAME : String, PATH : String}>,
	JARS : Array<String>,
	FULLSCREEN : Bool,
	TARGET_SDK_VERSION : Int,
	USES : Array<{ NAME : String, VALUE : String, REQUIRED : Bool }>,
	PERMISSIONS : Array<String>,
	SUPPORTS_SCREENS : KeyValueArray,
	MINIMUM_SDK_VERSION : Int,
	DEBUG : Bool,
	ACTIVITY_PARAMETERS : KeyValueArray,
	INSTALL_LOCATION : String,
	KEY_STORE : String, ///optional
	KEY_STORE_ALIAS : String, ///optional
	KEY_STORE_PASSWORD : String, ///optional
	KEY_STORE_ALIAS_PASSWORD : String, ///optional

	/// THESE ARE PURE XML STRINGS THAT ARE EMBEDDED IN THE MANIFEST
	MANIFEST_MAIN_ACTIVITY_INTENT_FILTER_SECTIONS : Array<String>,
	MANIFEST_MAIN_ACTIVITY_SECTIONS : Array<String>,
	MANIFEST_APPLICATION_SECTIONS : Array<String>,
}

class PlatformConfiguration
{
	public static var _configuration : PlatformConfigurationData = null;
	private static var _parsingDefines : Array<String> = ["android", "cpp"];
	public static function getData() : PlatformConfigurationData
	{
		if (_configuration == null)
			initConfig();
		return _configuration;
	}

	public static function getConfigParsingDefines() : Array<String>
	{
		return _parsingDefines;
	}

	public static function addParsingDefine(str : String)
	{
		_parsingDefines.push(str);
	}

	private static function initConfig()
	{
		_configuration = 
		{
			PLATFORM_NAME : "android",
			ICON_PATH : "Icon/android",
			ARCHS : ["armv7"],
			HXCPP_COMPILATION_ARGS : [],
			ACTIVITY_EXTENSIONS : [],
			JAVA_LIBS : [],
			JARS : [],
			JAVA_SOURCES : [{ NAME : "HXCPP", 
							  PATH : haxe.io.Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "java"])
							  }],
			FULLSCREEN : true,
			TARGET_SDK_VERSION : 19,
			INSTALL_LOCATION : "auto",
			SUPPORTS_SCREENS : [
							{NAME : "smallScreens", VALUE : "true"},
							{NAME : "normalScreens", VALUE : "true"},
							{NAME : "largeScreens", VALUE : "true"},
							{NAME : "xlargeScreens", VALUE : "true"},
							],
			USES : [],
			PERMISSIONS : [],
			MINIMUM_SDK_VERSION : 14,
			DEBUG : false,
			ACTIVITY_PARAMETERS : [
							{NAME : "launchMode", VALUE : "singleTask"},
							{NAME : "configChanges", VALUE : "keyboard|keyboardHidden|orientation|screenSize"}
											],
			KEY_STORE : null, ///optional
			KEY_STORE_ALIAS : null, ///optional
			KEY_STORE_PASSWORD : null, ///optional
			KEY_STORE_ALIAS_PASSWORD : null, ///optional

			MANIFEST_MAIN_ACTIVITY_INTENT_FILTER_SECTIONS : [],
			MANIFEST_MAIN_ACTIVITY_SECTIONS : [],
			MANIFEST_APPLICATION_SECTIONS : [],
		};
	}
}