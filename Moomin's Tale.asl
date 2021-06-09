//Moomin's Tale
//by Buurazu + SummerTimeAlice

/* 
C1EF = displaying numbers (5-byte password, meters left on rolling rock)
C2B5 = selected language (default 0, 0 = English, so useless for starting...)
C2B6 = fadeout time?
D001 = something camera position related, but equals 68 on language select
DE50 = current level (0 on menu)

final split checks:
C100 = fadeout type, 3 = fade out, 4 = fade in?
C103 = fadeout, switches to 0x1F on final A press
D359 = 0x75, D35D = 0x16, check that current level = 6
*/

state("EmuHawk") { }
state("bgb") { }
state("bgb64") { }

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
}

init
{	
	vars.password = 0;

	vars.fadeout = 0;
	vars.select = 0;
	vars.levelNumber = 0;
	vars.finalFadeout = 0;
	
	vars.startLoc = IntPtr.Zero;
	vars.WRAMLoc = IntPtr.Zero;
	vars.checkedForMoominHeader = -1;
}

update
{
	//since it's an emulator autosplitter, being connected to the emulator's exe does not mean the game is running
	//check for the emulator's memory region every few seconds to find the game's name in the ROM header
	if (vars.startLoc == IntPtr.Zero) {
		vars.checkedForMoominHeader += 1;

		if ((int)vars.checkedForMoominHeader % 120 == 0) {
			print("Searching for Moomin's Tale memory header...");
			
			//I attempt to find a memory page that's the exact size I'm expecting from searching in Cheat Engine
			//then I have to add whatever offset is necessary to where the emu places ROM/RAM in that page

			if (game.ProcessName == "EmuHawk") {
				//tested on BizHawk 2.6.1 and 2.6.2
				foreach (var page in memory.MemoryPages(true))
				{
					if ((int)page.RegionSize != 0x115000) continue; //checking for BizHawk's memory size
					//print(page.BaseAddress.ToString("X") + " " + page.RegionSize.ToString());
					
					string hopefullyMOOMIN = memory.ReadString((IntPtr)(page.BaseAddress + 0x4174), 6);
					if (hopefullyMOOMIN == "MOOMIN") {
						print("Moomin's Tale header found at 0x" + page.BaseAddress.ToString("X"));
						vars.startLoc = page.BaseAddress + 0x4174;
						vars.WRAMLoc = page.BaseAddress + 0x108040;
						break;
					}
				}
			}
			if (game.ProcessName == "bgb") {
				//BGB doesn't seem to have work RAM and the ROM in one memory block, so search for both
				//tested on BGB 1.5.9 and 1.5.7
				foreach (var page in memory.MemoryPages(true))
				{
					//checking for BGB's ROM area memory size (1.5.9's size and 1.5.7's size)
					if ((int)page.RegionSize != 0x108000 && (int)page.RegionSize != 0x104000) continue; 
					//print(page.BaseAddress.ToString("X") + " " + page.RegionSize.ToString());
					
					string hopefullyMOOMIN = memory.ReadString((IntPtr)(page.BaseAddress + 0x1134), 6);
					if (hopefullyMOOMIN == "MOOMIN") {
						print("Moomin's Tale header found at 0x" + page.BaseAddress.ToString("X"));
						vars.startLoc = page.BaseAddress + 0x1134;
						break;
					}
				}
				if (vars.startLoc != IntPtr.Zero) {
					foreach (var page in memory.MemoryPages(true))
					{
						if ((int)page.RegionSize != 0x5C000) continue; //checking for BGB64's RAM area memory size
						//print(page.BaseAddress.ToString("X") + " " + page.RegionSize.ToString());
						
						vars.WRAMLoc = page.BaseAddress + 0x10000;
						break;
					}
				}
				
			}
			if (game.ProcessName == "bgb64") {
				//BGB doesn't seem to have work RAM and the ROM in one memory block, so search for both
				//tested on BGB64 1.5.9
				foreach (var page in memory.MemoryPages(true))
				{
					if ((int)page.RegionSize != 0x110000) continue; //checking for BGB64's ROM area memory size
					//print(page.BaseAddress.ToString("X") + " " + page.RegionSize.ToString());
					
					string hopefullyMOOMIN = memory.ReadString((IntPtr)(page.BaseAddress + 0x1134), 6);
					if (hopefullyMOOMIN == "MOOMIN") {
						print("Moomin's Tale header found at 0x" + page.BaseAddress.ToString("X"));
						vars.startLoc = page.BaseAddress + 0x1134;
						break;
					}
				}
				if (vars.startLoc != IntPtr.Zero) {
					foreach (var page in memory.MemoryPages(true))
					{
						if ((int)page.RegionSize != 0x140000) continue; //checking for BGB64's RAM area memory size
						//print(page.BaseAddress.ToString("X") + " " + page.RegionSize.ToString());
						
						vars.WRAMLoc = page.BaseAddress + 0x63000;
						break;
					}
				}
			}
		}
		//don't run the rest of the update function until vars.startLoc != 0
		if (vars.startLoc == IntPtr.Zero) return false;
	}
	
	var isMoominLoaded = memory.ReadString((IntPtr)(vars.startLoc), 6);

	//Moomin has been unloaded (game swap) or otherwise changed locations (core reboot)
	if (isMoominLoaded != "MOOMIN") {
		print("Moomin's Tale unloaded");
		vars.startLoc = IntPtr.Zero;
		vars.WRAMLoc = IntPtr.Zero;
		if (settings.ResetEnabled) {
			vars.timerModel.Reset();
		}
		return false;
	}
	
	vars.prevPassword = vars.password;
	vars.password = 0;
	//could have done a for loop but w/e
	vars.password += memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x1EF)) * 10000;
	vars.password += memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x1F0)) * 1000;
	vars.password += memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x1F1)) * 100;
	vars.password += memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x1F2)) * 10;
	vars.password += memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x1F3));
	print(vars.password.ToString());
	
	vars.prevFadeout = vars.fadeout;
	vars.fadeout = memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x2B6));
	
	vars.prevSelect = vars.select;
	vars.select = memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x1001));
	
	vars.prevLevelNumber = vars.levelNumber;
	vars.levelNumber = memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x1E50));
	
	vars.prevFinalFadeout = vars.finalFadeout;
	vars.finalFadeout = memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x103));
	
	vars.finalFadeoutType = memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x100));
	vars.finalPicCheck1 = memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x1359));
	vars.finalPicCheck2 = memory.ReadValue<byte>((IntPtr)(vars.WRAMLoc + 0x135D));
	
}

start
{	
	//start timer as soon as the screen starts fading out while menu position is on language select and current level = 0
	//this might have false positives midrun but it doesn't run midrun so it's fine
	if (vars.levelNumber == 0 && vars.select == 68 && vars.fadeout != vars.prevFadeout) {
		return true;
	}
}

reset
{
	//reset when level number = 0, and we switch from GAME START to language selection
	//this is so restrictive that it shouldn't produce false positives
	if (vars.levelNumber == 0 && vars.select == 68 && vars.prevSelect == 80) {
		return true;
	}
}

split
{	
	//split when a new password is generated
	//the memory for the password display is also used during the rock chase, so check if it's above 99
	//and it has garbage data upon reset that makes it far above 99999
	if (vars.password != vars.prevPassword && vars.password > 99 && vars.password <= 99999) {
		return true;
	}
	
	//wonky final split logic
	//check for Level 6, check for final picture being displayed, the final fadeout just beginning, and it being fadeout rather than fadein
	if (vars.levelNumber == 6 && vars.finalPicCheck1 == 0x75 && vars.finalPicCheck2 == 0x16 && vars.prevFinalFadeout == 0 && vars.finalFadeout > 0 && vars.finalFadeoutType == 3) {
		return true;
	}
}
