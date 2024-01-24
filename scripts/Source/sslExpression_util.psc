Scriptname sslExpression_util Hidden

;Aah 0    BigAah 1
;BMP 2    ChjSh 3
;DST 4    Eee 5
;Eh 6     FV 7
;i 8      k 9
;N 10     Oh 11
;OohQ 12  R 13
;Th 14    W 15
;https://steamcommunity.com/sharedfiles/filedetails/?l=english&id=187155077
Function SmoothSetPhoneme(Actor act, Int id, Int str_dest, float modifier = 1.0) global
	Int t1 = MfgConsoleFunc.GetPhoneme(act, id)
	Int t2
	Int speed = 3
	;quick return if same
	if str_dest == t1
		return
	endif 
	str_dest = (str_dest * modifier) as Int
	While (t1 != str_dest)
		t2 = (str_dest - t1) / Math.Abs(str_dest - t1) as Int
		t1 = t1 + t2 * speed
		If ((str_dest - t1) / t2 < 0)
			t1 = str_dest
		EndIf
		MfgConsoleFunc.SetPhoneme(act, id, t1)
	EndWhile
EndFunction

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
	Int speed_blink_min = 25
	Int speed_blink_max = 60
	Int speed_eye_move_min = 5
	Int speed_eye_move_max = 15
	Int speed_blink = 0

	Int t1 = MfgConsoleFunc.GetModifier(act, mod1)
	Int t2
	Int t3
	Int speed
	str_dest = (str_dest * strModifier) as Int
	If (mod1 < 2)
		If (str_dest > 0)
			speed_blink = Utility.RandomInt(speed_blink_min, speed_blink_max)
			speed = speed_blink
		Else
			If (speed_blink > 0)
				speed = Round(speed_blink * 0.5)
			Else
				speed = Round(Utility.RandomInt(speed_blink_min, speed_blink_max) * 0.5)
			EndIf
		EndIf
	ElseIf (mod1 > 7 && mod1 < 12)
		speed = Utility.RandomInt(speed_eye_move_min, speed_eye_move_max)
	Else
		speed = 3
	EndIf
	While (t1 != str_dest)
		t2 = (str_dest - t1) / Math.Abs(str_dest - t1) as Int
		t1 = t1 + t2 * speed
		If ((str_dest - t1) / t2 < 0)
			t1 = str_dest
		EndIf
		If (!(mod2 < 0 || mod2 > 13))
			t3 = Utility.RandomInt(0, 1)
			MfgConsoleFunc.SetModifier(act, mod1 * t3 + mod2 * (1 - t3), t1)
			MfgConsoleFunc.SetModifier(act, mod2 * t3 + mod1 * (1 - t3), t1)
		Else
			MfgConsoleFunc.SetModifier(act, mod1, t1)
		EndIf
	EndWhile
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
Int Function SmoothSetExpression(Actor act, Int aiMood, Int aiStrength, int aiCurrentStrength = 0, float modifier = 1.0) global
	Int t2
	Int speed = 2
	aiStrength = (aiStrength * modifier) as Int
	While (aiCurrentStrength != aiStrength)
		t2 = (aiStrength - aiCurrentStrength) / Math.Abs(aiStrength - aiCurrentStrength) as Int
		aiCurrentStrength = aiCurrentStrength + t2 * speed
		If ((aiStrength - aiCurrentStrength) / t2 < 0)
			aiCurrentStrength = aiStrength
		EndIf
		act.SetExpressionOverride(aiMood, aiCurrentStrength)
	EndWhile
	return aiCurrentStrength
EndFunction

Int Function Round(Float f) global
	Return Math.Floor(f + 0.5)
EndFunction

Function resetMFGSmooth(Actor ac) global
	;blinks
	SmoothSetModifier(ac,0,1,0)
	
	;brows
	SmoothSetModifier(ac,2,3,0)
	SmoothSetModifier(ac,4,5,0)
	SmoothSetModifier(ac,6,7,0)

	;eyes
	SmoothSetModifier(ac,8,-1,0)
	SmoothSetModifier(ac,9,-1,0)
	SmoothSetModifier(ac,10,-1,0)
	SmoothSetModifier(ac,11,-1,0)

	;squints
	SmoothSetModifier(ac,12,13,0)
	
	;mouth
	int p = 0
	while (p <= 15)
		SmoothSetPhoneme(ac, p, 0)
		p = p + 1
	endwhile
	;expressions
	SmoothSetExpression(ac, MfgConsoleFunc.GetExpressionID(ac), 0, MfgConsoleFunc.GetExpressionValue(ac))
endfunction