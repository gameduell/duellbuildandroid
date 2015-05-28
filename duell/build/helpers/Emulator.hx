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

package duell.build.helpers;

import duell.objects.HXCPPConfigXML;
import duell.objects.DuellProcess;

import duell.helpers.LogHelper;
import duell.helpers.PlatformHelper;
import duell.helpers.HXCPPConfigXMLHelper;
import duell.helpers.CommandHelper;

import haxe.io.Path;
enum EmulatorArchitecture
{
	X86;
	ARM;

	/// MIPS not supported
}

@:access(duell.objects.DuellProcess)
class Emulator
{
	private static inline var EMULATOR_IS_RUNNING_TIME_TO_CHECK = 3;
	private static inline var SECONDS_BEFORE_GIVINGUP_ON_EMULATOR_LAUNCHING = 300;
	private var emulatorName: String;
	private var emulatorArchitecture: EmulatorArchitecture;

	private var emulatorProcess: DuellProcess;

	private var portToUse: Int = 0;

	private var adbPath: String;
	private var emulatorPath: String;

	public function new(emulatorName: String, emulatorArchitecture: EmulatorArchitecture = null): Void
	{
		this.emulatorName = emulatorName;
		this.emulatorArchitecture = emulatorArchitecture;

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

		adbKillStartServer();

		var args = ["-avd", emulatorName,
					"-prop", "persist.sys.language=en",
					"-prop", "persist.sys.country=GB",
					"-port", "" + portToUse,
					"-no-snapshot-load", "-no-snapshot-save",
					"-gpu", "on", "-noaudio"];

		var emulator = "emulator";
		var actualEmulatorPath = emulatorPath;
		if (PlatformHelper.hostPlatform == Platform.WINDOWS)
		{
			if (emulatorArchitecture != null)
			{
				switch (emulatorArchitecture)
				{
					case ARM:
						emulator = "../emulator-arm.exe";
						actualEmulatorPath = Path.join([emulatorPath, "lib"]);
					case X86:
						emulator = "../emulator-x86.exe";
						actualEmulatorPath = Path.join([emulatorPath, "lib"]);
					default:
				}
			}
		}

		emulatorProcess = new DuellProcess(
										actualEmulatorPath,
										emulator,
										args,
										{
											timeout : 0,
											logOnlyIfVerbose : true,
											loggingPrefix : "[Emulator]",
											shutdownOnError : false,
											block : false,
											errorMessage : "running emulator",
											systemCommand: false
										});
	}

	private function adbKillStartServer(): Void
	{
		var adbKillServer = new DuellProcess(
							adbPath,
							"adb",
							["kill-server"],
							{
								timeout : 0,
								logOnlyIfVerbose : true,
								loggingPrefix : "[ADB]",
								shutdownOnError : false,
								block : true,
								errorMessage : "restarting adb",
								systemCommand: false
							});

		var adbStartServer = new DuellProcess(
							adbPath,
							"adb",
							["start-server"],
							{
								timeout : 0,
								logOnlyIfVerbose : true,
								loggingPrefix : "[ADB]",
								shutdownOnError : false,
								block : false,
								errorMessage : "restarting adb",
								systemCommand: false
							});
	}

	public function shutdown(): Void
	{
		if (emulatorProcess != null)
			emulatorProcess.kill();
	}

	public function waitUntilReady(): Void
	{

		var timeStarted = haxe.Timer.stamp();

		var argsConnect = ["connect", "localhost:" + portToUse];
		var argsBoot = ["-s", "emulator-" + portToUse, "shell", "getprop", "dev.bootcomplete"];

		var opts = {
			timeout : 0.0,
			mute: false,
			shutdownOnError : false,
			block : true,
			errorMessage : "checking if emulator is connected",
			systemCommand: false
		};

		var alreadyConnected = false;

		var startKillCounter = 10;
		while (true)
		{
			if (!alreadyConnected && startKillCounter == 0)
			{
				adbKillStartServer();
				startKillCounter = 10;
			}
			if (timeStarted + SECONDS_BEFORE_GIVINGUP_ON_EMULATOR_LAUNCHING < haxe.Timer.stamp())
			{
				throw "time out connecting to the emulator";
			}

			LogHelper.info("Trying to connect to the emulator...");

			if (!alreadyConnected)
			{
				new DuellProcess(adbPath, "adb", argsConnect, opts);
			}

			var proc = new DuellProcess(adbPath, "adb", argsBoot, opts);
			var output = proc.getCompleteStdout().toString();
			var outputError = proc.getCompleteStderr().toString();

			if (output.indexOf("1") != -1)
			{
				break;
			}

			if (outputError.indexOf("device not found") != -1)
			{
				alreadyConnected = false;
			}
			else if(outputError.indexOf("device offline") != -1)
			{
				alreadyConnected = false;
			}
			else
			{
				alreadyConnected = true;
			}

			startKillCounter--;
			Sys.sleep(EMULATOR_IS_RUNNING_TIME_TO_CHECK);
		}
	}

	public function waitUntilFinished(): Void
	{
		emulatorProcess.blockUntilFinished();
	}
}
