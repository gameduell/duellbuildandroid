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
import duell.helpers.TemplateHelper;

import duell.helpers.PathHelper;
import duell.helpers.LogHelper;
import duell.helpers.FileHelper;
import duell.helpers.TestHelper;
import duell.helpers.CommandHelper;
import duell.helpers.HXCPPConfigXMLHelper;
import duell.helpers.PlatformHelper;
import duell.objects.HXCPPConfigXML;

import duell.objects.DuellLib;
import duell.objects.Haxelib;
import duell.objects.DuellProcess;
import duell.objects.Arguments;

import duell.build.helpers.Emulator;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

using StringTools;

class PlatformBuild
{
    public var requiredSetups = [{name: "android", version: "4.0.0"}];
    public var supportedHostPlatforms = [LINUX, WINDOWS, MAC];
    private static inline var TEST_RESULT_FILENAME = "test_result_android.xml";
    private static inline var DEFAULT_ARMV7_EMULATOR = "duellarmv7";
    private static inline var DEFAULT_X86_EMULATOR = "duellx86";
    private static inline var DELAY_BETWEEN_PYTHON_LISTENER_AND_RUNNING_THE_APP = 1;

    /// VARIABLES SET AFTER PARSING
    var targetDirectory : String;
    var publishDirectory : String;
    var libsWithSymbolsDirectory : String;
    var projectDirectory : String;
    var duellBuildAndroidPath : String;
    var fullTestResultPath : String;
    var isDebug : Bool = false;
    var isNDKGDB : Bool = false;
    var isVerbose : Bool = false;
    var isBuildNDLL : Bool = true;
    var isFullLogcat : Bool = false;
    var isClean : Bool = false;
    var isEmulator : Bool = false;
    var emulatorName : Null<String> = null;
    var emulatorArch : EmulatorArchitecture = null;

    var	adbPath : String;
    var	androidPath : String;
    var	emulatorPath : String;
    var antPath : String;

    var emulator: Emulator = null;
    var logcatProcess: DuellProcess = null; /// will block here if emulator is not running.

    public function new() : Void {}

    public function parse()
    {
        checkArguments();
        prepareVariablesPreParse();

        var projectXML = DuellProjectXML.getConfig();
        projectXML.parse();
    }

    private function prepareVariablesPreParse()
    {
        var hxcppConfig = HXCPPConfigXML.getConfig(HXCPPConfigXMLHelper.getProbableHXCPPConfigLocation());
        var defines : Map<String, String> = hxcppConfig.getDefines();

        if (!defines.exists("ANDROID_SDK"))
            throw "ANDROID_SDK not set in hxcpp config, did you run duell setup android correctly?";

        if (!defines.exists("ANT_HOME"))
            throw "ANT_HOME not set in hxcpp config, did you run duell setup android correctly?";

        if (!defines.exists("ANDROID_NDK_ROOT"))
            throw "ANDROID_NDK_DIR not set in hxcpp config, did you run duell setup android correctly?";

        Sys.putEnv("ANDROID_SDK", defines.get("ANDROID_SDK"));
        Sys.putEnv("ANDROID_HOME", defines.get("ANDROID_SDK"));

        Configuration.getData().PLATFORM.NDK_PATH = defines.get("ANDROID_NDK_ROOT");

        adbPath = Path.join([defines.get("ANDROID_SDK"), "platform-tools"]);
        androidPath = Path.join([defines.get("ANDROID_SDK"), "tools"]);
        emulatorPath = Path.join([defines.get("ANDROID_SDK"), "tools"]);
        antPath = defines.get("ANT_HOME");
    }

    private function checkArguments()
    {
        if (Arguments.isSet("-debug"))
        {
            isDebug = true;
        }

        if (Arguments.isSet("-ndkgdb"))
        {
            isNDKGDB = true;
        }

        if (Arguments.isSet("-verbose"))
        {
            isVerbose = true;
        }

        if (Arguments.isSet("-proguard"))
        {
            Configuration.getData().PLATFORM.PROGUARD_ENABLED = true;
        }

        var isArmv6 = Arguments.isSet("-armv6");
        var isArmv7 = Arguments.isSet("-armv7");
        var isX86 = Arguments.isSet("-x86");

        if (isArmv7 || isX86)
        {
            Configuration.getData().PLATFORM.ARCHS = [];

            if (isArmv6)
                Configuration.getData().PLATFORM.ARCHS.push("armv6");
            if (isArmv7)
                Configuration.getData().PLATFORM.ARCHS.push("armv7");
            if (isX86)
                Configuration.getData().PLATFORM.ARCHS.push("x86");
        }

        if (Arguments.isSet("-emulator"))
        {
            isEmulator = true;
            if (Arguments.isSet("-emulatorname"))
            {
                emulatorName = Arguments.get("-emulatorname");
            }
            else
            {
                if (isX86)
                {
                    emulatorName = DEFAULT_X86_EMULATOR;
                    emulatorArch = X86;
                }
                else
                {
                    emulatorName = DEFAULT_ARMV7_EMULATOR;
                    emulatorArch = ARM;
                }
            }
        }

        if (Arguments.isSet("-fulllogcat"))
        {
            isFullLogcat = true;
        }

        if (Arguments.isSet("-test"))
        {
            Configuration.addParsingDefine("test");
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

    /// =========
    /// PREPARE BUILD
    /// =========

    public function prepareBuild()
    {
        prepareVariablesPostParse();

        /// Additional Configuration
        startEmulator();
        addHXCPPLibs();
        convertDuellAndHaxelibsIntoHaxeCompilationFlags();
        addArchitectureInfoToHaxeCompilationFlags();
        convertParsingDefinesToCompilationDefines();
        forceDeprecationWarnings();
        gatherProguardConfigs();

        if (isDebug)
            addDebuggingInformation();

        convertArchsToArchABIs();

        prepareAndroidBuild();
    }

    private function prepareVariablesPostParse()
    {
        /// Set variables
        targetDirectory = Path.join([Configuration.getData().OUTPUT, "android"]);
        libsWithSymbolsDirectory = Path.join([targetDirectory, "libswithsym"]);
        publishDirectory = Path.join([Configuration.getData().PUBLISH, "android"]);
        fullTestResultPath = Path.join([Configuration.getData().OUTPUT, "test", TEST_RESULT_FILENAME]);
        projectDirectory = Path.join([targetDirectory, "bin"]);
        duellBuildAndroidPath = DuellLib.getDuellLib("duellbuildandroid").getPath();
    }

    private function gatherProguardConfigs()
    {
        for (proguardFile in Configuration.getData().PLATFORM.PROGUARD_PATHS)
        {
            if (!FileSystem.exists(proguardFile))
            {
                throw "Configured proguard file " + proguardFile + " was not found";
            }
            Configuration.getData().PLATFORM.PROGUARD_CONTENT.push(File.getContent(proguardFile));
        }
    }

    private function addHXCPPLibs()
    {
        var binPath = Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "bin"]);
        var buildFilePath = Path.join([Haxelib.getHaxelib("hxcpp").getPath(), "project", "Build.xml"]);

        Configuration.getData().NDLLS.push({NAME : "std", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true, DEBUG_SUFFIX : false});
        Configuration.getData().NDLLS.push({NAME : "regexp", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true, DEBUG_SUFFIX : false});
        Configuration.getData().NDLLS.push({NAME : "zlib", BIN_PATH : binPath, BUILD_FILE_PATH : buildFilePath, REGISTER_STATICS : true, DEBUG_SUFFIX : false});
    }

    private function convertDuellAndHaxelibsIntoHaxeCompilationFlags()
    {
        for (haxelib in Configuration.getData().DEPENDENCIES.HAXELIBS)
        {
            var version = haxelib.version;
            if (version.startsWith("ssh") || version.startsWith("http"))
                version = "git";
            Configuration.getData().HAXE_COMPILE_ARGS.push("-lib " + haxelib.name + (version != "" ? ":" + version : ""));
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

    private function forceDeprecationWarnings(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push("-D deprecation-warnings");
    }

    private function addDebuggingInformation()
    {
        Configuration.getData().PLATFORM.APPLICATION_PARAMETERS.push({NAME : "debuggable", VALUE : "true"});
        Configuration.getData().HAXE_COMPILE_ARGS.push("-debug");
        Configuration.getData().PLATFORM.DEBUG = true;
    }

    private function convertArchsToArchABIs()
    {
        for (arch in Configuration.getData().PLATFORM.ARCHS)
        {
            switch (arch)
            {
                case "armv6":
                    Configuration.getData().PLATFORM.ARCH_ABIS.push("armeabi");
                case "armv7":
                    Configuration.getData().PLATFORM.ARCH_ABIS.push("armeabi-v7a");
                case "x86":
                    Configuration.getData().PLATFORM.ARCH_ABIS.push("x86");
            }
        }
    }

    private function addArchitectureInfoToHaxeCompilationFlags()
    {
        for (arch in Configuration.getData().PLATFORM.ARCHS)
        {
            switch (arch)
            {
                case "armv6":
                case "armv7":
                    Configuration.getData().HAXE_COMPILE_ARGS.push("-D HXCPP_ARMV7");
                case "x86":
                    Configuration.getData().HAXE_COMPILE_ARGS.push("-D HXCPP_X86");
            }
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

		var iconTypes = [ "ldpi", "mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi" ];

        for (iconType in iconTypes)
        {
            var iconOriginPath = haxe.io.Path.join([PlatformConfiguration.getData().ICON_PATH, 'drawable-$iconType']);
            var iconDestinationPath = haxe.io.Path.join([projectDirectory, "res", 'drawable-$iconType']);

            PathHelper.mkdir(iconDestinationPath);

            if (!FileSystem.exists(iconOriginPath))
            {
                LogHelper.println('Icon type "$iconType" not found.');
                continue;
            }

            FileHelper.recursiveCopyFiles(iconOriginPath, iconDestinationPath);
        }
    }


    private function handleNDLLs()
    {
        for (archID in 0...3)
        {
            var arch = ["armv6", "armv7", "x86"][archID];

            var argsForBuild = [["-Dandroid", "-DHXCPP_FULL_DEBUG_LINK", "-Dnostrip"],
                                ["-Dandroid", "-DHXCPP_FULL_DEBUG_LINK", "-Dnostrip", "-DHXCPP_ARMV7"],
                                ["-Dandroid", "-DHXCPP_FULL_DEBUG_LINK", "-Dnostrip", "-DHXCPP_X86"]][archID];

            if (isDebug)
            {
                argsForBuild.push("-Ddebug");

            }

            var folderName = ["armeabi", "armeabi-v7a", "x86"][archID];

            var extension = [".so", "-v7.so", "-x86.so"][archID];

            var destFolderArch = Path.join([libsWithSymbolsDirectory, folderName]);

            /// clear if the architecture is not to be built now
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
                    var result = CommandHelper.runHaxelib(Path.directory(ndll.BUILD_FILE_PATH), ["run", "hxcpp", Path.withoutDirectory(ndll.BUILD_FILE_PATH)].concat(argsForBuild), {errorMessage: "building ndll"});

                    if (result != 0)
                        throw "Problem building ndll " + ndll.NAME;
                }

                copyNDLL(ndll, folderName, argsForBuild, extension);
            }
        }
    }

    private function copyNDLL(ndll : {NAME:String, BIN_PATH:String, BUILD_FILE_PATH:String, REGISTER_STATICS:Bool, DEBUG_SUFFIX:Bool},
                                destFolderName : String, argsForBuild : Array<String>, libExt : String)
    {
        /// if there is no suffix, tbe release version might be used.
        var debugSuffix = ndll.DEBUG_SUFFIX? "-debug": "";

        /// Try debug version
        var releaseLib = Path.join([ndll.BIN_PATH, "Android", "lib" + ndll.NAME + libExt]);
        var debugLib = Path.join([ndll.BIN_PATH, "Android", "lib" + ndll.NAME + debugSuffix + libExt]);

        /// Doesn't exist, so use the release on as debug
        if (!FileSystem.exists(debugLib))
        {
            debugLib = releaseLib;
        }

        var dest = Path.join([libsWithSymbolsDirectory, destFolderName, "lib" + ndll.NAME + ".so"]);

        /// Release doesn't exist so force the extension. Used mainly for trying to compile a armv7 lib without -v7, and universal libs
        if (!isDebug && !FileSystem.exists(releaseLib))
        {
            releaseLib = Path.join([ndll.BIN_PATH, "Android", "lib" + ndll.NAME + ".so"]);
        }

        /// Debug doesn't exist so force the extension. Used mainly for trying to compile a armv7 lib without -v7, and universal libs
        if (isDebug && !FileSystem.exists(debugLib))
        {
            debugLib = Path.join([ndll.BIN_PATH, "Android", "lib" + ndll.NAME + debugSuffix + ".so"]);
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


        /// Copy!
        if (!isDebug)
        {
            if (!FileSystem.exists(releaseLib))
            {
                throw "Could not find release lib for ndll" + ndll.NAME + " built with build file " + ndll.BUILD_FILE_PATH + " and having output folder " + ndll.BIN_PATH;
            }

            FileHelper.copyIfNewer(releaseLib, dest);
        }
        else
        {
            if (!FileSystem.exists(debugLib))
            {
                throw "Could not find release lib for ndll" + ndll.NAME + " built with build file " + ndll.BUILD_FILE_PATH + " and having output folder " + ndll.BIN_PATH;
            }

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

            /// Make sure the libs folder is there
            var libsDirectoryPath: String = Path.join([projectDirectory, "deps", javaLib.NAME, "libs"]);
            if(!FileSystem.exists(libsDirectoryPath) && javaLib.PROVIDED.length > 0)
            {
                PathHelper.mkdir(libsDirectoryPath);
            }
            /// Handling Provided jars
            for (providedItem  in  javaLib.PROVIDED)
            {
                var providedSrcPath: String = Path.join([projectDirectory, "libs", providedItem]);
                var providedDestPath: String = Path.join([libsDirectoryPath, providedItem]);
                if(FileSystem.exists(providedSrcPath))
                {
                    FileHelper.copyIfNewer(providedSrcPath,providedDestPath);
                }
                else
                {
                    throw 'Ivalid jar path $providedItem, provided for java-lib ${javaLib.NAME}';
                }
            }
        }
    }


    /// =========
    ///	EMULATOR
    /// =========

    public function startEmulator()
    {
        if (!isEmulator)
            return;

        emulator = new Emulator(emulatorName, emulatorArch);
        emulator.start();
    }

    public function waitForEmulatorReady()
    {
        if (!isEmulator)
            return;

        emulator.waitUntilReady();
    }

    public function waitForEmulatorFinished()
    {
        if (!isEmulator)
            return;

        emulator.waitUntilFinished();
    }

    public function shutdownEmulator()
    {
        if (!isEmulator)
            return;

        if (emulator == null)
            return;

        emulator.shutdown();
    }

    /// =========
    /// BUILD
    /// =========

    public function build()
    {
        buildHaxe();
        copyLibs();
        stripSymbols();
        runAnt();
    }

    private function buildHaxe()
    {
        var args: Array<String> = ["Build.hxml"];

        CommandHelper.runHaxe(Path.join([targetDirectory, "haxe"]), args, {errorMessage: "compiling the haxe code into c++"});

        for (archID in 0...3)
        {
            var arch = ["armv6", "armv7", "x86"][archID];

            var argsForBuildCpp = [["-Dandroid", "-DHXCPP_FULL_DEBUG_LINK", "-Dnostrip"],
                                   ["-Dandroid", "-DHXCPP_FULL_DEBUG_LINK", "-Dnostrip", "-DHXCPP_ARMV7"],
                                   ["-Dandroid", "-DHXCPP_FULL_DEBUG_LINK", "-Dnostrip", "-DHXCPP_X86"]][archID];

            argsForBuildCpp = argsForBuildCpp.concat(Configuration.getData().PLATFORM.HXCPP_COMPILATION_ARGS);


            var folderName = ["armeabi", "armeabi-v7a", "x86"][archID];

            var extension = [".so", "-v7.so", "-x86.so"][archID];

            var destFolderArch = Path.join([libsWithSymbolsDirectory, folderName]);

            /// clear if the architecture is not to be built now
            if (Configuration.getData().PLATFORM.ARCHS.indexOf(arch) == -1)
            {
                if (FileSystem.exists(destFolderArch))
                {
                    PathHelper.removeDirectory(destFolderArch);
                }
                continue;
            }

            PathHelper.mkdir(destFolderArch);


            var gdbSetupOrig = Path.join([duellBuildAndroidPath, "template", "android", "gdb.setup"]);
            var gdbSetupDest = Path.join([destFolderArch, "gdb.setup"]);

            var gdbServerPath = ["android-arm", "android-arm", "android-x86"][archID];
            var gdbServerOrigPath = Path.join([Configuration.getData().PLATFORM.NDK_PATH, "prebuilt", gdbServerPath, "gdbserver", "gdbserver"]);
            var gdbServerDestPath = Path.join([destFolderArch, "gdbserver"]);

            if (isDebug)
            {
                argsForBuildCpp.push("-Ddebug");
                FileHelper.copyIfNewer(gdbServerOrigPath,
                                       gdbServerDestPath);

                TemplateHelper.copyTemplateFile(gdbSetupOrig,
                                                gdbSetupDest,
                                                Configuration.getData(),
                                                Configuration.getData().TEMPLATE_FUNCTIONS);
            }
            else
            {
                if (FileSystem.exists(gdbServerDestPath))
                {
                    FileSystem.deleteFile(gdbServerDestPath);
                }
                if (FileSystem.exists(gdbSetupDest))
                {
                    FileSystem.deleteFile(gdbSetupDest);
                }
            }


            CommandHelper.runHaxelib(Path.join([targetDirectory, "haxe", "build"]), ["run", "hxcpp", "Build.xml"].concat(argsForBuildCpp), {errorMessage: "compiling the generated c++ code"});

            var lib = Path.join([targetDirectory, "haxe", "build", "lib" + Configuration.getData().MAIN + (isDebug ? "-debug" : "") + extension]);
            var dest = Path.join([destFolderArch, "libHaxeApplication.so"]);

            FileHelper.copyIfNewer(lib, dest);
        }
    }

    private function copyLibs()
    {
        var finalPathOfLibs = Path.join([projectDirectory, "libs"]);
        if (!FileSystem.exists(finalPathOfLibs))
        {
                PathHelper.mkdir(finalPathOfLibs);
        }

        FileHelper.recursiveCopyFiles(libsWithSymbolsDirectory, finalPathOfLibs);
    }

    private function stripSymbols()
    {
        if (!Arguments.isSet("-stripsym"))
            return;

        var finalPathOfLibs = Path.join([projectDirectory, "libs"]);
        var host = "darwin-x86";

        if (PlatformHelper.hostPlatform == Platform.WINDOWS)
        {
            host = "windows";
        }
        else if(PlatformHelper.hostPlatform == Platform.LINUX)
        {
            host = "linux-x86";
        }

        var ndkRoot = Configuration.getData().PLATFORM.NDK_PATH;

        for (archID in 0...3)
        {
            var arch = ["armv6", "armv7", "x86"][archID];
            var toolchain = ["arm-linux-androideabi-4.8", "arm-linux-androideabi-4.8", "x86-4.8"] [archID];
            var stripperExe = ["arm-linux-androideabi-strip", "arm-linux-androideabi-strip", "i686-linux-android-strip"] [archID];
            var folderName = ["armeabi", "armeabi-v7a", "x86"][archID];

            var basePathForExe = Path.join([ndkRoot, "toolchains", toolchain, "prebuilt", host, "bin"]);

            var abiPath = Path.join([finalPathOfLibs, folderName]);

            if (FileSystem.exists(abiPath))
            {
                var libsOfAbi = PathHelper.getRecursiveFileListUnderFolder(abiPath);

                for (lib in libsOfAbi)
                {
                    var abi = Path.join([abiPath, lib]);

                    if (abi.endsWith(".so"))
                    {
                        LogHelper.info("stripping symbols of " + abi);
                        CommandHelper.runCommand(basePathForExe, stripperExe, [abi], {systemCommand:false});
                    }
                }
            }
        }
    }

    private function runAnt()
    {
        var ant = Path.join([antPath, "bin", "ant"]);

        var build = "release";

        if (isDebug)
        {
            build = "debug";
        }

        var args: Array<String> = [build];

        if (isVerbose)
        {
            args.push("-v");
        }

        CommandHelper.runCommand(projectDirectory, ant, args, {errorMessage: "compiling the .apk"});
    }

    /// =========
    /// RUN
    /// =========
    public function run()
    {
        waitForEmulatorReady();

        install();
        clearLogcat();

        if (!isNDKGDB)
        {
            runActivity();
            runLogcat();

            if (isEmulator)
            {
                waitForEmulatorFinished();
            }
            else
            {
                logcatProcess.blockUntilFinished();
            }
        }
        else
        {
            runNDKGDB();
            shutdownEmulator();
        }
    }

    private function install()
    {
        var args = ["install", "-r", Path.join([projectDirectory, "bin", Configuration.getData().APP.FILE + "-" + (isDebug ? "debug" : "release") + ".apk"])];
        LogHelper.info("Installing with '" + "adb " + args.join(" ") + "'");
        var adbProcess = new DuellProcess(
                                        adbPath,
                                        "adb",
                                        args,
                                        {
                                            timeout : 300,
                                            logOnlyIfVerbose : false,
                                            shutdownOnError : true,
                                            block : true,
                                            errorMessage : "installing on device"
                                        });
    }

    private function runActivity()
    {
        var args = ["shell", "am", "start", "-a", "android.intent.action.MAIN", "-n", Configuration.getData().APP.PACKAGE + "/" + Configuration.getData().APP.PACKAGE + "." + "MainActivity"];

        var adbProcess = new DuellProcess(
                                        adbPath,
                                        "adb",
                                        args,
                                        {
                                            timeout : 60,
                                            logOnlyIfVerbose : false,
                                            shutdownOnError : true,
                                            block : true,
                                            errorMessage : "running the app on the device"
                                        });
    }

    private function clearLogcat()
    {
        var args = ["logcat"];

        var adbProcess = new DuellProcess(
                                        adbPath,
                                        "adb",
                                        args.concat(["-c"]),
                                        {
                                            logOnlyIfVerbose : false,
                                            shutdownOnError : true,
                                            block : true,
                                            errorMessage : "clearing logcat"
                                        });
    }

    private function runLogcat()
    {
        var args = ["logcat"];


        if (!isFullLogcat)
        {
            var filter = "*:E";
            var includeTags = ["duell", "Main", "DuellActivity", "GLThread", "trace"];

            for (tag in includeTags)
            {
                filter += " " + tag + ":D";
            }
            args = args.concat([filter]);
        }


        logcatProcess = new DuellProcess(
                                        adbPath,
                                        "adb",
                                        args,
                                        {
                                            logOnlyIfVerbose : false,
                                            loggingPrefix: "[LOGCAT]",
                                            errorMessage : "running logcat"
                                        });
    }

    private function runNDKGDB()
    {

        CommandHelper.runCommand(projectDirectory,
                                 "sh",
                                 [Path.join([Configuration.getData().PLATFORM.NDK_PATH ,"ndk-gdb"]),
                                 "--project=" + projectDirectory, "--verbose", "--start", "--force"],
                                 {
                                    errorMessage: "running ndk-gdb",
                                    systemCommand: true
                                 });
    }

    /// =========
    /// TEST
    /// =========
    public function test()
    {
        waitForEmulatorReady();

        /// DELETE PREVIOUS TEST
        if (sys.FileSystem.exists(fullTestResultPath))
        {
            sys.FileSystem.deleteFile(fullTestResultPath);
        }

        /// CREATE TARGET FOLDER
        PathHelper.mkdir(Path.directory(fullTestResultPath));

        /// RUN THE APP
        install();
        duell.helpers.ThreadHelper.runInAThread(function()
            {
                Sys.sleep(DELAY_BETWEEN_PYTHON_LISTENER_AND_RUNNING_THE_APP);
                runActivity();
            }
        );

        /**
        * TODO: Find a better/central place for the hardcoded fallback port 8181
        *       which is intended fall back on if the duell-tool's configuration
        *       does not provide the TEST_PORT property (backward-compatibility).
        *       Remove eventually...
        **/
        var testPort:Int = untyped Configuration.getData().TEST_PORT == null ?
            8181 : Configuration.getData().TEST_PORT;

        /// RUN THE LISTENER
        TestHelper.runListenerServer(300, testPort, fullTestResultPath);

        shutdownEmulator();
    }

    /// =========
    /// PUBLISH
    /// =========
    public function publish()
    {
        // remove the old publish android folder
        if (FileSystem.exists(publishDirectory))
        {
            PathHelper.removeDirectory(publishDirectory);
        }

        // create the publish part for android
        PathHelper.mkdir(publishDirectory);

        var binaryName: String = Configuration.getData().APP.FILE + "-" + (isDebug ? "debug" : "release") + ".apk";
        var outputFile: String = Path.join([projectDirectory, "bin", binaryName]);
        var destinationFile: String = Path.join([publishDirectory, '${Configuration.getData().APP.FILE}.apk']);

        FileHelper.copyIfNewer(outputFile, destinationFile);

        // update the published paths so that the plugins can operate on postPublish
        Configuration.getData().PLATFORM.PUBLISHED_APK_PATH = destinationFile;

        // run proguard on the resulting file and update PUBLISHED_MAPPING_PATH
        if (Configuration.getData().PLATFORM.PROGUARD_ENABLED)
        {
            Configuration.getData().PLATFORM.PUBLISHED_MAPPING_PATH = Path.join([projectDirectory, "bin", "proguard", "mapping.txt"]);
        }
    }

    /// =========
    /// FAST
    /// =========
    public function fast()
    {
        startEmulator();
        prepareVariablesPostParse();
        build();

        if (Arguments.isSet("-test"))
            test()
        else
            run();
    }

    /// =========
    /// CLEAN
    /// =========

    public function clean()
    {
        prepareVariablesPostParse();
        addHXCPPLibs();

        LogHelper.info('Cleaning android part of export folder...');

        if (FileSystem.exists(targetDirectory))
        {
            PathHelper.removeDirectory(targetDirectory);
        }

        for (ndll in Configuration.getData().NDLLS)
        {
            LogHelper.info('Cleaning ndll ' + ndll.NAME + "...");
            var result = CommandHelper.runHaxelib(Path.directory(ndll.BUILD_FILE_PATH), ["run", "hxcpp", Path.withoutDirectory(ndll.BUILD_FILE_PATH), "clean"], {errorMessage: "cleaning ndll"});

            if (result != 0)
                throw "Problem cleaning ndll " + ndll.NAME;

            var destFolder = Path.join([ndll.BIN_PATH, "Android"]);
            if (FileSystem.exists(destFolder))
            {
                PathHelper.removeDirectory(destFolder);
            }
        }
    }

    /// =========
    /// HANDLE ERROR
    /// =========

    public function handleError()
    {
        shutdownEmulator();
    }
}
