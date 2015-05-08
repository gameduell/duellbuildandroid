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
				case 'icon':
					parseIconElement(element);

                case 'app-icon':
                    parseAppIconElement(element);

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

                case 'raw-permission':
                    parseRawPermissionElement(element);

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

				case 'string-resource':
					parseStringResourceElement(element);

				case 'activity-parameter':
					parseActivityParameterElement(element);

				case 'application-parameter':
					parseApplicationParameterElement(element);

				case 'key-store':
					parseKeystoreElement(element);

				case 'manifest-main-activity-section':
					parseManifestMainActivitySectionElement(element);

				case 'manifest-main-activity-intent-filter-section':
					parseManifestMainActivityIntentFilterSectionElement(element);

				case 'manifest-application-section':
					parseManifestApplicationSectionElement(element);
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

    private static function parseAppIconElement(element : Fast)
    {
        if (element.has.drawable)
        {
            PlatformConfiguration.getData().APP_ICON = element.att.drawable;
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

    private static function parseRawPermissionElement(element : Fast)
    {
        if (element.has.name && element.has.level)
        {
            PlatformConfiguration.getData().RAW_PERMISSIONS.push({NAME : element.att.name, LEVEL : element.att.level});
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

	private static function parseStringResourceElement(element : Fast)
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
			addUniqueKeyValueToKeyValueArray(PlatformConfiguration.getData().STRING_RESOURCES, name, value);
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

	private static function parseKeystoreElement(element : Fast)
	{
		if (element.has.path)
		{
			PlatformConfiguration.getData().KEY_STORE = resolvePath(element.att.path);

			if (element.has.alias)
			{
				PlatformConfiguration.getData().KEY_STORE_ALIAS = element.att.alias;
			}

			if (element.has.password)
			{
				PlatformConfiguration.getData().KEY_STORE_PASSWORD = element.att.password;
			}

			if (element.has.aliaspassword)
			{
				PlatformConfiguration.getData().KEY_STORE_ALIAS_PASSWORD = element.att.aliaspassword;
			}
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
