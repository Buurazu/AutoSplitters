//Pikmin 2: Colossal Caverns Autosplitter
//by Buurazu

//note to self: find this by doing a string search for "GPVE01"
//and pointer scanning the topmost result that ends in 0000
//state("Dolphin", "5.0-13871") { long STARTLOC : 0x00C46190; }
state("Dolphin") { }

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	
	settings.Add("treasuresleft",true,"\"X Treasures Left\" Splits");
	settings.SetToolTip("treasuresleft","If checked, splits beginning with a number are read as the number of treasures left, instead of number of treasures collected");
	settings.Add("treasurename",true,"\"Treasure Name\" Splits");
	settings.SetToolTip("treasurename","If checked, split names that match a treasure name will be autosplit upon collection (good for The Key in any%)");
	settings.Add("globefirst",false,"First Split = Crab");
	settings.SetToolTip("globefirst","If checked, the first split will be autosplit upon collecting the Spherical Atlas");
	settings.Add("geyserlast",true,"Last Split = Geyser");
	settings.SetToolTip("geyserlast","If checked, the last split will be autosplit upon using the geyser");
	
	//Big Endian to Little Endian
	Func<int, int> BEtoLE = (beint) => {
		byte[] bytes = BitConverter.GetBytes(beint);
		Array.Reverse(bytes, 0, bytes.Length);
		beint = BitConverter.ToInt32(bytes, 0);
		return beint;
	};
	vars.BEtoLE = BEtoLE;
}

init
{	
	vars.treasuresLeft = 0;
	vars.treasureName = "Pikmin 4 Alpha Disc";
	vars.gameTime = 0;
	vars.pokos = 0;
	
	//SigScan function for locating beginning location of Gamecube memory
	Action<SigScanTarget, string> search = (theTarget, name) => {
	foreach (var page in memory.MemoryPages(true))
	{
		var bytes = memory.ReadBytes(page.BaseAddress, (int)page.RegionSize);
		if (bytes == null)
			continue;
		//print(page.ToString());
		//print(page.BaseAddress.ToString("X") + " " + page.RegionSize.ToString());
		var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
		vars.addr = scanner.Scan(theTarget); 

		if (vars.addr != IntPtr.Zero)
		{
			print(name + " found at 0x" + vars.addr.ToString("X"));
			break;
		}
	}
	};
	vars.search = search;
	
	//Colossal Caverns Version 2.2 text offset
	vars.versionNumberOffset = 0x53AC28;
	vars.versionNumber = "";
	
	vars.startLoc = IntPtr.Zero;
	vars.dolphinLoc = IntPtr.Zero;
	vars.checkedForGPVE = -1;
}

update
{
	//check for the Gamecube's memory region once per second
	if (vars.startLoc == IntPtr.Zero) {
		vars.checkedForGPVE += 1;
		
		//"GPVE01"
		if ((int)vars.checkedForGPVE % 120 == 0) {
			print("Searching for Pikmin 2 memory header...");
			SigScanTarget target = new SigScanTarget(0, "47 50 56 45 30 31 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00");

			vars.search(target,"Start of Pikmin 2");
			if (vars.addr != IntPtr.Zero) {
				vars.startLoc = vars.addr;
			}
		}
		//don't run the rest of the update function until vars.startLoc != 0
		return false;
	}
	
	//determine what version of Colossal Caverns has been loaded
	var isPikmin2Loaded = memory.ReadString((IntPtr)(vars.startLoc), 6);
	if (isPikmin2Loaded == "GPVE01") {
		if (vars.versionNumber == "") {
			//boy I sure hope the versionNumberOffset doesn't differ between versions hahahaha
			//I'll find some way to differentiate versions if I have to
			vars.versionNumber = memory.ReadString((IntPtr)(vars.startLoc + vars.versionNumberOffset), 30);
			if (vars.versionNumber == "Version 2.2") {
				vars.treasuresLeftOffset = 0x53DBCB;
				vars.treasureNameOffset = 0x5C52F8;
				vars.gameTimerOffset = 0x53DC44;
				vars.pokosOffset = 0xA0F608;
				print("Colossal Caverns " + vars.versionNumber + " located!");
			}
			else {
				vars.versionNumber = "";
			}
		}
	}
	//the location of Gamecube memory can change between game launches, so blank it if Pikmin 2 unloads
	else {
		print("Pikmin 2 unloaded");
		vars.startLoc = IntPtr.Zero;
		vars.versionNumber = "";
	}
	//don't run anything if we can't determine Colossal Caverns is running in Dolphin
	if (vars.versionNumber == "") return false;
	
	vars.prevTreasuresLeft = vars.treasuresLeft;
	vars.treasuresLeft = memory.ReadValue<byte>((IntPtr)(vars.startLoc + vars.treasuresLeftOffset));
	
	vars.prevTreasureName = vars.treasureName;
	vars.treasureName = memory.ReadString((IntPtr)(vars.startLoc + vars.treasureNameOffset), 30);
	
	vars.prevGameTime = vars.gameTime;
	vars.gameTime = vars.BEtoLE(memory.ReadValue<int>((IntPtr)(vars.startLoc + vars.gameTimerOffset)));
	
	vars.prevPokos = vars.pokos;
	vars.pokos = vars.BEtoLE(memory.ReadValue<int>((IntPtr)(vars.startLoc + vars.pokosOffset)));
	
	//print(vars.gameTime.ToString());
}

start
{	
	//the gameTime hangs on 1 for a few frames before real time should begin so let's start real time at 2
	if (vars.gameTime > 1 && vars.prevGameTime <= 1) {
		return true;
	}
}

reset
{
	if (vars.gameTime == 0 && vars.prevGameTime != 0) {
		return true;
	}
}

split
{	
	var currentSplitName = vars.timerModel.CurrentState.CurrentSplit.Name;
	var currentSplit = vars.timerModel.CurrentState.CurrentSplitIndex;

	//final split = geyser
	if (settings["geyserlast"] && currentSplit == vars.timerModel.CurrentState.Run.Count-1 && vars.pokos > 0 && vars.prevPokos == 0) {
		return true;
	}
	
	//split name = last collected treasure
	if (settings["treasurename"] && currentSplitName == vars.treasureName && vars.treasureName != vars.prevTreasureName) {
		return true;
	}
	
	//first split = globe
	if (settings["globefirst"] && currentSplit == 0 && vars.treasureName != vars.prevTreasureName &&
	vars.treasureName == "Spherical Atlas") {
		return true;
	}

	//check if the first word of the split name is a number
	var firstWord = currentSplitName.Split(' ')[0];
	int target;
	if (Int32.TryParse(firstWord, out target)) {
		if (!settings["treasuresleft"]) target = 201 - target;
		
		//we missed a split, possibly because of slow crab?
		if (target > vars.treasuresLeft) {
			vars.timerModel.SkipSplit();
		}
		else if (target == vars.treasuresLeft && vars.treasuresLeft != vars.prevTreasuresLeft) {
			return true;
		}
	}
}

gameTime
{
	return TimeSpan.FromSeconds(vars.gameTime/30f);
}

isLoading
{
	return true;
}
