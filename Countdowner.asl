//Very simple ASL that turns LiveSplit into a countdown timer
//Can play a .wav file at the end of the countdown
//Make sure to compare to Game Time

state("LiveSplit") { }

startup {
	vars.timerModel = new TimerModel { CurrentState = timer };
}

init {
	//Change the sound location here (keep the at sign, just change what's in between the quotation marks)
	//currently, only .wavs can be used
	vars.playSoundAtEnd = true;
	vars.soundLocation = @"D:\fanfare.wav";
	
	vars.playedSound = false;
}

update {
	//Countdown time is set to your splits file's "Start timer at:" offset
	if (vars.timerModel.CurrentState.CurrentPhase == TimerPhase.NotRunning) {
		vars.playedSound = false;
		vars.targetSeconds = vars.timerModel.CurrentState.Run.Offset;
	}
}

gameTime
{
	vars.elapsedTime = vars.timerModel.CurrentState.CurrentTime.RealTime - vars.timerModel.CurrentState.Run.Offset;
	
	if (vars.elapsedTime > vars.targetSeconds) {
		if (vars.playSoundAtEnd == true && vars.playedSound == false) {
			vars.playedSound = true;
			System.Media.SoundPlayer player = new System.Media.SoundPlayer(vars.soundLocation);
			player.Play();
		}
		return TimeSpan.Zero;
	}
	return vars.targetSeconds - vars.elapsedTime;
}

isLoading
{
	return true;
}
