package org.haxe.duell;

public interface MainHaxeThreadHandler
{
	void queueRunnableOnMainHaxeThread(Runnable queue);
}