//HuniePop AutoSplitter
//created by RShields and Buurazu

//DO NOT USE THIS FOR 100%, for obvious reasons (like not knowing how many dates it will be, and possibly closing the game midway)

//_gameManager : "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0;
//_stage : "mono.dll", 0x00209554, 0x10, 0x5A4, 0xC;

//bool interactive		: "HuniePop.exe", 0x00959154, 0x68, 0x27C, 0x68, 0x14, 0xA0, 0x80, 0xD0, 0x78;

state("HuniePop", "Jan. 23")
{
	int displayAffection	: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x3C, 0xBC;
	int goalAffection		: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x3C, 0xA0;
	bool victory			: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x3C, 0x8C;
	bool isBonusRound		: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x3C, 0x7C;
	int girlID				: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x10, 0x18, 0x10;
	
	bool interactive		: "mono.dll", 0x00209554, 0x10, 0x154, 0xC, 0xA0, 0x80, 0xD0, 0x78;
}

state("HuniePop", "Valentine's")
{
	int displayAffection	: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x40, 0xC4;
	int goalAffection		: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x40, 0xA4;
	bool victory			: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x40, 0x90;
	bool isBonusRound		: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x40, 0x7C;
	int girlID				: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x10, 0x18, 0x10;
	
	bool interactive		: "mono.dll", 0x00209554, 0x10, 0x154, 0xC, 0xA0, 0x80, 0xD0, 0x78;
}

state("HuniePop", "Jan. 23 Modded")
{
	int displayAffection	: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x3C, 0xBC;
	int goalAffection		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x3C, 0xA0;
	bool victory			: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x3C, 0x8C;
	bool isBonusRound		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x3C, 0x7C;
	int girlID				: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x10, 0x18, 0x10;
	
	bool interactive		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0xC, 0xA0, 0x80, 0xD0, 0x78;
}

state("HuniePop", "Valentine's Modded")
{
	int displayAffection	: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x40, 0xC4;
	int goalAffection		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x40, 0xA4;
	bool victory			: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x40, 0x90;
	bool isBonusRound		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x40, 0x7C;
	int girlID				: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x10, 0x18, 0x10;
	
	bool interactive		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0xC, 0xA0, 0x80, 0xD0, 0x78;
}

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	settings.Add("resetonexit",true,"Reset on Game Exit");
	settings.SetToolTip("resetonexit","Disable this if you want to be able to relaunch the game without a reset (like for fixing route mistakes / undoing a failed date)");
}

init
{
	//file size check by Ero
	string AsmCsPath = Path.Combine(game.MainModule.FileName, @"..\HuniePop_Data\Managed\Assembly-CSharp.dll");
	long AsmCsSize = new FileInfo(AsmCsPath).Length;
	
	print("AssemblyCSharp size: " + AsmCsSize.ToString());
	switch (AsmCsSize)
	{
		case 576512: version = "Jan. 23"; break;
		case 591360: version = "Valentine's"; break;
		default: version = "Unknown"; break;
	}
	
	//check if the mod is running by seeing if the doorstop config is present, and HunieMod.dll is present
	//deleting either are good ways to temporarily disable running the mod
	if (File.Exists(Path.Combine(game.MainModule.FileName, @"..\doorstop_config.ini")) &&
		File.Exists(Path.Combine(game.MainModule.FileName, @"..\BepInEx\plugins\HunieMod\HunieMod.dll"))) {
		version = version + " Modded";
		//if (version == "Jan. 23") version = "Jan. 23 Modded";
		//if (version == "Valentine's") version = "Valentine's Modded";
	}
	
	vars.watchForVenus = true;
	vars.venusCounter = 0;
}

start
{	
	//check if the LoadScreen is interactive
	//note that this starts splits on file load too, but that's not really a bad thing
	if (current.interactive == false && old.interactive == true) {
			return true;
	}
}

exit
{
	//exiting the game = reset
	if (settings["resetonexit"]) vars.timerModel.Reset();
}

reset
{
	//return to main menu = reset
	//there's no way the title screen would ever be interactive again without the mod
	if (current.interactive == true && old.interactive == false) {
		return true;
	}
}

split
{
	if (current.displayAffection == current.goalAffection) {
		//Bonus rounds split the frame that display affection = goal affection
		if (current.isBonusRound && current.displayAffection != old.displayAffection) {
			return true;
		}
		//Dates have to wait until victory is confirmed, due to potential Broken Heart matches
		if (!current.isBonusRound && current.victory && (current.victory != old.victory || current.displayAffection != old.displayAffection)) {
			return true;
		}
	}
	
	//check for Unlock Venus ending
	//NOTE: if you exit and relaunch the game in late-game of All Panties, there may be false positives with Venus
	if (vars.venusCounter > 0) {
		vars.venusCounter--;
		if (vars.venusCounter == 0) return true;
	}
	
	//disable Venus splitting if Celeste or Momo have been seen
	if (current.girlID == 10 || current.girlID == 11) {
		vars.watchForVenus = false;
	}
	if (vars.watchForVenus && current.girlID == 12) {
		//split a couple frames after Venus is set as current girl, if we're watching for her. it's not scientific but w/e
		vars.watchForVenus = false;
		vars.venusCounter = 5;
	}
}
