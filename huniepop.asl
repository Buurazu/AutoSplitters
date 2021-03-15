//HuniePop AutoSplitter
//created by RShields and Buurazu

//DO NOT USE THIS FOR 100%, for obvious reasons (like not knowing how many dates it will be, and possibly closing the game midway)

state("HuniePop")
{
}

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	settings.Add("resetonexit",true,"Reset on Game Exit");
	settings.SetToolTip("resetonexit","Disable this if you want to be able to relaunch the game without a reset (like for fixing route mistakes / undoing a failed date)");
}

init
{
	vars.version = -1;
	vars.modVarLoc = 0;
	vars.gameManagerLoc = 0;
	vars.gameStageLoc = 0;
	
	vars.prevCDA = 0;
	vars.prevInteractive = false;
	vars.prevVar = 123456789;
	
	vars.watchForVenus = true;
	vars.venusCounter = 0;
	
	vars.search = (Action<SigScanTarget, string>) ((theTarget, name) => {
		foreach (var page in memory.MemoryPages())
		{
			var bytes = memory.ReadBytes(page.BaseAddress, (int)page.RegionSize);
			if (bytes == null)
				continue;
			
			var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
			vars.addr = scanner.Scan(theTarget); 

			if (vars.addr != IntPtr.Zero)
			{
				print(name + " found at 0x" + vars.addr.ToString("X"));
				break;
			}
		}
	});
	
	SigScanTarget target;
	
	//Locate the GameManager location
	while (vars.gameManagerLoc == 0) {
		target = new SigScanTarget(0, "55 8B EC 83 EC 08 8B 05 ?? ?? ?? ?? 85 C0 75 29 83 EC 0C 68 ?? ?? ?? ?? E8 ?? ?? ?? ?? 83 C4 10 83 EC 0C 89 45 FC 50 E8 ?? ?? ?? ?? 83 C4 10 8B 4D FC B8 ?? ?? ?? ?? 89 08 8B 05 ?? ?? ?? ?? C9 C3");
		vars.search(target,"Game Manager");
		
		vars.gameManagerLoc = memory.ReadValue<int>((IntPtr)((int)vars.addr + 8));
	}
	
	//Locate the Stage, so we can check if the LoadScreen is interactive
	while (vars.gameStageLoc == 0) {
		target = new SigScanTarget(0, "55 8B EC 83 EC 08 8B 05 ?? ?? ?? ?? 83 EC 08 6A 00 50 E8 ?? ?? ?? ?? 83 C4 10 85");
		vars.search(target,"Stage");
		
		vars.gameStageLoc = memory.ReadValue<int>((IntPtr)((int)vars.addr + 8));
	}
	
	//Check for Valentine's Patch's SaveUtils.Init function to determine the version of the game
	//Jan 23
	target = new SigScanTarget(0, "55 8B EC 83 EC 08 B8 ?? ?? ?? ?? C6 00 01 E8 ?? ?? ?? ?? 83 EC 08 68 ?? ?? ?? ?? 50 E8 ?? ?? ?? ??");
	//Valentines
	//var target = new SigScanTarget(0, "55 8B EC 83 EC 18 C7 45 FC 00 00 00 00 C7 45 F8 00 00 00 00 B8 58 1E 17 06 C6 00 01 B8 5C 1E 17 06");
	vars.search(target,"SaveUtils");
	
	if (vars.addr != IntPtr.Zero) vars.version = 0;
	else { print("no Jan 23 saveutils found"); vars.version = 1; }
	
	//we don't want to freeze forever searching for HunieMod if they don't have it, so just check once
	//Locate HunieMod's BasePatches.InitSearchForMe
	//123456789 = new launch
	target = new SigScanTarget(0, "B8 ?? ?? ?? ?? C7 00 15 CD 5B 07 C3");
	vars.search(target,"HunieMod");
	
	vars.modVarLoc = memory.ReadValue<int>((IntPtr)((int)vars.addr + 1));
}

start
{	
	//HunieMod is running
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		//111 = new game just started
		if (theVar == 111) return true;
	}
	//HunieMod is not running; check if the LoadScreen is interactive instead
	//note that this starts splits on file load too, but that's not really a bad thing
	else {
		//offsets (same across versions)
		var UIToffset = 0xA0;
		var TSoffset = 0x80;
		var LSoffset = 0xD0;
		var Ioffset = 0x78;
		
		var stage = memory.ReadValue<int>((IntPtr)vars.gameStageLoc);
		if (stage == 0) return;
		var uiTitle = memory.ReadValue<int>((IntPtr)(stage + (int)UIToffset));
		var titleScreen = memory.ReadValue<int>((IntPtr)(uiTitle + (int)TSoffset));
		var loadScreen = memory.ReadValue<int>((IntPtr)(titleScreen + (int)LSoffset));
		var interactive = memory.ReadValue<bool>((IntPtr)(loadScreen + (int)Ioffset));
		
		if (interactive == false && vars.prevInteractive == true) {
			vars.prevInteractive = interactive;
			return true;
		}
		vars.prevInteractive = interactive;
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
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		//-111 = return to main menu
		if (theVar == -111 && vars.prevVar != -111) {
			vars.prevVar = theVar;
			return true;
		}
	}
}

split
{
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		//100 = puzzle completed
		if (theVar == 100 && vars.prevVar != 100) {
			vars.prevVar = theVar;
			return true;
		}
		//check for Unlock Venus end
		if (theVar == 500 && vars.prevVar != 500) {
			vars.prevVar = theVar;
			return true;
		}
		vars.prevVar = theVar;
	}
	else {
		//if no HunieMod, check for the puzzle's current displayed affection
		//offsets for Valentine's Patch
		var PMoffset = 0x2C;	//Puzzle Manager
		var Poffset = 0x40;		//Puzzle
		var CDAoffset = 0xC4;	//Current Display Affection
		var GAoffset = 0xA4;	//Goal Affection
		var Voffset = 0x90;
		var BRoffset = 0x7C;
		
		var LMoffset = 0x10;	//Location Manager
		var CGoffset = 0x18;	//Current Girl
		var IDoffset = 0x10;	//Girl ID
		//offsets for Jan. 23 Patch
		if (vars.version == 0) {
			Poffset = 0x3C;
			CDAoffset = 0xBC;
			GAoffset = 0xA0;
			Voffset = 0x8C;
			BRoffset = 0x7C;
		}
		
		var gameManager = memory.ReadValue<int>((IntPtr)vars.gameManagerLoc);
		if (gameManager == 0) return;
		var puzzleManager = memory.ReadValue<int>((IntPtr)(gameManager + (int)PMoffset));
		var puzzle = memory.ReadValue<int>((IntPtr)(puzzleManager + (int)Poffset));
		
		var currentDisplayAffection = memory.ReadValue<int>((IntPtr)(puzzle + (int)CDAoffset));
		var goalAffection = memory.ReadValue<int>((IntPtr)(puzzle + (int)GAoffset));
		var victory = memory.ReadValue<bool>((IntPtr)(puzzle + (int)Voffset));
		var isBonusRound = memory.ReadValue<bool>((IntPtr)(puzzle + (int)BRoffset));
		
		if ((currentDisplayAffection == goalAffection) && vars.prevCDA != currentDisplayAffection)
		{
			if (victory || isBonusRound) {
				vars.prevCDA = currentDisplayAffection;
				return true;
			}
		}
		//DO NOT update prevCDA if we're at max affection but haven't reached victory yet
		else vars.prevCDA = currentDisplayAffection;
		
		//check for Unlock Venus ending
		//NOTE: if you exit and relaunch the game in late-game of All Panties, there will be false positives with Venus
		if (vars.venusCounter > 0) {
			vars.venusCounter--;
			if (vars.venusCounter == 0) return true;
		}
		var locationManager = memory.ReadValue<int>((IntPtr)(gameManager + (int)LMoffset));
		var currentGirl = memory.ReadValue<int>((IntPtr)(locationManager + (int)CGoffset));
		var girlID = memory.ReadValue<int>((IntPtr)(currentGirl + (int)IDoffset));
		
		//disable Venus splitting if Celeste or Momo have been seen
		if (girlID == 10 || girlID == 11) {
			vars.watchForVenus = false;
		}
		if (vars.watchForVenus && girlID == 12) {
			//split a couple frames after Venus is set as current girl, if we're watching for her
			vars.watchForVenus = false;
			vars.venusCounter = 5;
		}
		
	}
}
