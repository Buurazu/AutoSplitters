//HuniePop 2: Double Date AutoSplitter
//created by Buurazu and RShields

//The HuniePop 2 Speedrun Mod is recommended (and has a built-in timer that can handle route variance and non-Wing categories!)
//But this works fine with the vanilla game for any Wing-based categories

//Game._manager : "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0;
//Game._session : "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x8;

state("HuniePop 2 - Double Date", "1.1.0")
{
	long session			: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x8;
	
	int displayAffection	: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x50, 0x68, 0xB0, 0x80, 0x98, 0x94;
	int goalAffection		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x50, 0x68, 0xB0, 0x80, 0x98, 0x9C;
	int victory				: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x50, 0x68, 0x90, 0x184;
	
	bool isBonusRound		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x8, 0x60, 0x170, 0x51;
	bool puzzleActive		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x8, 0x60, 0x190;
	bool titleCanvas		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x50, 0x68, 0x38;
	bool loadingGame		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x50, 0x68, 0x98;
	bool unloadingGame		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x50, 0x68, 0xF2;
	bool cellOpen			: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x50, 0x68, 0xB0, 0xE6;

}
state("HuniePop 2 - Double Date", "1.0.2")
{
	long session			: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x8;
	
	int displayAffection	: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x48, 0x68, 0xB0, 0x80, 0x98, 0x94;
	int goalAffection		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x48, 0x68, 0xB0, 0x80, 0x98, 0x9C;
	int victory				: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x48, 0x68, 0x90, 0x184;
	
	bool isBonusRound		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x8, 0x60, 0x178, 0x51;
	bool puzzleActive		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x8, 0x60, 0x198;
	bool titleCanvas		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x48, 0x68, 0x38;
	bool loadingGame		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x48, 0x68, 0x98;
	bool unloadingGame		: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x48, 0x68, 0xF2;
	bool cellOpen			: "mono-2.0-bdwgc.dll", 0x00493A90, 0xDD8, 0x0, 0x1B0, 0x120, 0x0, 0x48, 0x68, 0xB0, 0xE6;

}


startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	settings.Add("dateonly",true,"Split after Dates");
	settings.Add("bonusroundonly",true,"Split after Bonus Rounds");
	settings.Add("resetonexit",true,"Reset on Game Exit");
	settings.SetToolTip("resetonexit","Disable this if you want to be able to relaunch the game without a reset (like for undoing a failed date)");
	settings.Add("resetonreturn",true,"Reset on Return to Menu");
	settings.SetToolTip("resetonreturn","Disable this if you want to be able to return to main menu without a reset (like for fixing route/shopping mistakes)");
}

init
{
	//file size check by Ero
	string AsmCsPath = Path.Combine(game.MainModule.FileName, @"..\HuniePop 2 - Double Date_Data\Managed\Assembly-CSharp.dll");
	long AsmCsSize = new FileInfo(AsmCsPath).Length;
	
	print("AssemblyCSharp size: " + AsmCsSize.ToString());
	switch (AsmCsSize)
	{
		case 633856: version = "1.0.2"; break;
		case 644608: version = "1.1.0"; break;
		default: version = "Unknown"; break;
	}
	
	//check if the mod is running by seeing if the doorstop config is present, and HP2SpeedrunMod.dll is present
	//deleting either are good ways to temporarily disable running the mod
	/*if (File.Exists(Path.Combine(game.MainModule.FileName, @"..\doorstop_config.ini")) &&
		File.Exists(Path.Combine(game.MainModule.FileName, @"..\BepInEx\plugins\HP2SpeedrunMod\HP2SpeedrunMod.dll"))) {
		//version = version + " Modded";
	}*/
	//ended up not being necessary in HP2
	
	vars.prevSession = 0;
}

start
{	
	//Check if Game.Manager.Ui.currentCanvas._loadingGame = true
	if (current.titleCanvas == true && current.loadingGame == true) {
		vars.prevSession = current.session;
		print(vars.prevSession.ToString("X"));
		return true;
	}
}

exit
{
	if (settings["resetonexit"]) vars.timerModel.Reset();
}

reset
{
	//check if Game.Manager.Ui.currentCanvas._unloadingGame is true
	if (settings["resetonreturn"]) {
		if (current.titleCanvas == true && current.titleCanvas != old.titleCanvas) {
			return true;
		}
		
		if (current.session != vars.prevSession) {
			if (current.titleCanvas == false && current.unloadingGame == true) {
				return true;
			}
		}
	}
}

split
{
	//only check for splits once our new Game.Session has loaded
	if (current.session != vars.prevSession) {
		if (current.titleCanvas == false && current.puzzleActive == true && current.cellOpen == false) {
			if (current.goalAffection > 100 && current.displayAffection == current.goalAffection) {
				//Bonus rounds split the frame that display affection = goal affection
				if (settings["bonusroundonly"] && current.isBonusRound && current.displayAffection != old.displayAffection) {
					return true;
				}
				//Dates have to wait until victory is confirmed, due to potential... uh... switching off Nora?
				if (settings["dateonly"] && !current.isBonusRound && current.victory == 1 &&
					(current.victory != old.victory || current.displayAffection != old.displayAffection)) {
					return true;
				}
			}
		}
	}
}
