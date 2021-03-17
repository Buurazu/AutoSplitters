//NOT A HERO IL autosplitter
//and full-game too i guess

state("NOT A HERO", "Steam")
{
//fulltime begins counting as soon as you start loading a level, as well as during many other screens
int FULLTIME : 0x46EB5C;
//These timers I found seem to pause at odd times (like during Kimmy's katana, or while a pipebomb is out)
//there's many of them and I figure whichever is the highest should be fine
int LEVELTIME2 : 0x46EF3C;
int LEVELTIME3 : 0x46EFB4;
int LEVELTIME4 : 0x46F46C;
int LEVELTIME  : 0x46F530;
byte ONLEVELCLEAR : 0x46ED54;
//i hope these pointers don't break.
//well, worst case scenario it doesn't autoreset on THE SHOOTORIAL, just like before I found this
string255 LEVELNAME : 0x4A50D8, 0;
}

state("NOT A HERO", "Humble Bundle")
{
//fulltime begins counting as soon as you start loading a level, as well as during many other screens
int FULLTIME : 0x3C8B6C;
//These timers I found seem to pause at odd times (like during Kimmy's katana, or while a pipebomb is out)
//there's many of them and I figure whichever is the highest should be fine
int LEVELTIME2 : 0x3C9058;
int LEVELTIME3 : 0x3C90F0;
int LEVELTIME4 : 0x3C9154;
int LEVELTIME  : 0x3C94E8;
byte ONLEVELCLEAR : 0x3C8D81;
string255 LEVELNAME : 0x3F97DC, 0, 0;
}

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	vars.startFrame = 0;
	//used to keep track of IL splits during a full game run, enabling us to rewind if splits are undone
	vars.elapsedGameTime = new int[30];
	//in the time between stages, we don't want to display elapsed time + level time, only elapsed time
	vars.justBeatLevel = false;
	//used to reset the elapsedGameTime array after resets
	vars.haveSplit = false;
	
	
	settings.Add("tutorialreset",true,"Auto-Reset on The Shootorial");
	settings.SetToolTip("tutorialreset","If checked, full-game runs will automatically reset upon starting The Shootorial");
	settings.Add("tutorialstart",true,"Start Only on The Shootorial");
	settings.SetToolTip("tutorialstart","If checked, full-game runs will only start when you play The Shootorial, otherwise the timer starts upon starting any level");
	
	// Taken from https://github.com/tduva/LiveSplit-ASL/blob/master/AlanWake.asl
	// Based on: https://github.com/NoTeefy/LiveSnips/blob/master/src/snippets/checksum(hashing)/checksum.asl
	Func<ProcessModuleWow64Safe, string> CalcModuleHash = (module) => {
		print("Calcuating hash of "+module.FileName);
		byte[] exeHashBytes = new byte[0];
		using (var sha = System.Security.Cryptography.MD5.Create())
		{
			using (var s = File.Open(module.FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
			{
				exeHashBytes = sha.ComputeHash(s);
			}
		}
		var hash = exeHashBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
		print("Hash: "+hash.ToString());
		return hash;
	};
	vars.CalcModuleHash = CalcModuleHash;
}

init {
	var module = modules.Single(x => String.Equals(x.ModuleName, "NOT A HERO.exe", StringComparison.OrdinalIgnoreCase));
	var moduleSize = module.ModuleMemorySize;
	print("Module Size: "+moduleSize.ToString()+" "+module.ModuleName);
	string hash = vars.CalcModuleHash(module);

	switch (hash){
        case "70AE1D0664F561939177171B43A037D6": version = "Steam"; break;
        case "95548EFC333A021FA4476206A714C245": version = "Humble Bundle"; break;
        default: version = "Unknown"; break;
    }
}

update
{
	//print(current.LEVELNAME + "," + current.FULLTIME.ToString() + "," + vars.startFrame.ToString());
	//probably dumb way to get the maximum value out of the four level time variables
	string debugstr = "";
	vars.maxTime = current.LEVELTIME; debugstr += vars.maxTime.ToString() + ",";
	vars.maxTime = Math.Max(vars.maxTime, current.LEVELTIME2); debugstr += vars.maxTime.ToString() + ",";
	vars.maxTime = Math.Max(vars.maxTime, current.LEVELTIME3); debugstr += vars.maxTime.ToString() + ",";
	vars.maxTime = Math.Max(vars.maxTime, current.LEVELTIME4); debugstr += vars.maxTime.ToString() + ",";
	//print(debugstr);
	
	//reset IL timer on game relaunch
	if (current.LEVELTIME == 0 && current.FULLTIME > 0 && old.FULLTIME == 0) {
		if (vars.timerModel.CurrentState.Run.Count == 1) {
			vars.timerModel.Reset();
		}
	}
	//reset ILs (and full-game if THE SHOOTORIAL), and start full-game timer, as soon as the "load" screen begins
	//note: full-game can't start here if you've yet to load a level (current and old.LEVELTIME == 0)
	//can't find a good way around that
	if (current.LEVELTIME == 0 && old.LEVELTIME != 0)
	{
		vars.startFrame = 0;
		if (vars.timerModel.CurrentState.Run.Count == 1 ||
		(settings["tutorialreset"] && current.LEVELNAME == "THE SHOOTORIAL")) {
			vars.timerModel.Reset();
		}
		if (vars.timerModel.CurrentState.Run.Count > 1 && settings.StartEnabled) {
			if ((settings["tutorialstart"] && current.LEVELNAME == "THE SHOOTORIAL") || !settings["tutorialstart"])
				vars.timerModel.Start();
		}
	}
	//the timer starts counting up during the "load" screen, but is frozen at 0 until the level appears
	//so it starts at 100ish frames. subtract that starting value from the time
	//it's in update instead of start because the startFrame needs to be set during fullgame
	if (current.LEVELTIME != 0 && old.LEVELTIME == 0)
	{
		vars.justBeatLevel = false;
		vars.startFrame = current.LEVELTIME;
		if (vars.timerModel.CurrentState.Run.Count == 1 && settings.StartEnabled) {
			vars.timerModel.Start();
		}
	}
}

start
{	
	//dumb way to have this reset only when the timer hasn't started
	if (vars.haveSplit == true) {
		vars.haveSplit = false;
		vars.elapsedGameTime = new int[30];
	}
}

split
{
	//with just LEVELTIME, you can't tell the difference between a restart and a completed stage
	//the easiest way I could find is this other address that equals 1 during the post-level screen and (hopefully) doesn't equal 1 otherwise
	//this also happens to be a good time to split in full-game
	if (current.ONLEVELCLEAR == 1 && old.ONLEVELCLEAR != 1)
	{
		int splitNum = vars.timerModel.CurrentState.CurrentSplitIndex;
		vars.elapsedGameTime[splitNum+1] = vars.elapsedGameTime[splitNum] + (vars.maxTime-vars.startFrame);
		vars.justBeatLevel = true;
		vars.haveSplit = true;
		return true;
	}
}

gameTime
{
	int splitNum = vars.timerModel.CurrentState.CurrentSplitIndex;
	if (vars.justBeatLevel == true) {
		return TimeSpan.FromSeconds(vars.elapsedGameTime[splitNum]/60f);
	}
	else {
		return TimeSpan.FromSeconds((vars.elapsedGameTime[splitNum]+vars.maxTime-vars.startFrame)/60f);
	}
}

isLoading
{
	return true;
}
