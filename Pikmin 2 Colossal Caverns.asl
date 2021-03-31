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
	settings.SetToolTip("treasurename","If checked, split names that match a treasure name will be autosplit upon collection");
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
	
	vars.treasureNames = new string[] { "Rubber Ugly", "Insect Condo", "Meat Satchel", "Coiled Launcher", "Confection Hoop", "Omniscient Sphere", "Love Sphere", "Mirth Sphere", "Maternal Sculpture", "Stupendous Lens", "Leviathan Feather", "Superstrong Stabilizer", "Space Wave Receiver", "Joy Receptacle", "Worthless Statue", "Priceless Statue", "Triple Sugar Threat", "King of Sweets", "Diet Doomer", "Pale Passion", "Boom Cone", "Bug Bait", "Milk Tub", "Petrified Heart", "Regal Diamond", "Princess Pearl", "Silencer", "Armored Nut", "Chocolate Cushion", "Sweet Dreamer", "Cosmic Archive", "Cupid's Grenade", "Science Project", "Manual Honer", "Broken Food Master", "Sud Generator", "Wiggle Noggin", "Omega Flywheel", "Lustrous Element", "Superstick Textile", "Possessed Squash", "Gyroid Bust", "Sunseed Berry", "Glee Spinner", "Decorative Goo", "Anti-hiccup Fungus", "Crystal King", "Fossilized Ursidae", "Time Capsule", "Olimarnite Shell", "Conifer Spire", "Abstract Masterpiece", "Arboreal Frippery", "Onion Replica", "Infernal Vegetable", "Adamantine Girdle", "Director of Destiny", "Colossal Fossil", "Invigorator", "Vacuum Processor", "Mirrored Element", "Nouveau Table", "Pink Menace", "Frosty Bauble", "Gemstar Husband", "Gemstar Wife", "Universal Com", "Joyless Jewel", "Fleeting Art Form", "Innocence Lost", "Icon of Progress", "Unspeakable Wonder", "Aquatic Mine", "Temporal Mechanism", "Essential Furnishing", "Flame Tiller", "Doomsday Apparatus", "Impediment Scourge", "Future Orb", "Shock Therapist", "Flare Cannon", "Comedy Bomb", "Monster Pump", "Mystical Disc", "Vorpal Platter", "Taste Sensation", "Lip Service", "Utter Scrap", "Paradoxical Enigma", "King of Bugs", "Essence of Rage", "Essence of Despair", "Essence of True Love", "Essence of Desire", "Citrus Lump", "Behemoth Jaw", "Anxious Sprout", "Implement of Toil", "Luck Wafer", "Meat of Champions", "Talisman of Life", "Strife Monolith", "Boss Stone", "Toxic Toadstool", "Growshroom", "Indomitable CPU", "Network Mainbrain", "Repair Juggernaut", "Exhausted Superstick", "Pastry Wheel", "Combustion Berry", "Imperative Cookie", "Compelling Cookie", "Impenetrable Cookie", "Comfort Cookie", "Succulent Mattress", "Corpulent Nut", "Alien Billboard", "Massage Girdle", "Crystallized Telepathy", "Crystallized Telekinesis", "Crystallized Clairvoyance", "Eternal Emerald Eye", "Tear Stone", "Crystal Clover", "Danger Chime", "Sulking Antenna", "Spouse Alert", "Master's Instrument", "Extreme Perspirator", "Pilgrim Bulb", "Stone of Glory", "Furious Adhesive", "Quenching Emblem", "Flame of Tomorrow", "Love Nugget", "Child of the Earth", "Disguised Delicacy", "Proton AA", "Fuel Reservoir", "Optical Illustration", "Durable Energy Cell", "Courage Reactor", "Thirst Activator", "Harmonic Synthesizer", "Merciless Extractor", "Remembered Old Buddy", "Fond Gyro Block", "Memorable Gyro Block", "Lost Gyro Block", "Favorite Gyro Block", "Treasured Gyro Block", "Fortified Delicacy", "Scrumptious Shell", "Memorial Shell", "Chance Totem", "Dream Architect", "Spiny Alien Treat", "Spirit Flogger", "Mirrored Stage", "Enamel Buster", "Drought Ender", "White Goodness", "Salivatrix", "Creative Inspiration", "Massive Lid", "Happiness Emblem", "Survival Ointment", "Mysterious Remains", "Dimensional Slicer", "Yellow Taste Tyrant", "Hypnotic Platter", "Gherkin Gate", "Healing Cask", "Pondering Emblem", "Activity Arouser", "Stringent Container", "Patience Tester", "Endless Repository", "Fruit Guard", "Nutrient Silo", "Drone Supplies", "Unknown Merit", "Seed of Greed", "Heavy-duty Magnetizer", "Air Brake", "Hideous Victual", "Emperor Whistle", "Brute Knuckles", "Dream Material", "Amplified Amplifier", "Professional Noisemaker", "Stellar Orb", "Justice Alloy", "Forged Courage", "Repugnant Appendage", "Prototype Detector", "Five-man Napsack", "Spherical Atlas", "Geographic Projection", "The Key" };

}

init
{	
	vars.treasuresLeft = 0;
	vars.prevTreasuresCollected = new byte[201]; vars.treasuresCollected = new byte[201];
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
					
					vars.treasuresOffset = 0xA10130;
					vars.explorationOffset = 0xA101FC;
					
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
					
					vars.treasuresOffset = 0xA20A0C;
					vars.explorationOffset = 0xA20AD8;
					
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
					
					//the code used to print out list of treasure names
					/*
					var treasureNameLoc = vars.startLoc + 0xA94D79;
					string theArray = "";
					for (int i = 0; i < 201; i++) {
						string currentName = memory.ReadString((IntPtr)(treasureNameLoc), 40);
						treasureNameLoc += (currentName.Length) + 1;
						currentName = memory.ReadString((IntPtr)(treasureNameLoc), 40);
						currentName = currentName.Replace("\n"," ").Substring(0,currentName.Length-3);
						theArray += "\"" + currentName + "\", ";
						treasureNameLoc += (currentName.Length) + 6;
						//print(treasureNameLoc.ToString("X"));
					}
					theArray = theArray.Replace("  ", " ");
					print(theArray);
					*/
					
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
	
	vars.prevGameTime = vars.gameTime;
	vars.gameTime = vars.BEtoLE(memory.ReadValue<int>((IntPtr)(vars.startLoc + vars.gameTimerOffset)));
	
	vars.prevPokos = vars.pokos;
	vars.pokos = vars.BEtoLE(memory.ReadValue<int>((IntPtr)(vars.startLoc + vars.pokosOffset)));
	
	vars.prevOptionsMusic = vars.optionsMusic;
	vars.optionsMusic = memory.ReadValue<bool>((IntPtr)(vars.startLoc+vars.optionsMusicOffset));
	
	Array.Copy(vars.treasuresCollected, vars.prevTreasuresCollected, 201);
	for (int i = 0; i <= 187; i++) {
		vars.treasuresCollected[i] = memory.ReadValue<byte>((IntPtr)(vars.startLoc + vars.treasuresOffset + i));
	}
	for (int i = 0; i <= 12; i++) {
		vars.treasuresCollected[i+188] = memory.ReadValue<byte>((IntPtr)(vars.startLoc + vars.explorationOffset + i));
	}
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
	
	//split name = last collected treasure
	//skip the split if we run into it with the treasure already collected
	if (settings["treasurename"]) {
		for (int i = 0; i < 201; i++) {
			if (vars.treasureNames[i] == currentSplitName && vars.treasuresCollected[i] == 2) {
				if (vars.treasuresCollected[i] != vars.prevTreasuresCollected[i]) return true;
				else vars.timerModel.SkipSplit();
			}			
		}
	}
	
	//first split = globe
	if (settings["globefirst"] && currentSplit == 0 &&
	vars.treasuresCollected[198] != vars.prevTreasuresCollected[198] && vars.treasuresCollected[198] == 2) {
		return true;
	}
	//first split = key
	if (settings["keyfirst"] && currentSplit == 0 &&
	vars.treasuresCollected[200] != vars.prevTreasuresCollected[200] && vars.treasuresCollected[200] == 2) {
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
