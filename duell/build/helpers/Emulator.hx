package duell.build.helpers;

import duell.objects.DuellProcess;
import duell.helpers.LogHelper;

import duell.helpers.HXCPPConfigXMLHelper;
import duell.objects.HXCPPConfigXML;

import haxe.io.Path;

class Emulator
{
	private static inline var EMULATOR_IS_RUNNING_TIME_TO_CHECK = 1;
	private static inline var SECONDS_BEFORE_GIVINGUP_ON_EMULATOR_LAUNCHING = 300;
	private var emulatorName: String;

	private var emulatorProcess: DuellProcess;

	private var portToUse: Int = 0;

	private var adbPath: String;
	private var emulatorPath: String;

	public function new(emulatorName: String): Void
	{
		this.emulatorName = emulatorName;

		var hxcppConfig = HXCPPConfigXML.getConfig(HXCPPConfigXMLHelper.getProbableHXCPPConfigLocation());
		var defines : Map<String, String> = hxcppConfig.getDefines();
		adbPath = Path.join([defines.get("ANDROID_SDK"), "platform-tools"]);
		emulatorPath = Path.join([defines.get("ANDROID_SDK"), "tools"]);
	}

	public function start(): Void
	{
		portToUse = 5554 + Std.random(125);

		if (portToUse % 2 > 0)
		{
			portToUse += 1;
		}

		var args = ["-avd", emulatorName,
					"-prop", "persist.sys.language=en",
					"-prop", "persist.sys.country=GB",
					"-port", "" + portToUse,
					"-no-snapshot-load", "-no-snapshot-save",
					"-gpu", "on", "-noaudio"];

		emulatorProcess = new DuellProcess(
										emulatorPath,
										"emulator",
										args,
										{
											timeout : 0,
											logOnlyIfVerbose : true,
											loggingPrefix : "[Emulator]",
											shutdownOnError : true,
											block : false,
											errorMessage : "running emulator",
											systemCommand: false
										});
	}

	public function shutdown(): Void
	{
		emulatorProcess.kill();
	}

	public function waitUntilReady(): Void
	{

		var timeStarted = haxe.Timer.stamp();

		var args = ["-s", "emulator-" + portToUse, "shell", "getprop", "dev.bootcomplete"];

		var opts = {
			timeout : 0.0,
			mute: true,
			shutdownOnError : false,
			block : true,
			errorMessage : "checking if emulator is connected",
			systemCommand: false
		};

		while (true)
		{
			if (timeStarted + SECONDS_BEFORE_GIVINGUP_ON_EMULATOR_LAUNCHING < haxe.Timer.stamp())
			{
				LogHelper.error("time out connecting to the emulator");
			}
			var output = new DuellProcess(adbPath, "adb", args, opts).getCompleteStdout().toString();

			if (output.indexOf("1") != -1)
			{
				break;
			}
			Sys.sleep(EMULATOR_IS_RUNNING_TIME_TO_CHECK);
		}
	}

	public function waitUntilFinished(): Void
	{
		emulatorProcess.blockUntilFinished();
	}
}
