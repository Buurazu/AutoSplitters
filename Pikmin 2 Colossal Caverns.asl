//Pikmin 2: Colossal Caverns Autosplitter
//by Buurazu

state("Dolphin", "5.0-13603")
{
	long STARTLOC : 0x00C15BE0;
}

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	
	
	settings.Add("treasuresleft",true,"\"X Treasures Left\" Splits");
	settings.SetToolTip("treasuresleft","If checked, your splits are read as the number of treasures left, instead of number of treasures collected");
	settings.Add("globefirst",false,"First Split = Globe");
	settings.SetToolTip("globefirst","If checked, the first split will be autosplit upon collecting either globe treasure");
	settings.Add("splitongeyser",true,"Split on Geyser");
	settings.SetToolTip("globefirst","If checked, it'll autosplit on the Treasures Salvaged screen if you used the geyser");
	
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
	
	var module = modules.Single(x => String.Equals(x.ModuleName, "Dolphin.exe", StringComparison.OrdinalIgnoreCase));
	var moduleSize = module.ModuleMemorySize;
	print("Module Size: "+moduleSize.ToString()+" "+module.ModuleName);
	string hash = vars.CalcModuleHash(module);

	switch (hash){
        case "079F3A179FC7F67902C6892CFF37BEEB": version = "5.0-13603"; break;
        default: version = "Unknown"; break;
    }

	vars.versionNumberOffset = 0x53AC28;
	vars.versionNumber = "";
}

update
{
	//determine what version of Colossal Caverns has been loaded
	var isPikmin2Loaded = memory.ReadString((IntPtr)(current.STARTLOC), 6);
	if (isPikmin2Loaded == "GPVE01") {
		if (vars.versionNumber == "") {
			//boy I sure hope the versionNumberOffset doesn't differ between versions hahahaha
			//I'll find some way to differentiate versions if I have to
			vars.versionNumber = memory.ReadString((IntPtr)(current.STARTLOC + vars.versionNumberOffset), 30);
			if (vars.versionNumber == "Version 2.2") {
				vars.treasuresLeftOffset = 0x53DBCB;
				vars.treasureNameOffset = 0x5C52F8;
				vars.gameTimerOffset = 0x53DC44;
				vars.pokosOffset = 0xA0F608;
				print(current.STARTLOC.ToString("X"));
			}
			else {
				vars.versionNumber = "";
			}
		}
	}
	else {
		vars.versionNumber = "";
	}
	//don't run anything if we can't determine Colossal Caverns is running in Dolphin
	if (vars.versionNumber == "") return false;
	
	vars.prevTreasuresLeft = vars.treasuresLeft;
	vars.treasuresLeft = memory.ReadValue<byte>((IntPtr)(current.STARTLOC + vars.treasuresLeftOffset));
	
	vars.prevTreasureName = vars.treasureName;
	vars.treasureName = memory.ReadString((IntPtr)(current.STARTLOC + vars.treasureNameOffset), 30);
	
	vars.prevGameTime = vars.gameTime;
	vars.gameTime = vars.BEtoLE(memory.ReadValue<int>((IntPtr)(current.STARTLOC + vars.gameTimerOffset)));
	
	vars.prevPokos = vars.pokos;
	vars.pokos = vars.BEtoLE(memory.ReadValue<int>((IntPtr)(current.STARTLOC + vars.pokosOffset)));
}

start
{	
	if (vars.gameTime > 0 && vars.prevGameTime == 0) {
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

	//
	if (settings["splitongeyser"] && vars.pokos > 0 && vars.prevPokos == 0) {
		return true;
	}
	
	if (currentSplitName == vars.treasureName && vars.treasureName != vars.prevTreasureName) {
		return true;
	}
	
	if (settings["globefirst"] && currentSplit == 0 && vars.treasureName != vars.prevTreasureName &&
	(vars.treasureName == "Spherical Atlas" || vars.treasureName == "Geographic Projection")) {
		return true;
	}

	var firstWord = currentSplitName.Split(' ')[0];
	int target;
	//only check for splitting logic if the split name begins with a number
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
