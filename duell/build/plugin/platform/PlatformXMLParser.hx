/**
 * @autor rcam
 * @date 04.08.2014.
 * @company Gameduell GmbH
 */
package duell.build.plugin.platform;


import duell.build.objects.DuellProjectXML;
import duell.build.objects.Configuration;

import duell.build.plugin.platform.PlatformConfiguration;

import duell.helpers.XMLHelper;
import duell.helpers.LogHelper;


import haxe.xml.Fast;

class PlatformXMLParser
{
	public static function parse(xml : Fast) : Void
	{
		for (element in xml.elements) 
		{
			switch(element.name)
			{
				case 'android':
					parsePlatform(element);
			}
		}
	}

	public static function parsePlatform(xml : Fast) : Void
	{
		for (element in xml.elements) 
		{
			if (!XMLHelper.isValidElement(element, DuellProjectXML.getConfig().parsingConditions))
				continue;

			switch(element.name)
			{
				case 'architecture':
					parseArchitectureElement(element);

				case 'icon':
					parseIconElement(element);

				case 'hxcpp-compilation-arg':
					parseHXCPPCompilationArgElement(element);

				case 'install-location':
					parseInstallLocationElement(element);

				case 'target-sdk':
					parseTargetSDKElement(element);

				case 'minimum-sdk':
					parseMinimumSDKElement(element);

				case 'fullscreen':
					parseFullscreenElement(element);

				case 'uses':
					parseUsesElement(element);

				case 'permission':
					parsePermissionElement(element);

				case 'activity-extension':
					parseActivityExtensionElement(element);

				case 'java-lib':
					parseJavaLibElement(element);

				case 'jar':
					parseJarElement(element);

				case 'java-source':
					parseJavaSourceElement(element);

				case 'supports-screen':
					parseSupportsScreenElement(element);

				case 'activity-parameter':
					parseActivityParameterElement(element);

				case 'application-parameter':
					parseApplicationParameterElement(element);

				case 'manifest-main-activity-section':
					parseManifestMainActivitySectionElement(element);

				case 'manifest-main-activity-intent-filter-section':
					parseManifestMainActivityIntentFilterSectionElement(element);

				case 'manifest-application-section':
					parseManifestApplicationSectionElement(element);
			}
		}
	}

	private static function parseArchitectureElement(element : Fast)
	{
		if (element.has.name)
		{
			if (PlatformConfiguration.getData().ARCHS.indexOf(element.att.name) == -1)
			{
				PlatformConfiguration.getData().ARCHS.push(element.att.name);
			}
		}
	}

	private static function parseIconElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().ICON_PATH = resolvePath(element.att.path);
		}
	}

	private static function parseHXCPPCompilationArgElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().HXCPP_COMPILATION_ARGS.push(element.att.value);
		}
	}

	private static function parseInstallLocationElement(element : Fast)
	{
		if (element.has.value)
		{
			PlatformConfiguration.getData().INSTALL_LOCATION = element.att.value;
		}
	}

	private static function parseTargetSDKElement(element : Fast)
	{
		if (element.has.value)
		{
			var value = Std.parseInt(element.att.value);
			PlatformConfiguration.getData().TARGET_SDK_VERSION = value;
		}
	}

	private static function parseMinimumSDKElement(element : Fast)
	{
		if (element.has.value)
		{
			var value = Std.parseInt(element.att.value);
			PlatformConfiguration.getData().MINIMUM_SDK_VERSION = value;
		}
	}

	private static function parseFullscreenElement(element : Fast)
	{
		if (element.has.value)
		{
			var value = element.att.value == "true" ? true : false;
			PlatformConfiguration.getData().FULLSCREEN = value;
		}
	}

	private static function parseUsesElement(element : Fast)
	{		
		var name = "name";
		var value = null;
		var required = null;

		if (element.has.name)
		{
			name = element.att.name;
		}

		if (element.has.value)
		{
			value = element.att.value;
		}

		if (element.has.required)
		{
			required = element.att.required == "true" ? true : false;
		}


		if (value != null && required != null)
		{
			PlatformConfiguration.getData().USES.push({NAME : name, VALUE : value, REQUIRED : required});
		}
	}

	private static function parsePermissionElement(element : Fast)
	{	
		if (element.has.name)
		{
			PlatformConfiguration.getData().PERMISSIONS.push(element.att.name);
		}
	}

	private static function parseActivityExtensionElement(element : Fast)
	{
		var name = null;
		if (element.has.name)
		{
			name = element.att.name;
			PlatformConfiguration.getData().ACTIVITY_EXTENSIONS.push(name);
		}
	}

	private static function parseJavaLibElement(element : Fast):Void
	{
		if (element.has.path)
		{
			var path = resolvePath(element.att.path);
			var name = null;

			if (element.has.name)
			{
				name = element.att.name;
			}

			PlatformConfiguration.getData().JAVA_LIBS.push({PATH : path, NAME : name});
		}
	}

	private static function parseJavaSourceElement(element : Fast)
	{
		if (element.has.path)
		{
			var path = resolvePath(element.att.path);
			var name = null;

			if (element.has.name)
			{
				name = element.att.name;
			}

			PlatformConfiguration.getData().JAVA_SOURCES.push({PATH : path, NAME : name});
		}
	}

	private static function parseJarElement(element : Fast)
	{
		if (element.has.path)
		{
			var path = resolvePath(element.att.path);

			PlatformConfiguration.getData().JARS.push(path);
		}
	}

	private static function parseSupportsScreenElement(element : Fast)
	{		
		var name = null;
		var value = null;

		if (element.has.name)
		{
			name = element.att.name;
		}

		if (element.has.value)
		{
			value = element.att.value;
		}

		if (element != null && value != null)
		{
			addUniqueKeyValueToKeyValueArray(PlatformConfiguration.getData().SUPPORTS_SCREENS, name, value);
		}
	}

	private static function parseActivityParameterElement(element : Fast)
	{
		var name = null;
		var value = null;

		if (element.has.name)
		{
			name = element.att.name;
		}

		if (element.has.value)
		{
			value = element.att.value;
		}

		if (element != null && value != null)
		{
			addUniqueKeyValueToKeyValueArray(PlatformConfiguration.getData().ACTIVITY_PARAMETERS, name, value);
		}
	}

	private static function parseApplicationParameterElement(element : Fast)
	{
		var name = null;
		var value = null;

		if (element.has.name)
		{
			name = element.att.name;
		}

		if (element.has.value)
		{
			value = element.att.value;
		}

		if (element != null && value != null)
		{
			addUniqueKeyValueToKeyValueArray(PlatformConfiguration.getData().APPLICATION_PARAMETERS, name, value);
		}
	}

	private static function parseManifestMainActivitySectionElement(element : Fast)
	{
		PlatformConfiguration.getData().MANIFEST_MAIN_ACTIVITY_SECTIONS.push(element.innerHTML);
	}

	private static function parseManifestMainActivityIntentFilterSectionElement(element : Fast)
	{
		PlatformConfiguration.getData().MANIFEST_MAIN_ACTIVITY_INTENT_FILTER_SECTIONS.push(element.innerHTML);
	}

	private static function parseManifestApplicationSectionElement(element : Fast)
	{
		PlatformConfiguration.getData().MANIFEST_APPLICATION_SECTIONS.push(element.innerHTML);
	}

	/// HELPERS
	private static function addUniqueKeyValueToKeyValueArray(keyValueArray : KeyValueArray, key : String, value : String)
	{
		for (keyValuePair in keyValueArray)
		{
			if (keyValuePair.NAME == key)
			{
				LogHelper.println('Overriting key $key value ${keyValuePair.VALUE} with value $value');
				keyValuePair.VALUE = value;
			}
		}

		keyValueArray.push({NAME : key, VALUE : value});
	}

	private static function resolvePath(string : String) : String /// convenience method
	{
		return DuellProjectXML.getConfig().resolvePath(string);
	}
}