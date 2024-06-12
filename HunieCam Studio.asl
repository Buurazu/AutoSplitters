//HunieCam Studio Autosplitter
//created by Buurazu

//The HunieCam Speedrun Mod is required, sorry.
//Doesn't split on 100%

state("HunieCamStudio")
{

}

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	settings.Add("daysplits",true,"Split after Each Day");
	settings.SetToolTip("daysplits","The autosplitter will split at midnight each day");
	settings.Add("trophysplits",false,"Split after Each Trophy Milestone");
	settings.SetToolTip("trophysplits","The autosplitter will split at 5,000, 10,000, 25,000, 50,000, and 100,000 fans");
	settings.Add("splitnamesplits",true,"Split on Trophy/Fan Count Split Names");
	settings.SetToolTip("splitnamesplits","The autosplitter will split on specific fan counts by checking the FIRST WORD of the current split name for either a number (ex. '50,000 Fans') or trophy type (ex. 'Platinum Trophy')");
	settings.Add("platinumlast",false,"Last Split = Platinum Trophy");
	settings.SetToolTip("platinumlast","The autosplitter will split at 50,000 fans if it's the last split (so you can name it whatever)");
	
	settings.Add("resetonexit",true,"Reset on Game Exit");
	settings.SetToolTip("resetonexit","Disable this if you want to be able to relaunch the game without a reset");
	settings.Add("resetonnewgame",true,"Reset on New Game");
	settings.SetToolTip("resetonnewgame","Disable this if you want to be able to start a new game mid-run without a reset (for 100%?)");
	
	vars.trophyNames = new string[] { "bronze", "silver", "gold", "platinum", "diamond" };
	vars.trophyNums = new int[] { 5000, 10000, 25000, 50000, 100000 };
}

init
{	
	vars.search = (Action<SigScanTarget, string>) ((theTarget, name) => {
		foreach (var page in memory.MemoryPages())
		{
			var bytes = memory.ReadBytes(page.BaseAddress, (int)page.RegionSize);
			//if (bytes == null || (int)page.RegionSize != 65536)
			//	continue;
			
			var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
			vars.addr = scanner.Scan(theTarget); 

			if (vars.addr != IntPtr.Zero)
			{
				print(name + " found at 0x" + vars.addr.ToString("X"));
				//print(page.BaseAddress.ToString());
				//print(page.RegionSize.ToString());
				break;
			}
		}
	});
	
	
	vars.prevVar = 123456789;
	vars.currentDay = 1;
	vars.prevDay = 1;
	vars.currentFans = 0;
	vars.prevFans = 0;
	vars.runSaveFile = -1;
	vars.dontReset = false;
	
	vars.modVarLoc = 0;
	SigScanTarget target;
	
	//check if the mod is running by seeing if the doorstop config is present, and HP2SpeedrunMod.dll is present
	//deleting either are good ways to temporarily disable running the mod
	if (File.Exists(Path.Combine(game.MainModule.FileName, @"..\doorstop_config.ini")) &&
		File.Exists(Path.Combine(game.MainModule.FileName, @"..\BepInEx\plugins\HuniecamSpeedrunMod\HuniecamSpeedrunMod.dll"))) {
		//Locate BasePatches.InitSearchForMe
		//123456789 = new launch
		var attempts = 0;
		//Search for the base game if mod isn't found yet (game loading)
			print("Searching for mod...");
			target = new SigScanTarget(0, "B8 ?? ?? ?? ?? C7 00 14 CD 5B 07");
			vars.search(target,"HCSR");
			vars.modVarLoc = memory.ReadValue<int>((IntPtr)(vars.addr + 1));
		vars.gameManagerLoc = 0;
		while (vars.gameManagerLoc == 0 && vars.modVarLoc == 0) {
			print("Searching for base game...");
			target = new SigScanTarget(0, "55 8B EC 57 83 EC 04 8B 7D 08 C6 47 44 01 C6 47 45 00 C6 47 46 00 D9 EE D9 5F 48 D9 EE D9 5F 4C C7 47 40 02 00 00 00 8D 65 FC 5F C9 C3");
			vars.search(target,"Game:StartTitleScreen");
			vars.gameManagerLoc = memory.ReadValue<int>((IntPtr)(vars.addr));
		}
		while (vars.modVarLoc == 0 && attempts < 20) {
			print("Searching for mod...");
			attempts++;
			target = new SigScanTarget(0, "B8 ?? ?? ?? ?? C7 00 14 CD 5B 07");
			vars.search(target,"HCSR");
			vars.modVarLoc = memory.ReadValue<int>((IntPtr)(vars.addr + 1));
		}
		
		if (vars.modVarLoc != 0) {
			print("Mod found!");
		}
	}
}

start
{	
	//Speedrun Mod is running
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		var theFile = memory.ReadValue<int>((IntPtr)vars.modVarLoc+12);
		//123 = new game just started, Kyu is talking
		if (theVar == 123) {
			vars.runSaveFile = theFile;
			vars.currentDay = 1;
			vars.prevDay = 1;
			vars.currentFans = 0;
			vars.prevFans = 0;
			return true;
		}
	}
}

exit
{
	if (settings["resetonexit"]) vars.timerModel.Reset();
}

reset
{
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		//reset our run's save file on new game (for 100%)
		if (theVar == 111) vars.runSaveFile = -1;
		if (theVar == 111 && settings["resetonnewgame"]) {
			return true;
		}
	}
}

split
{
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		var theFile = memory.ReadValue<int>((IntPtr)vars.modVarLoc+12);
		if (vars.runSaveFile == -1 && theVar == 123) vars.runSaveFile = theFile;
		if (vars.runSaveFile == -1 || theFile != vars.runSaveFile || theVar == 111) return;
		
		vars.prevDay = vars.currentDay;
		vars.currentDay = memory.ReadValue<int>((IntPtr)vars.modVarLoc+4);
		vars.prevFans = vars.currentFans;
		vars.currentFans = memory.ReadValue<int>((IntPtr)vars.modVarLoc+8);
		
		var currentSplitName = vars.timerModel.CurrentState.CurrentSplit.Name;
		var currentSplit = vars.timerModel.CurrentState.CurrentSplitIndex;
		
		//final split = platinum
		if (settings["platinumlast"] && currentSplit == vars.timerModel.CurrentState.Run.Count-1 && vars.currentFans >= 50000 && vars.prevFans < 50000) {
			return true;
		}
		
		if (settings["splitnamesplits"]) {
			//check what the first word of the split name is
			var firstWord = currentSplitName.Split(' ')[0].Replace(",", "").ToLower();
			int target;
			//check for numbers
			if (Int32.TryParse(firstWord, out target)) {
				if (vars.currentFans >= target && vars.prevFans < target) {
					return true;
				}
			}
			//check for trophy words
			else {
				for (int i = 0; i < 5; i++) {
					if (firstWord == vars.trophyNames[i] && vars.currentFans >= vars.trophyNums[i] && vars.prevFans < vars.trophyNums[i]) {
						return true;
					}
				}
			}
		}
		
		if (settings["trophysplits"]) {
			for (int i = 0; i < 5; i++) {
				if (vars.currentFans >= vars.trophyNums[i] && vars.prevFans < vars.trophyNums[i]) {
					return true;
				}
			}
		}
		
		if (settings["daysplits"]) {
			if (vars.currentDay > vars.prevDay) {
				return true;
			}
		}
		
	}
	return;
}
