//HuniePop 2: Double Date AutoSplitter
//created by Buurazu and RShields

//The HuniePop 2 Speedrun Mod is recommended (and has a built-in timer that can handle route variance and non-Wing categories!)
//But this works fine with the vanilla game for any Wing-based categories

state("HuniePop 2 - Double Date")
{
}

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	settings.Add("dateonly",true,"Split after Dates");
	settings.Add("bonusroundonly",true,"Split after Bonus Rounds");
	settings.Add("resetonexit",true,"Reset on Game Exit");
	settings.SetToolTip("resetonexit","Disable this if you want to be able to relaunch the game without a reset (like for undoing a failed date)");
	settings.Add("resetonreturn",true,"Reset on Return to Menu");
	settings.SetToolTip("resetonreturn","Disable this if you want to be able to return to main menu without a reset (like for fixing route/shopping mistakes) (Doesn't apply to the speedrun mod return hotkey)");
}

init
{
	vars.version = -1;
	vars.modVarLoc = 0;
	vars.gameManagerLoc = 0;
	vars.gameSessionLoc = 0;
	
	vars.prevCDA = 0;
	vars.prevVar = 123456789;
	
	vars.prevSession = 0;
	
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
	
	//Locate Game.Manager, which also finds us Game.Session
	while (vars.gameManagerLoc == 0) {
		//target = new SigScanTarget(0, "48 83 EC 08 48 89 0C 24 48 B8 ?? ?? ?? ?? ?? ?? ?? ?? 48 8B 00 48 8B C8 83 39 00 48 8B 40 48 83 38 00");
		//target = new SigScanTarget(0, "55 48 8B EC 48 83 EC 70 48 89 75 F0 48 89 7D F8 48 8B F1 48 B8 ?? ?? ?? ?? ?? ?? ?? ?? 48 8B 00 48 8B C8 48 8B D6 83 38 00 48 8D 64 24 00");
		target = new SigScanTarget(0, "55 48 8B EC 48 83 EC 30 48 89 4D F8 48 B8 ?? ?? ?? ?? ?? ?? ?? ?? 48 8B 08 33 D2 66 66 90 49 BB ?? ?? ?? ?? ?? ?? ?? ?? 41 FF D3 85 C0");
		vars.search(target,"Game:set_Manager");
		vars.gameManagerLoc = memory.ReadValue<long>((IntPtr)((long)vars.addr + 14));
		vars.gameSessionLoc = vars.gameManagerLoc + 8;
		//now if the version offset changes between versions, that'd be awkward
		var VERSIONoffset = 0x28;
		var gameManager = memory.ReadValue<long>((IntPtr)vars.gameManagerLoc);
		var versionStringLoc = memory.ReadValue<long>((IntPtr)(gameManager + (long)VERSIONoffset));
		vars.version = memory.ReadString((IntPtr)(versionStringLoc + 0x14), 10);
	}
	
	//Locate HP2SR's BasePatches.InitSearchForMe
	//123456789 = new launch
	var attempts = 0;
	while (vars.modVarLoc == 0 && attempts < 2) {
		attempts++;
		print(attempts.ToString());
		target = new SigScanTarget(0, "B8 ?? ?? ?? ?? ?? ?? ?? ?? C7 00 15 CD 5B 07");
		vars.search(target,"HP2SR");
		vars.modVarLoc = memory.ReadValue<long>((IntPtr)((long)vars.addr + 1));
	}
	

}

start
{	
	//HunieMod is running
	if (vars.modVarLoc != 0 && false) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		//111 = new game just started
		if (theVar == 111) return true;
	}
	//Check if Game.Manager.Ui.currentCanvas._loadingGame = true
	else {
		var UIMANAGERoffset = 0x48;
		var CANVASoffset = 0x68;
		var TCoffset = 0x38; //isTitleCanvas bool
		var LGoffset = 0x98; //_loadingGame bool (UiTitleCanvas only)
		if (vars.version == "1.0.5") {
			//achievement update shifted the uimanager down
			UIMANAGERoffset = 0x50;
		}
		
		var gameManager = memory.ReadValue<long>((IntPtr)vars.gameManagerLoc);
		var uiManager = memory.ReadValue<long>((IntPtr)(gameManager + (long)UIMANAGERoffset));
		var canvas = memory.ReadValue<long>((IntPtr)(uiManager + (long)CANVASoffset));
		var titleCanvas = memory.ReadValue<bool>((IntPtr)(canvas + (long)TCoffset));
		var loadingGame = memory.ReadValue<bool>((IntPtr)(canvas + (long)LGoffset));
		if (titleCanvas == true && loadingGame == true) {
			vars.prevSession = memory.ReadValue<long>((IntPtr)vars.gameSessionLoc);
			print(vars.prevSession.ToString());
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
		var UIMANAGERoffset = 0x48;
		var CANVASoffset = 0x68;
		var TCoffset = 0x38; //isTitleCanvas bool
		var UGoffset = 0xF2; //_unloadingGame bool (UiGameCanvas only)
		if (vars.version == "1.0.5") {
			//achievement update shifted the uimanager down
			UIMANAGERoffset = 0x50;
		}
		
		//only check for resets once our new Game.Session has loaded
		var session = memory.ReadValue<long>((IntPtr)vars.gameSessionLoc);
		if (session != vars.prevSession) {
			var gameManager = memory.ReadValue<long>((IntPtr)vars.gameManagerLoc);		
			var uiManager = memory.ReadValue<long>((IntPtr)(gameManager + (long)UIMANAGERoffset));
			var canvas = memory.ReadValue<long>((IntPtr)(uiManager + (long)CANVASoffset));
			var titleCanvas = memory.ReadValue<bool>((IntPtr)(canvas + (long)TCoffset));
			var unloadingGame = memory.ReadValue<bool>((IntPtr)(canvas + (long)UGoffset));
			if (titleCanvas == false && unloadingGame == true) {
				return true;
			}
		}
	}
}

split
{
	if (vars.modVarLoc != 0) {
		var theVar = memory.ReadValue<int>((IntPtr)vars.modVarLoc);
		//100 = puzzle completed
		if (theVar == 100 && vars.prevVar != 100 && settings["dateonly"]) {
			vars.prevVar = theVar;
			return true;
		}
		//200 = bonus round completed
		if (theVar == 200 && vars.prevVar != 200 && settings["bonusroundonly"]) {
			vars.prevVar = theVar;
			return true;
		}
		vars.prevVar = theVar;
	}
	
	else {
		var UIMANAGERoffset = 0x48;
		var CANVASoffset = 0x68;
		var TCoffset = 0x38; //isTitleCanvas bool
		var GRIDoffset = 0x90; //UiGameCanvas.puzzleGrid
		var ROUNDSTATEoffset = 0x184; //UiPuzzleGrid._roundState
		var CELLoffset = 0xB0; //UiGameCanvas.cellphone
		var ISOPENoffset = 0xE6; //UiCellphone._isOpen
		var APPoffset = 0x80; //UiCellphone._currentApp
		var AFFMETERoffset = 0x98; //UiCellphoneAppStatus.affectionMeter
		var CURRAFFoffset = 0x94; //MeterRollerBehavior._currentValue
		var MAXAFFoffset = 0x9C; //MeterRollerBehavior._maxValue
		
		var PUZZoffset = 0x60; //GameSession._puzzle
		var PUZZSTAToffset = 0x178; //PuzzleManager._puzzleStatus
		var BONUSoffset = 0x51; //PuzzleStatus._bonusRound
		
		var PUZZACTIVEoffset = 0x198; //PuzzleManager._isPuzzleActive
		
		if (vars.version == "1.0.5") {
			//achievement update shifted the uimanager down
			UIMANAGERoffset = 0x50;
		}
		
		//only check for splits once our new Game.Session has loaded
		var session = memory.ReadValue<long>((IntPtr)vars.gameSessionLoc);
		if (session != vars.prevSession) {
			
			var puzzleManager = memory.ReadValue<long>((IntPtr)(session + (long)PUZZoffset));
			var puzzleActive = memory.ReadValue<bool>((IntPtr)(puzzleManager + (long)PUZZACTIVEoffset));
			var puzzleStatus = memory.ReadValue<long>((IntPtr)(puzzleManager + (long)PUZZSTAToffset));
			var isBonusRound = memory.ReadValue<bool>((IntPtr)(puzzleStatus + (long)BONUSoffset));
			
			var gameManager = memory.ReadValue<long>((IntPtr)vars.gameManagerLoc);		
			var uiManager = memory.ReadValue<long>((IntPtr)(gameManager + (long)UIMANAGERoffset));
			var canvas = memory.ReadValue<long>((IntPtr)(uiManager + (long)CANVASoffset));
			var titleCanvas = memory.ReadValue<bool>((IntPtr)(canvas + (long)TCoffset));
			
			var uiPuzzleGrid = memory.ReadValue<long>((IntPtr)(canvas + (long)GRIDoffset));
			var puzzleRoundState = memory.ReadValue<int>((IntPtr)(uiPuzzleGrid + (long)ROUNDSTATEoffset));
			
			var cellphone = memory.ReadValue<long>((IntPtr)(canvas + (long)CELLoffset));
			var cellOpen = memory.ReadValue<bool>((IntPtr)(cellphone + (long)ISOPENoffset));
			var cellApp = memory.ReadValue<long>((IntPtr)(cellphone + (long)APPoffset));
			var affectionMeter = memory.ReadValue<long>((IntPtr)(cellApp + (long)AFFMETERoffset));
			var currentDisplayAffection = memory.ReadValue<int>((IntPtr)(affectionMeter + (long)CURRAFFoffset));
			var goalAffection = memory.ReadValue<int>((IntPtr)(affectionMeter + (long)MAXAFFoffset));
			
			if (titleCanvas == false && puzzleActive == true && cellOpen == false) {
				if (goalAffection > 100 && (currentDisplayAffection == goalAffection) && vars.prevCDA != currentDisplayAffection) {
					if (puzzleRoundState == 1 || isBonusRound) {
						vars.prevCDA = currentDisplayAffection;
						if (isBonusRound == true && settings["bonusroundonly"]) {
							return true;
						}
						if (isBonusRound == false && settings["dateonly"]) {
							return true;
						}
					}
				}
				//DO NOT update prevCDA if we're at max affection but haven't reached victory yet
				else vars.prevCDA = currentDisplayAffection;
			}
		}
	}
	
}
