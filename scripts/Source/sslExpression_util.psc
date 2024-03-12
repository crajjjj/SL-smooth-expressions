Scriptname sslExpression_util Hidden

String Function GetSLSmoothVersionString() global
    Return "2.0.1"
EndFunction

int Function getSmoothDelay() global
	return 10
endfunction
int Function getSmoothSpeed() global
	return 5
endfunction
int Function getHardDelay() global
	return 0
endfunction
int Function getHardSpeed() global
	return 100
endfunction






;mfg modifier
;BlinkL 0
;BlinkR 1
;BrowDownL 2
;BrownDownR 3
;BrowInL 4
;BrowInR 5
;BrowUpL 6
;BrowUpR 7
;LookDown 8
;LookLeft 9
;LookRight 10
;LookUp 11
;SquintL 12
;SquintR 13
;for changing 2 values at the same time (e.g. eyes squint)
;set -1 to mod2 if not needed 
Function SmoothSetModifier(Actor act, Int mod1, Int mod2, Int str_dest, float strModifier = 1.0) global
	str_dest = (str_dest * strModifier) as Int
	mod1 = PapyrusUtil.ClampInt(mod1, 0, 13)
	mod2 = PapyrusUtil.ClampInt(mod1, -1, 13)
	str_dest = (str_dest * strModifier) as Int
	MfgConsoleFunc.SetModifier(act,mod1,str_dest)
	if mod2!= -1
		MfgConsoleFunc.SetModifier(act,mod2,str_dest)
	endif
	;PyramidUtils.SetPhonemeModifierSmooth(act, 1, mod1, mod2, str_dest, getSmoothSpeed(), getSmoothDelay())
EndFunction
Function SetModifier(Actor act, Int mod1, Int str_dest, float strModifier = 1.0) global
	str_dest = (str_dest * strModifier) as Int
	mod1 = PapyrusUtil.ClampInt(mod1, 0, 13)
	MfgConsoleFunc.SetModifier(act,mod1,str_dest)
	;PyramidUtils.SetPhonemeModifierSmooth(act, 1, mod1, -1, str_dest, getHardSpeed(), getHardDelay())
EndFunction
;Aah 0    BigAah 1
;BMP 2    ChjSh 3
;DST 4    Eee 5
;Eh 6     FV 7
;i 8      k 9
;N 10     Oh 11
;OohQ 12  R 13
;Th 14    W 15
;https://steamcommunity.com/sharedfiles/filedetails/?l=english&id=187155077
Function SmoothSetPhoneme(Actor act, Int number, Int str_dest, float modifier = 1.0) global
	str_dest = (str_dest * modifier) as Int
	number = PapyrusUtil.ClampInt(number, 0, 15)
	PyramidUtils.SetPhonemeModifierSmooth(act, 0, number, -1, str_dest, getSmoothSpeed(), getSmoothDelay())
EndFunction
Function SetPhoneme(Actor act, Int mod1, Int str_dest, float modifier = 1.0) global
	str_dest = (str_dest * modifier) as Int
	mod1 = PapyrusUtil.ClampInt(mod1, 0, 15)
	MfgConsoleFunc.SetPhoneme(act,mod1,str_dest)
	;PyramidUtils.SetPhonemeModifierSmooth(act, 0, mod1, -1, str_dest, getHardSpeed(), getHardDelay())
EndFunction

Function ApplyExpressionPreset(Actor akActor, float[] expression, bool openMouth) global
	MfgConsoleFunc.ApplyExpressionPreset(akActor, expression, openMouth, 0, 1, 1, 1) 
	; PyramidUtils.ApplyExpressionPreset(akActor, expression, openMouth, 0, 1, 1, 1, getSmoothSpeed(), getSmoothDelay())
EndFunction

;mfg expression
;Sets an expression to override any other expression other systems may give this actor.
;7 - Mood Neutral
;0 - Dialogue Anger 8 - Mood Anger 15 - Combat Anger
;1 - Dialogue Fear 9 - Mood Fear 16 - Combat Shout
;2 - Dialogue Happy 10 - Mood Happy
;3 - Dialogue Sad 11 - Mood Sad
;4 - Dialogue Surprise 12 - Mood Surprise
;5 - Dialogue Puzzled 13 - Mood Puzzled
;6 - Dialogue Disgusted 14 - Mood Disgusted
;aiCurrentStrength can be used if current expression is the same or we want to start with an offset
Function SmoothSetExpression(Actor act, Int aiMood, Int aiStrength, int aiCurrentStrength, float aiModifier = 1.0) global
	aiMood = PapyrusUtil.ClampInt(aiMood, 0, 16)
	MfgConsoleFunc.SetExpression(act,aiMood, aiStrength)
	;PyramidUtils.SetExpressionSmooth(act, aiMood, aiStrength, aiCurrentStrength, aiModifier, getSmoothSpeed(), getSmoothDelay())
EndFunction

Function resetMFG(Actor act) global
	MfgConsoleFunc.ResetPhonemeModifier(act)
	;PyramidUtils.SetPhonemeModifierSmooth(act, -1, 0, -1, 0, 0, 0)
endfunction

Function resetMFGSmooth(Actor ac) global
	MfgConsoleFunc.ResetMFGSmooth(ac, -1)
	;PyramidUtils.ResetMFGSmooth(ac,-1, getSmoothSpeed(),getSmoothDelay())
endfunction
Function resetPhonemesSmooth(Actor ac) global
	MfgConsoleFunc.ResetMFGSmooth(ac, 0)
	;PyramidUtils.ResetMFGSmooth(ac, 0, getSmoothSpeed(),getSmoothDelay())
endfunction
Function resetModifiersSmooth(Actor ac) global
	MfgConsoleFunc.ResetMFGSmooth(ac, 1)
	;PyramidUtils.ResetMFGSmooth(ac, 1, getSmoothSpeed(),getSmoothDelay())
endfunction









