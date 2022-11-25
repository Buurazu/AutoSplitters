//HuniePop AutoSplitter
//created by RShields and Buurazu

//DOES NOT AUTOSPLIT ON 100% COMPLETION, there's no way I can do that check in here

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
	int saveFiles			: "mono.dll", 0x00209554, 0x10, 0x154, 0xC, 0xA0, 0x80, 0xD0, 0x8C;
}

state("HuniePop", "Valentine's")
{
	int displayAffection	: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x40, 0xC4;
	int goalAffection		: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x40, 0xA4;
	bool victory			: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x40, 0x90;
	bool isBonusRound		: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x2C, 0x40, 0x7C;
	int girlID				: "mono.dll", 0x00209554, 0x10, 0x154, 0x0, 0x10, 0x18, 0x10;
	
	bool interactive		: "mono.dll", 0x00209554, 0x10, 0x154, 0xC, 0xA0, 0x80, 0xD0, 0x78;
	int saveFiles			: "mono.dll", 0x00209554, 0x10, 0x154, 0xC, 0xA0, 0x80, 0xD0, 0x8C;
}

state("HuniePop", "Jan. 23 Modded")
{
	int displayAffection	: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x3C, 0xBC;
	int goalAffection		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x3C, 0xA0;
	bool victory			: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x3C, 0x8C;
	bool isBonusRound		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x3C, 0x7C;
	int girlID				: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x10, 0x18, 0x10;
	
	bool interactive		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0xC, 0xA0, 0x80, 0xD0, 0x78;
	int saveFiles			: "mono.dll", 0x00209554, 0x10, 0x5A4, 0xC, 0xA0, 0x80, 0xD0, 0x8C;
}

state("HuniePop", "Valentine's Modded")
{
	int displayAffection	: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x40, 0xC4;
	int goalAffection		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x40, 0xA4;
	bool victory			: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x40, 0x90;
	bool isBonusRound		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x2C, 0x40, 0x7C;
	int girlID				: "mono.dll", 0x00209554, 0x10, 0x5A4, 0x0, 0x10, 0x18, 0x10;
	
	bool interactive		: "mono.dll", 0x00209554, 0x10, 0x5A4, 0xC, 0xA0, 0x80, 0xD0, 0x78;
	int saveFiles			: "mono.dll", 0x00209554, 0x10, 0x5A4, 0xC, 0xA0, 0x80, 0xD0, 0x8C;
}

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
	
	settings.Add("resetonexit",true,"Reset on Game Exit");
	settings.SetToolTip("resetonexit","Disable this if you want to be able to relaunch the game without a reset (like for fixing route mistakes / undoing a failed date)");
	
	settings.Add("limit4", true, "Limit 4+1 Splits Per Girl");
	settings.SetToolTip("limit4", "Limit girls to splitting after dates 4 times (plus 1 after bonus rounds), to help with 100% compatibility");
	
	settings.Add("autorenamesplits", false, "Auto-Rename \"GirlName #\" Splits");
	settings.SetToolTip("autorenamesplits", "The autosplitter will dynamically edit your split names after a split to help with route changes. Note it's an EDIT, so the split name needs a girl's first name, and 1/2/3/4/Bonus in it.");
	
	Action InitSplitArrays = () => {
		vars.splitsPerGirl = new int[13];
		vars.splitsPerGirl[9] = -1;
		vars.bonusPerGirl = new bool[13];
	};
	vars.InitSplitArrays = InitSplitArrays;
	vars.InitSplitArrays();
	
	string[] girlNames = new string[] { "Tiffany", "Aiko", "Kyanna", "Audrey", "Lola", "Nikki", "Jessie", "Beli", "Kyu", "Momo", "Celeste", "Venus" };
	string[] dateNames = new string[] { "1", "2", "3", "4", "Bonus" };
	
	Action<int,string> RenameSplit = (girlID,dateName) => {
		string girlName = girlNames[girlID-1];
		string currentSplitName = vars.timerModel.CurrentState.CurrentSplit.Name;
		
		foreach (string s in girlNames) {
			currentSplitName = currentSplitName.Replace(s, girlName);
		}
		foreach (string s in dateNames) {
			currentSplitName = currentSplitName.Replace(s, dateName);
		}
		
		vars.timerModel.CurrentState.CurrentSplit.Name = currentSplitName;
	};
	vars.RenameSplit = RenameSplit;
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
	
	vars.waitAFrame = 5;
	
	//if reset on exit is disabled, we don't want to reset the first time we see the title screen
	vars.resetAllowed = settings["resetonexit"];
}

update
{
	if (current.interactive == true && old.interactive == false) {
		//fix a bug where occasionally LoadScreen.interactive is true for one frame and makes splits start
		vars.waitAFrame = 5;
	}
}

start
{	
	//check if the LoadScreen is interactive
	//note that this starts splits on file load too, but that's not really a bad thing
	if (current.interactive == false && old.interactive == true && vars.waitAFrame <= 0) {
			vars.InitSplitArrays();
			return true;
	}
	vars.waitAFrame = vars.waitAFrame - 1;
}

exit
{
	//exiting the game = reset
	if (settings["resetonexit"]) {
		vars.InitSplitArrays();
		vars.timerModel.Reset();
	}
}

reset
{
	//return to main menu = reset
	//LoadScreen's save files list is nulled once the load screen is exited
	if (current.saveFiles != 0 && old.saveFiles == 0 && vars.resetAllowed) {
		vars.InitSplitArrays();
		return true;
	}
}

split
{
	if (current.displayAffection == current.goalAffection) {
		//Bonus rounds split the frame that display affection = goal affection
		if (current.isBonusRound && current.displayAffection != old.displayAffection) {
			if (!settings["limit4"] || !vars.bonusPerGirl[current.girlID]) {
				if (settings["autorenamesplits"] && !vars.bonusPerGirl[current.girlID]) vars.RenameSplit(current.girlID, "Bonus");
				vars.bonusPerGirl[current.girlID] = true;
				
				return true;
			}
		}
		//Dates have to wait until victory is confirmed, due to potential Broken Heart matches
		if (!current.isBonusRound && current.victory && (current.victory != old.victory || current.displayAffection != old.displayAffection)) {
			if (!settings["limit4"] || vars.splitsPerGirl[current.girlID] < 4) {
				vars.splitsPerGirl[current.girlID] += 1;
				if (settings["autorenamesplits"] && vars.splitsPerGirl[current.girlID] <= 4 && vars.splitsPerGirl[current.girlID] > 0) vars.RenameSplit(current.girlID, vars.splitsPerGirl[current.girlID].ToString());
				
				return true;
			}
		}
	}
	
	//allow splitting the next time the menu is seen when we see a girl
	if (current.girlID != 0) {
		vars.resetAllowed = true;
	}
}
