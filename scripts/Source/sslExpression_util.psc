Scriptname sslExpression_util Hidden

String Function GetVersionString() Global
    Return "2.0.0 SLPlus"
EndFunction

int Function getSmoothDelay() global
	return 15
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


Function SetPhoneme(Actor act, Int number, Int str_dest, float modifier = 1.0) global
	str_dest = (str_dest * modifier) as Int
	PyramidUtils.SetPhonemeModifierSmooth(act, 0, number, -1, str_dest, getHardSpeed(), getHardDelay())
EndFunction
Function SetModifier(Actor act, Int mod1, Int str_dest, float strModifier = 1.0) global
	str_dest = (str_dest * strModifier) as Int
	PyramidUtils.SetPhonemeModifierSmooth(act, 1, mod1, -1, str_dest, getHardSpeed(), getHardDelay())
EndFunction

; get phoneme/modifier/expression
int function GetPhoneme(Actor act, int id) global
	return PyramidUtils.GetPhonemeValue(act, id)
endfunction
int function GetModifier(Actor act, int id) global
	return PyramidUtils.GetModifierValue(act, id)
endfunction

; return expression value which is enabled. (enabled only one at a time.)
int function GetExpressionValue(Actor act) global
	return PyramidUtils.GetExpressionValue(act)
endfunction

; return expression ID which is enabled.
int function GetExpressionID(Actor act) global
	return PyramidUtils.GetExpressionId(act)
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
	PyramidUtils.SetPhonemeModifierSmooth(act, 1, mod1, mod2, str_dest, getSmoothSpeed(), getSmoothDelay())
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
	PyramidUtils.SetPhonemeModifierSmooth(act, 0, number, -1, str_dest, getSmoothSpeed(), getSmoothDelay())
EndFunction

Function ApplyExpressionPreset(Actor akActor, float[] expression, float exprStrModifier, float phStrModifier, bool openMouth) global
	 PyramidUtils.ApplyExpressionPreset(akActor, expression, openMouth, 0, exprStrModifier, 1, phStrModifier, getSmoothSpeed(), getSmoothDelay())
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
	PyramidUtils.SetExpressionSmooth(act, aiMood, aiStrength, aiCurrentStrength, aiModifier, getSmoothSpeed(), getSmoothDelay())
EndFunction

Function resetMFG(Actor act) global
	PyramidUtils.SetPhonemeModifierSmooth(act, -1, 0, -1, 0, 0, 0)
endfunction

Function resetMFGSmooth(Actor ac) global
	PyramidUtils.ResetMFGSmooth(ac,-1, getSmoothSpeed(),getSmoothDelay())
endfunction
Function resetPhonemesSmooth(Actor ac) global
	PyramidUtils.ResetMFGSmooth(ac, 0, getSmoothSpeed(),getSmoothDelay())
endfunction
Function resetModifiersSmooth(Actor ac) global
	PyramidUtils.ResetMFGSmooth(ac, 1, getSmoothSpeed(),getSmoothDelay())
endfunction









