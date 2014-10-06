/**
 * @autor rcam
 * @date 05.08.2014.
 * @company Gameduell GmbH
 */

package duell.build.plugin.platform;

import duell.build.objects.DuellProjectXML;
import duell.build.objects.Configuration;
import duell.helpers.TemplateHelper;

import duell.helpers.PathHelper;
import duell.helpers.LogHelper;
import duell.helpers.FileHelper;
import duell.helpers.TestHelper;
import duell.helpers.ProcessHelper;
import duell.helpers.HXCPPConfigXMLHelper;
import duell.helpers.PlatformHelper;
import duell.objects.HXCPPConfigXML;

import duell.objects.DuellLib;
import duell.objects.Haxelib;

import sys.FileSystem;
import haxe.io.Path;

class PlatformBuild
{
	public var requiredSetups = ["android"];
	public static inline var TEST_RESULT_FILENAME = "test_result_android.xml";

	/// VARIABLES SET AFTER PARSING
	var targetDirectory : String;
	var projectDirectory : String;
	var duellBuildAndroidPath : String;
	var fullTestResultPath : String;
	var isDebug : Bool = false;
	var isBuildNDLL : Bool = true;
	var isFullLogcat : Bool = false;
	var isSignedRelease : Bool = false;

	var	adbPath : String;
	var	androidPath : String;
	var	emulatorPath : String;
	var antPath : String;

	public function new() : Void
	{
        checkArguments();

        prepareVars();
	}

	private function prepareVars()
	{
		var hxcppConfig = HXCPPConfigXML.getConfig(HXCPPConfigXMLHelper.getProbableHXCPPConfigLocation());
		var defines : Map<String, String> = hxcppConfig.getDefines();

		if (!defines.exists("ANDROID_SDK"))
			throw "ANDROID_SDK not set in hxcpp config, did you run duell setup android correctly?";

		if (!defines.exists("ANT_HOME"))
			throw "ANT_HOME not set in hxcpp config, did you run duell setup android correctly?";

		Sys.putEnv("ANDROID_SDK", defines.get("ANDROID_SDK"));

		adbPath = Path.join([defines.get("ANDROID_SDK"), "platform-tools"]);
		androidPath = Path.join([defines.get("ANDROID_SDK"), "tools"]);
		emulatorPath = Path.join([defines.get("ANDROID_SDK"), "tools"]);
		antPath = defines.get("ANT_HOME");
	}

	private function checkArguments()
	{	
		for (arg in Sys.args())
		{
			if (arg == "-debug")
			{
				isDebug = true;
			}
			else if (arg == "-nondllbuild")
			{
				isBuildNDLL = false;
			}
			else if (arg == "-fulllogcat")
			{
				isFullLogcat = true;
			}
			else if (arg == "-signedrelease")
			{
				isSignedRelease = true;
			}
		}

		if (isDebug)
		{
			Configuration.addParsingDefine("debug");
		}
		else
		{
			Configuration.addParsingDefine("release");
		}
	}

    public function parse()
    {
		var projectXML = DuellProjectXML.getConfig();
		projectXML.parse();
    }

	/// =========
	/// PREPARE BUILD
	/// =========

    public function prepareBuild()
    {		
    	if (PlatformConfiguration.getData().ARCHS.indexOf("x86") != -1)
    		throw "x86 is not currently supported, its implemented, but currently not functioning well";

    	/// Set variables
		targetDirectory = Path.join([Configuration.getData().OUTPUT, "android"]);
		fullTestResultPath = Path.join([targetDirectory, TEST_RESULT_FILENAME]);
		projectDirectory = Path.join([targetDirectory, "bin"]);
		duellBuildAndroidPath = DuellLib.getDuellLib("duellbuildandroid").getPath();

		/// Additional Configuration
		addHXCPPLibs();
		convertDuellAndHaxelibsIntoHaxeCompilationFlags();
		convertParsingDefinesToCompilationDefines();

		prepareAndroidBuild();		
    }

	private function addHXCPPLibs()
	{
		var binPath = Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "bin"]);
		var buildFilePath = Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "project", "Build.xml"]);

		Configuration.getData().NDLLS.push({NAME : "std", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true});
		Configuration.getData().NDLLS.push({NAME : "regexp", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true});
		Configuration.getData().NDLLS.push({NAME : "zlib", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true});
	}

	private function convertDuellAndHaxelibsIntoHaxeCompilationFlags()
	{
		for (haxelib in Configuration.getData().DEPENDENCIES.HAXELIBS)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + Haxelib.getHaxelib(haxelib.name, haxelib.version).getPath());
		}

		for (duelllib in Configuration.getData().DEPENDENCIES.DUELLLIBS)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + DuellLib.getDuellLib(duelllib.name, duelllib.version).getPath());
		}

		for (path in Configuration.getData().SOURCES)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + path);
		}
	}

    private function convertParsingDefinesToCompilationDefines()
	{		
		for (define in DuellProjectXML.getConfig().parsingConditions)
		{
			if (define == "cpp") /// not allowed
				continue;

			Configuration.getData().HAXE_COMPILE_ARGS.push("-D " + define);
		}
	}

    private function prepareAndroidBuild() : Void
    {
		createDirectoriesAndCopyTemplates();
		handleIcons();
		handleNDLLs();
		handleJavaSources();
		handleJars();
		handleJavaLibs();
    }

    private function createDirectoriesAndCopyTemplates() : Void
    {
		var packageDirectory = Configuration.getData().APP.PACKAGE;
		packageDirectory = Path.join([projectDirectory, "src"].concat(packageDirectory.split(".")));
		PathHelper.mkdir(packageDirectory);

		var originMainActivity = Path.join([duellBuildAndroidPath, "template", "android", "MainActivity.java"]);
		var destMainActivity = Path.join([packageDirectory, "MainActivity.java"]);
		TemplateHelper.copyTemplateFile(originMainActivity, destMainActivity, Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);

		var originProjectTemplate = Path.join([duellBuildAndroidPath, "template", "android", "template"]);
		var destProjectTemplate = projectDirectory;

		TemplateHelper.recursiveCopyTemplatedFiles(originProjectTemplate, destProjectTemplate, Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		
		var originHaxeTemplate = Path.join([duellBuildAndroidPath, "template", "android", "haxe"]);
		var destHaxeTemplate = Path.join([targetDirectory, "haxe"]);
		TemplateHelper.recursiveCopyTemplatedFiles(originHaxeTemplate, destHaxeTemplate, Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
    }

    private function handleIcons()
    {
		if (!FileSystem.exists(PlatformConfiguration.getData().ICON_PATH))
		{
			LogHelper.println('Icon path ${PlatformConfiguration.getData().ICON_PATH} is not accessible.');
			return;
		}

		var iconTypes = [ "ldpi", "mdpi", "hdpi", "xhdpi" ];

		for (icon in iconTypes) 
		{
			var destinationPath = haxe.io.Path.join([projectDirectory, "res", "drawable-" + icon]);
			var iconDestinationPath = haxe.io.Path.join([destinationPath, "icon.png"]);
			var iconOriginPath = haxe.io.Path.join([PlatformConfiguration.getData().ICON_PATH, "drawable-" + icon, "icon.png"]);

			PathHelper.mkdir(destinationPath);

			if(!FileSystem.exists(iconOriginPath))
			{
				LogHelper.println('Icon $icon not found.');
				continue;
			}

			FileHelper.copyIfNewer(iconOriginPath, iconDestinationPath);
		}
    }


	private function handleNDLLs()
	{
		var destFolder = Path.join([projectDirectory, "libs"]);

		for (archID in 0...3) 
		{
			var arch = ["armv6", "armv7", "x86"][archID];

			var argsForBuild = [["-Dandroid"],
								["-Dandroid", "-DHXCPP_ARMV7"],
								["-Dandroid", "-DHXCPP_X86"]][archID];

			if (isDebug)
			{
				argsForBuild.push("-Ddebug");
			}

			var folderName = ["armeabi", "armeabi-v7a", "x86"][archID];

			var extension = [".so", "-v7.so", "-x86.so"][archID];

			var destFolderArch = Path.join([destFolder, folderName]);

			if (Configuration.getData().PLATFORM.ARCHS.indexOf(arch) == -1)
			{
				if (FileSystem.exists(destFolderArch))
				{
					PathHelper.removeDirectory(destFolderArch);
				}
				continue; 
			}
			
			PathHelper.mkdir(destFolderArch);
			
			for (ndll in Configuration.getData().NDLLS) 
			{
				if (isBuildNDLL)
				{
	        		var result = duell.helpers.ProcessHelper.runCommand(Path.directory(ndll.BUILD_FILE_PATH), "haxelib", ["run", "hxcpp", Path.withoutDirectory(ndll.BUILD_FILE_PATH)].concat(argsForBuild));

					if (result != 0)
						LogHelper.error("Problem building ndll " + ndll.NAME);
				}

				copyNDLL(ndll, folderName, argsForBuild, extension);
			}
		}
	}

	private function copyNDLL(ndll : {NAME:String, BIN_PATH:String, BUILD_FILE_PATH:String, REGISTER_STATICS:Bool},
								destFolderName : String, argsForBuild : Array<String>, libExt : String)
	{
		/// Try debug version
		var releaseLib = Path.join([ndll.BIN_PATH, "Android", "lib" + ndll.NAME + libExt]);
		var debugLib = Path.join([ndll.BIN_PATH, "Android", "lib" + ndll.NAME + "-debug" + libExt]);

		/// Doesn't exist, so use the release on as debug
		if (!FileSystem.exists(debugLib))
		{
			debugLib = releaseLib;
		}

		var dest = Path.join([projectDirectory, "libs", destFolderName, "lib" + ndll.NAME + ".so"]);
		
		/// Release doesn't exist so force the extension. Used mainly for trying to compile a armv7 lib without -v7, and universal libs
		if (!isDebug && !FileSystem.exists(releaseLib))
		{
			releaseLib = Path.join([ndll.BIN_PATH, "Android", "lib" + ndll.NAME + ".so"]);
		}
		
		/// Debug doesn't exist so force the extension. Used mainly for trying to compile a armv7 lib without -v7, and universal libs
		if (isDebug && !FileSystem.exists(debugLib)) 
		{
			debugLib = Path.join([ndll.BIN_PATH, "Android", "lib" + ndll.NAME + "-debug" + ".so"]);
		}

		/// Copy!
		if (!isDebug)
		{
			FileHelper.copyIfNewer(releaseLib, dest);
		}
		
		if (isDebug && FileSystem.exists(debugLib) && debugLib != releaseLib) 
		{
			FileHelper.copyIfNewer (debugLib, dest);
		}
	}


	private function handleJars() : Void
	{
		for (jar in PlatformConfiguration.getData().JARS)
		{
			if (jar == "" || !FileSystem.exists(jar))
			{
				throw "Invalid Jar path " + jar;
			}

			FileHelper.copyIfNewer(jar, Path.join([projectDirectory, "libs", Path.withoutDirectory(jar)]));
		}
	}

	private function handleJavaSources() : Void
	{
	    for (javaSource in PlatformConfiguration.getData().JAVA_SOURCES)
		{
			if (javaSource.PATH == "" || !FileSystem.exists(javaSource.PATH))
			{
				throw "Invalid Java Sources path " + javaSource;
			}

			if (FileSystem.isDirectory(javaSource.PATH))
			{
				TemplateHelper.recursiveCopyTemplatedFiles(javaSource.PATH, Path.join([projectDirectory, "src"]), Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
			}
			else
			{
				FileHelper.copyIfNewer(javaSource.PATH, Path.join([projectDirectory, "src", Path.withoutDirectory(javaSource.PATH)]));
			}
		}
	}

	private function handleJavaLibs() : Void
	{
	    for (javaLib in PlatformConfiguration.getData().JAVA_LIBS)
		{
			if (javaLib.PATH == "" || !FileSystem.isDirectory(javaLib.PATH) )
				throw "Invalid Java Lib path! " + javaLib;

			if (!FileSystem.exists(haxe.io.Path.join([javaLib.PATH, "project.properties"])))
				throw "Java Lib path is missing project.properties file. " + javaLib;

			TemplateHelper.recursiveCopyTemplatedFiles(javaLib.PATH, Path.join([projectDirectory, "deps", javaLib.NAME]), Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
		}
	}

	/// =========
	/// BUILD
	/// =========

	public function build()
	{
		buildHaxe();
		runAnt();
	}

	private function buildHaxe()
	{
	    var destFolder = Path.join([projectDirectory, "libs"]);

		for (archID in 0...3) 
		{
			var arch = ["armv6", "armv7", "x86"][archID];

			var argsForBuildCpp = [["-Dandroid"],
								   ["-Dandroid", "-DHXCPP_ARMV7"],
								   ["-Dandroid", "-DHXCPP_X86"]][archID];

            var argsForBuildHaxe = [["-D", "android", "-cpp", "build"],
            						["-D", "android", "-cpp", "build", "-D", "HXCPP_ARMV7"],
            						["-D", "android", "-cpp", "build", "-D", "HXCPP_X86"],
            						][archID];

			if (isDebug)
			{
				argsForBuildCpp.push("-Ddebug");
				argsForBuildHaxe.push("-debug");
			}

			var folderName = ["armeabi", "armeabi-v7a", "x86"][archID];

			var extension = [".so", "-v7.so", "-x86.so"][archID];

			var destFolderArch = Path.join([destFolder, folderName]);

			if (Configuration.getData().PLATFORM.ARCHS.indexOf(arch) == -1)
			{
				if (FileSystem.exists(destFolderArch))
				{
					PathHelper.removeDirectory(destFolderArch);
				}
				continue; 
			}
			
			PathHelper.mkdir(destFolderArch);

			ProcessHelper.runCommand(Path.join([targetDirectory, "haxe"]), "haxe", ["Build.hxml"].concat(argsForBuildHaxe));

    		var result = duell.helpers.ProcessHelper.runCommand(Path.join([targetDirectory, "haxe", "build"]), "haxelib", ["run", "hxcpp", "Build.xml"].concat(argsForBuildCpp));

			if (result != 0)
				throw "Problem building haxe library";
			
			var lib = Path.join([targetDirectory, "haxe", "build", "lib" + Configuration.getData().MAIN + (isDebug ? "-debug" : "") + extension]);
			var dest = Path.join([destFolderArch, "libHaxeApplication.so"]);

			FileHelper.copyIfNewer(lib, dest);
		}
	}

	private function runAnt()
	{
		var ant = Path.join([antPath, "bin", "ant"]);
		
		var build = "debug";
		
		if (isSignedRelease) /// not yet done
		{
			build = "release";
		}
		
		ProcessHelper.runCommand(projectDirectory, ant, [build]);
	}

	/// =========
	/// RUN
	/// =========
	public function run()
	{
		install();
		clearLogcat();
		runActivity();
		runLogcat();
	} 

	private function install()
	{
		var args = ["install", "-r", Path.join([projectDirectory, "bin", Configuration.getData().APP.FILE + "-" + (isSignedRelease ? "release" : "debug") + ".apk"])];
		
		ProcessHelper.runCommand(adbPath, "adb", args);
	}

	private function runActivity()
	{
		var args = ["shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", Configuration.getData().APP.PACKAGE + "/" + Configuration.getData().APP.PACKAGE + "." + "MainActivity"];
		
		ProcessHelper.runCommand(adbPath, "adb", args);
	}

	private function clearLogcat()
	{
		var args = ["logcat"];
		
		ProcessHelper.runCommand(adbPath, "adb", args.concat(["-c"]));
	}

	private function runLogcat()
	{
		var args = ["logcat"];

		if (isFullLogcat) 
		{
			ProcessHelper.runCommand(adbPath, "adb", args);
		} 
		else if (isDebug) 
		{
			var filter = "*:E";
			var includeTags = ["duell", "Main", "DuellActivity", "GLThread", "trace"];
			
			for (tag in includeTags) 
			{
				filter += " " + tag + ":D";
			}
			
			ProcessHelper.runCommand(adbPath, "adb", args.concat([filter]));
		}
		else 
		{
			ProcessHelper.runCommand(adbPath, "adb", args.concat (["*:S trace:I"]));
		}
	}


	public function test()
	{
		neko.vm.Thread.create(run);
		TestHelper.runListenerServer(10, 8181, fullTestResultPath);
	}
}