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
	settings.Add("globefirst",false,"First Split = Spherical Atlas");
	settings.SetToolTip("globefirst","If checked, the first split will be autosplit upon collecting the Spherical Atlas");
	settings.Add("keyfirst",false,"First Split = The Key");
	settings.SetToolTip("keyfirst","If checked, the first split will be autosplit upon collecting The Key");
	settings.Add("geyserlast",true,"Last Split = Geyser");
	settings.SetToolTip("geyserlast","If checked, the last split will be autosplit upon using the geyser");
	settings.Add("autooptions",false,"Automatically Set Game Options");
	settings.SetToolTip("autooptions","If checked, Onion Mode and 200 Pikmin Limit are turned on, and the cursor is moved to Begin!, at game launch. Also, the captain and music choices are remembered between game resets. (Doesn't affect loading savestates)");
	
	vars.captainOne = 0;
	vars.captainTwo = 1;
	vars.musicChoice = 0;
	
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
	vars.globeCollected = 0; vars.keyCollected = 0;
	vars.gameTime = 0;
	vars.pokos = 0;
	vars.optionsMusic = false;
	
	//version number offsets for Version 2.2, 2.3
	vars.versionNumberOffsets = new int[] { 0x53AC28, 0x53CB68 };
	vars.versionNumber = "";
	
	vars.startLoc = IntPtr.Zero;
	vars.checkedForGPVE = -1;
}

update
{
	//check for the Gamecube's memory region every few seconds
	if (vars.startLoc == IntPtr.Zero) {
		vars.checkedForGPVE += 1;
		
		if ((int)vars.checkedForGPVE % 120 == 0) {
			print("Searching for Pikmin 2 memory header...");
			foreach (var page in memory.MemoryPages(true))
			{
				//print(page.BaseAddress.ToString("X") + " " + page.RegionSize.ToString());
				if ((int)page.RegionSize < 67108864) continue; //checking for 64MB or higher
				string hopefullyGPVE01 = memory.ReadString((IntPtr)(page.BaseAddress), 6);
				if (hopefullyGPVE01 == "GPVE01") {
					print("Pikmin 2 memory found at 0x" + page.BaseAddress.ToString("X"));
					vars.startLoc = page.BaseAddress;
					break;
				}
			}
		}
		//don't run the rest of the update function until vars.startLoc != 0
		if (vars.startLoc == IntPtr.Zero) return false;
	}
	
	//determine what version of Colossal Caverns has been loaded
	var isPikmin2Loaded = memory.ReadString((IntPtr)(vars.startLoc), 6);
	if (isPikmin2Loaded == "GPVE01") {
		if (vars.versionNumber == "") {
			foreach (int versionNumberOffset in vars.versionNumberOffsets) {
				string versionCheck = memory.ReadString((IntPtr)(vars.startLoc + versionNumberOffset), 30);
				if (versionCheck == "Version 2.2") {
					vars.versionNumber = versionCheck;
					vars.treasuresLeftOffset = 0x53DBCB;
					vars.globeOffset = 0xA10206;
					vars.gameTimerOffset = 0x53DC44;
					vars.pokosOffset = 0xA0F608;
					
					vars.optionsOffset = 0x53DBE4;
					vars.beginOffset = 0x0A;
					vars.captainOneOffset = vars.optionsOffset - 4;
					vars.captainTwoOffset = 0x53D332; //idk why captain 2 selection is way far away
					vars.musicOffset = vars.optionsOffset - 2;
					vars.twoHundredOffset = vars.optionsOffset + 2;
					vars.onionOffset = vars.optionsOffset + 0x0A;
					vars.treasureCutsceneOffset = vars.optionsOffset + 0x24;
					vars.optionsMusicOffset = vars.optionsOffset + 0x5A;
				}
				else if (versionCheck == "Version 2.3") {
					vars.versionNumber = versionCheck;
					vars.treasuresLeftOffset = 0x5403DB;
					//vars.explorationKitOffset = 0xA1FE44; //bit 3 = good globe
					vars.globeOffset = 0xA20AE2; //key offset = +2, it equals 2 when its collected
					vars.gameTimerOffset = 0x540474;
					vars.pokosOffset = 0xA1FEE4;
					
					vars.optionsOffset = 0x5403F5;
					vars.beginOffset = 0x09;
					vars.captainOneOffset = vars.optionsOffset - 4;
					vars.captainTwoOffset = 0x53FDFA; //idk why captain 2 selection is way far away
					vars.musicOffset = vars.optionsOffset - 2;
					vars.twoHundredOffset = vars.optionsOffset + 2;
					vars.onionOffset = vars.optionsOffset + 0x0A;
					vars.treasureCutsceneOffset = 0;
					vars.optionsMusicOffset = vars.optionsOffset + 0x79;
				}
				if (vars.versionNumber != "") {
					print("Colossal Caverns " + vars.versionNumber + " located!");
					break;
				}
			}
		}
	}
	//the location of Gamecube memory can change between game launches, so blank it if Pikmin 2 unloads
	else {
		print("Pikmin 2 unloaded");
		vars.startLoc = IntPtr.Zero;
		vars.versionNumber = "";
		if (settings.ResetEnabled) {
			vars.timerModel.Reset();
		}
	}
	//don't run anything if we can't determine Colossal Caverns is running in Dolphin
	if (vars.versionNumber == "") return false;
	
	vars.prevTreasuresLeft = vars.treasuresLeft;
	vars.treasuresLeft = memory.ReadValue<byte>((IntPtr)(vars.startLoc + vars.treasuresLeftOffset));
	
	vars.prevGlobeCollected = vars.globeCollected;
	vars.prevKeyCollected = vars.keyCollected;
	vars.globeCollected = memory.ReadValue<byte>((IntPtr)(vars.startLoc + vars.globeOffset));
	vars.keyCollected = memory.ReadValue<byte>((IntPtr)(vars.startLoc + vars.globeOffset + 2));
	
	vars.prevGameTime = vars.gameTime;
	vars.gameTime = vars.BEtoLE(memory.ReadValue<int>((IntPtr)(vars.startLoc + vars.gameTimerOffset)));
	
	vars.prevPokos = vars.pokos;
	vars.pokos = vars.BEtoLE(memory.ReadValue<int>((IntPtr)(vars.startLoc + vars.pokosOffset)));
	
	vars.prevOptionsMusic = vars.optionsMusic;
	vars.optionsMusic = memory.ReadValue<bool>((IntPtr)(vars.startLoc+vars.optionsMusicOffset));
	
	//print(vars.gameTime.ToString());
}

start
{	
	if (settings["autooptions"]) {
		//set the preset options on game reset
		var optionsCursor = memory.ReadValue<byte>((IntPtr)(vars.startLoc+vars.optionsOffset));
		if (vars.optionsMusic == true && vars.prevOptionsMusic == false && optionsCursor == 0) {
			memory.WriteBytes((IntPtr)(vars.startLoc+vars.captainOneOffset), new byte [] { (byte)vars.captainOne });
			memory.WriteBytes((IntPtr)(vars.startLoc+vars.captainTwoOffset), new byte [] { (byte)vars.captainTwo });
			memory.WriteBytes((IntPtr)(vars.startLoc+vars.musicOffset), new byte [] { (byte)vars.musicChoice });
			memory.WriteBytes((IntPtr)(vars.startLoc+vars.onionOffset), new byte [] {3});
			memory.WriteBytes((IntPtr)(vars.startLoc+vars.twoHundredOffset), new byte [] {1});
			if (vars.treasureCutsceneOffset != 0)
				memory.WriteBytes((IntPtr)(vars.startLoc+vars.treasureCutsceneOffset), new byte [] {1});
			memory.WriteBytes((IntPtr)(vars.startLoc+vars.optionsOffset), new byte [] {(byte)vars.beginOffset});
		}
	}
	//the gameTime hangs on 1 for a few frames before real time should begin so let's start real time at 2
	if (vars.gameTime > 1 && vars.prevGameTime <= 1) {
		vars.captainOne = memory.ReadValue<byte>((IntPtr)(vars.startLoc+vars.captainOneOffset));
		vars.captainTwo = memory.ReadValue<byte>((IntPtr)(vars.startLoc+vars.captainTwoOffset));
		vars.musicChoice = memory.ReadValue<byte>((IntPtr)(vars.startLoc+vars.musicOffset));
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
	if (vars.gameTime == 0) return false;
	
	var currentSplitName = vars.timerModel.CurrentState.CurrentSplit.Name;
	var currentSplit = vars.timerModel.CurrentState.CurrentSplitIndex;

	//final split = geyser
	if (settings["geyserlast"] && currentSplit == vars.timerModel.CurrentState.Run.Count-1 && vars.pokos > 0 && vars.prevPokos == 0) {
		return true;
	}
	
	//first split = globe
	if (settings["globefirst"] && currentSplit == 0 && vars.globeCollected != vars.prevGlobeCollected &&
	vars.globeCollected == 2) {
		return true;
	}
	//first split = key
	if (settings["keyfirst"] && currentSplit == 0 && vars.keyCollected != vars.prevKeyCollected &&
	vars.keyCollected == 2) {
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
