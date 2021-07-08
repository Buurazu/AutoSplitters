//Dolphin Autosplitter Template
//by Buurazu

state("Dolphin") { }

startup {

	//CHANGE THIS TO YOUR GAME'S ID
	//(check the title bar of the Dolphin window, it's after the game's name)
	vars.gameID = "GPVE01";
	
	//this is just used for debug prints
	vars.gameName = "Pikmin 2";
	

	vars.timerModel = new TimerModel { CurrentState = timer };
	
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
	vars.startLoc = IntPtr.Zero;
	vars.checkedForGameID = -1;
}

update
{
	//check for Dolphin's memory region every 2 seconds
	//(feel free to change this frequency, but it's a pretty quick check since it's not scanning memory, just checking page size)
	if (vars.startLoc == IntPtr.Zero) {
		vars.checkedForGameID += 1;
		
		if ((int)vars.checkedForGameID % 120 == 0) {
			print("Searching for " + vars.gameName + "'s memory header...");
			foreach (var page in memory.MemoryPages(true))
			{
				//print(page.BaseAddress.ToString("X") + " " + page.RegionSize.ToString());
				if ((int)page.RegionSize == 0x2000000) continue; //checking for 32MB exactly
				string hopefullyID = memory.ReadString((IntPtr)(page.BaseAddress), 6);
				if (hopefullyID == vars.gameID) {
					print(vars.gameName + " memory found at 0x" + page.BaseAddress.ToString("X"));
					vars.startLoc = page.BaseAddress;
					break;
				}
			}
		}
		//don't run the rest of the update function until vars.startLoc != 0
		if (vars.startLoc == IntPtr.Zero) return false;
	}
	
	//make sure the target game is still loaded
	var isGameStillLoaded = memory.ReadString((IntPtr)(vars.startLoc), 6);
	if (isGameStillLoaded == vars.gameID) {
		
	}
	//the location of memory can change between game launches, so blank it if the target game unloads
	else {
		print(vars.gameName + " unloaded");
		vars.startLoc = IntPtr.Zero;
		
		if (settings.ResetEnabled) {
			vars.timerModel.Reset();
		}
	}
	
	//don't run anything if we can't determine the target game is still running in Dolphin
	if (vars.startLoc == IntPtr.Zero) return false;
	
	
	//update code goes here
	//for examples of how to read memory from the start location: https://github.com/Buurazu/AutoSplitters/blob/main/Pikmin%202%20Colossal%20Caverns.asl
	
}

start
{	

}

reset
{

}

split
{	

}

