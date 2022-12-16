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

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	settings.Add("dateonly",true,"Split after Dates");
	settings.Add("bonusroundonly",true,"Split after Bonus Rounds");
	settings.Add("resetonexit",true,"Reset on Game Exit");
	settings.SetToolTip("resetonexit","Disable this if you want to be able to relaunch the game without a reset (like for undoing a failed date)");
	settings.Add("resetonreturn",true,"Reset on Return to Menu");
	settings.SetToolTip("resetonreturn","Disable this if you want to be able to return to main menu without a reset (like for fixing route/shopping mistakes)");
	
	settings.Add("autorenamesplits", false, "Auto-Rename Split After Splitting");
	settings.SetToolTip("autorenamesplits", "The autosplitter will dynamically set your split name after a split to the girl pair dated (works with Speedrun Mod only)");
	
	string[] girlNames = new string[] {"Lola & Abia", "Lola & Nora", "Candace & Nora", "Ashley & Polly", "Lillian & Ashley", "Lillian & Zoey", "Sarah & Lailani", "Jessie & Lailani", "Jessie & Brooke", "Lola & Jessie", "Lola & Zoey", "Jessie & Abia", "Lillian & Lailani", "Lillian & Abia", "Zoey & Sarah", "Zoey & Polly", "Sarah & Nora", "Sarah & Brooke", "Lailani & Candace", "Candace & Abia", "Candace & Polly", "Nora & Ashley", "Brooke & Ashley", "Brooke & Polly", "Moxie & Jewn", "Kyu & Lola"};
	
	Action<int,string> RenameSplit = (girlID,dateName) => {
		string girlName = girlNames[girlID-1];
		vars.timerModel.CurrentState.CurrentSplit.Name = girlName + " " + dateName;
	};
	vars.RenameSplit = RenameSplit;
	
}

init
{
	//file size check by Ero
	/*
	string AsmCsPath = Path.Combine(game.MainModule.FileName, @"..\HuniePop 2 - Double Date_Data\Managed\Assembly-CSharp.dll");
	long AsmCsSize = new FileInfo(AsmCsPath).Length;
	
	print("AssemblyCSharp size: " + AsmCsSize.ToString());
	switch (AsmCsSize)
	{
		case 633856: version = "1.0.2"; break;
		case 644608: version = "1.1.0"; break;
		default: version = "Unknown"; break;
	}
	*/
	
	vars.search = (Action<SigScanTarget, string>) ((theTarget, name) => {
		foreach (var page in memory.MemoryPages())
		{
			var bytes = memory.ReadBytes(page.BaseAddress, (int)page.RegionSize);
			if (bytes == null || (int)page.RegionSize != 65536)
				continue;
			
			var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
			vars.addr = scanner.Scan(theTarget); 

			if (vars.addr != IntPtr.Zero)
			{
				print(name + " found at 0x" + vars.addr.ToString("X"));
				print(page.BaseAddress.ToString());
				print(page.RegionSize.ToString());
				break;
			}
		}
	});
	
	version = "1.1.0"; //only version we care about as of 12/16/2022
	
	vars.modded = false;
	vars.prevVar = 123456789;
	vars.modVarLoc = 0;
	SigScanTarget target;
	
	//check if the mod is running by seeing if the doorstop config is present, and HP2SpeedrunMod.dll is present
	//deleting either are good ways to temporarily disable running the mod
	if (File.Exists(Path.Combine(game.MainModule.FileName, @"..\doorstop_config.ini")) &&
		File.Exists(Path.Combine(game.MainModule.FileName, @"..\BepInEx\plugins\HP2SpeedrunMod\HP2SpeedrunMod.dll"))) {
		//Locate HP2SR's BasePatches.InitSearchForMe
		//123456789 = new launch
		vars.gameManagerLoc = 0;
		var attempts = 0;
		//Search for the mod, then for base game if mod isn't found yet (game loading)
		while (vars.modVarLoc == 0) {
			target = new SigScanTarget(0, "B8 ?? ?? ?? ?? ?? ?? ?? ?? C7 00 15 CD 5B 07");
			vars.search(target,"HP2SR");
			vars.modVarLoc = memory.ReadValue<long>((IntPtr)((long)vars.addr + 1));
		}
		while (vars.gameManagerLoc == 0 && vars.modVarLoc == 0) {
			target = new SigScanTarget(0, "55 48 8B EC 48 83 EC 30 48 89 4D F8 48 B8 ?? ?? ?? ?? ?? ?? ?? ?? 48 8B 08 33 D2 66 66 90 49 BB ?? ?? ?? ?? ?? ?? ?? ?? 41 FF D3 85 C0");
			vars.search(target,"Game:set_Manager");
			break;
		}
		while (vars.modVarLoc == 0 && attempts < 2) {
			attempts++;
			target = new SigScanTarget(0, "B8 ?? ?? ?? ?? ?? ?? ?? ?? C7 00 15 CD 5B 07");
			vars.search(target,"HP2SR");
			vars.modVarLoc = memory.ReadValue<long>((IntPtr)((long)vars.addr + 1));
		}
		version = version + " Modded";
		vars.modded = true;
		print("Mod found");
	}
	
	vars.prevSession = 0;
}

start
{	
	//Speedrun Mod is running
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		//111 = new game just started
		if (theVar == 111) return true;
	}
	//Check if Game.Manager.Ui.currentCanvas._loadingGame = true
	else if (current.titleCanvas == true && current.loadingGame == true) {
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
	//return to main menu = reset
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		//-111 = return to main menu hotkey
		if (theVar == -111 && vars.prevVar != -111) {
			vars.prevVar = theVar;
			return true;
		}
		if (settings["resetonreturn"] && theVar == -112 && vars.prevVar != -112) {
			vars.prevVar = theVar;
			return true;
		}
	}
	//check if Game.Manager.Ui.currentCanvas._unloadingGame is true
	else if (settings["resetonreturn"]) {
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
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		var thePair = memory.ReadValue<int>((IntPtr)vars.modVarLoc+4);
		var theNum = memory.ReadValue<int>((IntPtr)vars.modVarLoc+8);
		//100 = puzzle completed
		if (theVar == 100 && vars.prevVar != 100 && settings["dateonly"]) {
			vars.prevVar = theVar;
			if (settings["autorenamesplits"]) vars.RenameSplit(thePair, "#" + theNum);
			return true;
		}
		//200 = bonus round completed
		if (theVar == 200 && vars.prevVar != 200 && settings["bonusroundonly"]) {
			vars.prevVar = theVar;
			if (settings["autorenamesplits"]) vars.RenameSplit(thePair, "Bonus");
			return true;
		}
		vars.prevVar = theVar;
	}
	//only check for splits once our new Game.Session has loaded
	else if (current.session != vars.prevSession) {
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
