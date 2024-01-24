scriptname sslBaseExpression extends sslBaseObject

;import PapyrusUtil

; Gender Types
int property Male       = 0 autoreadonly
int property Female     = 1 autoreadonly
int property MaleFemale = -1 autoreadonly
; MFG Types
int property Phoneme  = 0 autoreadonly
int property Modifier = 16 autoreadonly
int property Mood     = 30 autoreadonly
; ID loop ranges
int property PhonemeIDs  = 15 autoreadonly
int property ModifierIDs = 13 autoreadonly
int property MoodIDs     = 16 autoreadonly

string property File hidden
	string function get()
		return "../SexLab/Expression_"+Registry+".json"
	endFunction
endProperty

int[] Phases
int[] property PhaseCounts hidden
	int[] function get()
		return Phases
	endFunction
endProperty
int property PhasesMale hidden
	int function get()
		return Phases[Male]
	endFunction
endProperty
int property PhasesFemale hidden
	int function get()
		return Phases[Female]
	endFunction
endProperty

Form[] MaleEquip
Form[] FemaleEquip

float[] Male1
float[] Male2
float[] Male3
float[] Male4
float[] Male5

float[] Female1
float[] Female2
float[] Female3
float[] Female4
float[] Female5

; ------------------------------------------------------- ;
; --- Application Functions                           --- ;
; ------------------------------------------------------- ;

function Apply(Actor ActorRef, int Strength, int Gender)
	ApplyPhase(ActorRef, PickPhase(Strength, Gender), Gender)
endFunction

function ApplyPhase(Actor ActorRef, int Phase, int Gender)
	if Phase <= Phases[Gender]
	;	TransitPresetFloats(ActorRef, GetCurrentMFG(ActorRef), GenderPhase(Phase, Gender)) 
		ApplyPresetFloats(ActorRef, GenderPhase(Phase, Gender))
	endIf
endFunction

int function PickPhase(int Strength, int Gender)
	return PapyrusUtil.ClampInt(((PapyrusUtil.ClampInt(Strength, 1, 100) * Phases[Gender]) / 100), 1, Phases[Gender])
endFunction

float[] function SelectPhase(int Strength, int Gender)
	return GenderPhase(PickPhase(Strength, Gender), Gender)
endFunction 

; ------------------------------------------------------- ;
; --- Global Utilities                                --- ;
; ------------------------------------------------------- ;



float function GetModifier(Actor ActorRef, int id) global native
float function GetPhoneme(Actor ActorRef, int id) global native
float function GetExpression(Actor ActorRef, bool getId) global native

function ClearPhoneme(Actor ActorRef) global
	bool HasMFG = SexLabUtil.GetConfig().HasMFGFix
	int p
	if HasMFG
		while (p <= 15)
			SmoothSetPhoneme(ActorRef, p, 0)
			p = p + 1
		endwhile
	else
		while p <= 15
			ActorRef.SetExpressionPhoneme(p, 0.0)
			p += 1
		endWhile
	endIf
endFunction
function ClearModifier(Actor ActorRef) global
	bool HasMFG = SexLabUtil.GetConfig().HasMFGFix
	int i
	if HasMFG
		;blinks
		SmoothSetModifier(ActorRef,0,1,0)
	
		;brows
		SmoothSetModifier(ActorRef,2,3,0)
		SmoothSetModifier(ActorRef,4,5,0)
		SmoothSetModifier(ActorRef,6,7,0)

		;eyes
		SmoothSetModifier(ActorRef,8,-1,0)
		SmoothSetModifier(ActorRef,9,-1,0)
		SmoothSetModifier(ActorRef,10,-1,0)
		SmoothSetModifier(ActorRef,11,-1,0)

		;squints
		SmoothSetModifier(ActorRef,12,13,0)
	else
		while i <= 13
			ActorRef.SetExpressionModifier(i, 0.0)
			i += 1
		endWhile
	endIf
endFunction

function OpenMouth(Actor ActorRef) global
;	ClearPhoneme(ActorRef)
;	if SexLabUtil.GetConfig().HasMFGFix
;		MfgConsoleFunc.SetPhonemeModifier(ActorRef, 0, 1, SexLabUtil.GetConfig().OpenMouthSize) 
;	else
;		ActorRef.SetExpressionPhoneme(1, (SexLabUtil.GetConfig().OpenMouthSize as float / 100.0))
;	endIf
	bool isRealFemale = ActorRef.GetLeveledActorBase().GetSex() == 1
	int OpenMouthExpression = SexLabUtil.GetConfig().GetOpenMouthExpression(isRealFemale)
	int OpenMouthSize = SexLabUtil.GetConfig().OpenMouthSize
	float[] Phonemes = SexLabUtil.GetConfig().GetOpenMouthPhonemes(isRealFemale)											 
	Int i = 0
	Int s = 0
	bool HasMFG = SexLabUtil.GetConfig().HasMFGFix
	while i < Phonemes.length
		if (GetPhoneme(ActorRef, i) != Phonemes[i])
			if HasMFG
				SmoothSetModifier(ActorRef,0,-1,PapyrusUtil.ClampInt((OpenMouthSize * Phonemes[i]) as int, 0, 100))
			else
				ActorRef.SetExpressionPhoneme(i, PapyrusUtil.ClampInt((OpenMouthSize * Phonemes[i]) as int, 0, 100) as float / 100.0)
			endIf
		endIf
		if Phonemes[i] >= Phonemes[s] ; seems to be required to prevet issues
			s = i
		endIf
		i += 1
	endWhile
	if HasMFG
		SmoothSetPhoneme(ActorRef, s, (Phonemes[s] * 100.0) as int) ; Oldrim
	else
		ActorRef.SetExpressionPhoneme(s, Phonemes[s]) ; is supouse to be / 100.0 already thanks SetIndex function
	endIf
	if (GetExpression(ActorRef, true) as int == OpenMouthExpression || GetExpression(ActorRef, false) != OpenMouthSize as float / 100.0)
		SmoothSetExpression(ActorRef,OpenMouthExpression, OpenMouthSize, GetExpression(ActorRef,true) as Int)
	endIf
	Utility.WaitMenuMode(0.1)
endFunction

function CloseMouth(Actor ActorRef) global
	ClearPhoneme(ActorRef)
	SmoothSetExpression(ActorRef,7,70, GetExpression(ActorRef,true) as Int)
	Utility.WaitMenuMode(0.1)
endFunction

bool function IsMouthOpen(Actor ActorRef) global
	bool isRealFemale = ActorRef.GetLeveledActorBase().GetSex() == 1
	int OpenMouthExpression = SexLabUtil.GetConfig().GetOpenMouthExpression(isRealFemale)
	float MinMouthSize = (SexLabUtil.GetConfig().OpenMouthSize * 0.01) - 0.1
;	return GetPhoneme(ActorRef, 1) >= MinMouthSize && (GetExpression(ActorRef, true) as Int == OpenMouthExpression && GetExpression(ActorRef, false) >= MinMouthSize)
	if GetExpression(ActorRef, true) as Int == OpenMouthExpression && GetExpression(ActorRef, false) >= MinMouthSize
		return true
	endIf
	float[] Phonemes = SexLabUtil.GetConfig().GetOpenMouthPhonemes(isRealFemale)											 
	Int i = 0
	while i < Phonemes.length
		if (GetPhoneme(ActorRef, i) < (MinMouthSize * Phonemes[i]))
			return false
		endIf
		i += 1
	endWhile
	return true
endFunction

function ClearMFG(Actor ActorRef) global
	if SexLabUtil.GetConfig().HasMFGFix
		resetMFGSmooth(ActorRef)
	else
		ActorRef.ClearExpressionOverride()
		ClearPhoneme(ActorRef)
		ClearModifier(ActorRef)
	endIf
endFunction

function TransitPresetFloats(Actor ActorRef, float[] FromPreset, float[] ToPreset, float Speed = 1.0, float Time = 1.0) global 
	if !ActorRef || FromPreset.Length < 32 || ToPreset.Length < 32
		return
	endIf
	if Speed < 0.1
		ApplyPresetFloats(ActorRef, ToPreset)
		return
	endIf
	int n = (10 * Speed) as int
	int p
	while p < n
		float[] Preset = new float[32]
		int i = Preset.Length
		while i > 0
			i -= 1
			if i > 29
				Preset[i] = ToPreset[i]
			else
				Preset[i] = ((ToPreset[i] - FromPreset[i]) / n) * p + FromPreset[i]
			endIf
		endWhile
		ApplyPresetFloats(ActorRef, Preset)
		Utility.Wait((Time / 10) / Speed)
		p += 1
	endWhile
	ApplyPresetFloats(ActorRef, ToPreset)
endFunction

function ApplyPresetFloats(Actor ActorRef, float[] Preset) global 
	if !ActorRef || Preset.Length < 32
		return
	endIf

	int i
	int p
	int m
	; MFG
	bool IsMouthOpen = IsMouthOpen(ActorRef)
	bool HasMFG = SexLabUtil.GetConfig().HasMFGFix
	; Set Phoneme
	if IsMouthOpen
		i = 16 ; escape the Phoneme to prevent override the MouthOpen
	else
		int s
		while p <= 15
			if GetPhoneme(ActorRef, p) != Preset[i]
				if HasMFG
					SmoothSetPhoneme(ActorRef, p, (Preset[i] * 100.0) as int) ; Oldrim
				else
					ActorRef.SetExpressionPhoneme(p, Preset[i]) ; is supouse to be / 100.0 already thanks SetIndex function
				endIf
			endIf
			if Preset[p] >= Preset[s] ; seems to be required to prevet issues
				s = p
			endIf
			i += 1
			p += 1
		endWhile
		if HasMFG
			SmoothSetPhoneme(ActorRef, s, (Preset[s] * 100.0) as int) ; Oldrim
		else
			ActorRef.SetExpressionPhoneme(s, Preset[s]) ; is supouse to be / 100.0 already thanks SetIndex function
		endIf
		
	endIf
	; Set Modifers
	while m <= 13
		if GetModifier(ActorRef, m) != Preset[i]
			if HasMFG
				;both eyes involved
				if (m == 0 || m == 2 || m == 4 || m == 6 || m == 12)
					if Preset[i] == Preset[i+1]
						SmoothSetModifier(ActorRef, m, m+1, (Preset[i] * 100.0) as int)
						i += 1
						m += 1
					else
						SmoothSetModifier(ActorRef, m, -1, (Preset[i] * 100.0) as int)
					endif 
				else
					SmoothSetModifier(ActorRef, m, -1, (Preset[i] * 100.0) as int)
				endif
			else
				ActorRef.SetExpressionModifier(m, Preset[i]) ; is supouse to be / 100.0 already thanks SetIndex function
			endIf
		endif
		i += 1
		m += 1
	endWhile
	; Set expression
	if (GetExpression(ActorRef, true) == Preset[30] || GetExpression(ActorRef, false) != Preset[31]) && !IsMouthOpen
		SmoothSetExpression(ActorRef,Preset[30] as int, (Preset[31] * 100.0) as int, 0)
	endIf
endFunction


float[] function GetCurrentMFG(Actor ActorRef) global
	float[] Preset = new float[32]
	int i
	; Get Phoneme
	int p
	while p <= 15
		Preset[i] = GetPhoneme(ActorRef, p) ; 0.0 - 1.0
		i += 1
		p += 1
	endWhile
	; Get Modifers
	int m
	while m <= 13
		Preset[i] = GetModifier(ActorRef, m) ; 0.0 - 1.0
		i += 1
		m += 1
	endWhile
	; Get Exression/Mood type and value
	Preset[30] = GetExpression(ActorRef, true)  ; 0 - 16
	Preset[31] = GetExpression(ActorRef, false) ; 0.0 - 1.0
	return Preset
endFunction

; ------------------------------------------------------- ;
; --- Editing Functions                               --- ;
; ------------------------------------------------------- ;

function SetIndex(int Phase, int Gender, int Mode, int id, int value)
	float[] Preset = GenderPhase(Phase, Gender)
	int i = Mode+id
	if value > 100
		value = 100
	elseIf value < 0
		value = 0
	endIf
	Preset[i] = value as float
	if i != 30
		Preset[i] = Preset[i] / 100.0
	endIf
	SetPhase(Phase, Gender, Preset)
endFunction

function SetPreset(int Phase, int Gender, int Mode, int id, int value)
	if Mode == Mood
		SetMood(Phase, Gender, id, value)
	elseif Mode == Modifier
		SetModifier(Phase, Gender, id, value)
	elseif Mode == Phoneme
		SetPhoneme(Phase, Gender, id, value)
	endIf
endFunction

function SetMood(int Phase, int Gender, int id, int value)
	if Gender == Female || Gender == MaleFemale
		SetIndex(Phase, Female, Mood, 0, id)
		SetIndex(Phase, Female, Mood, 1, value)
	endIf
	if Gender == Male || Gender == MaleFemale
		SetIndex(Phase, Male, Mood, 0, id)
		SetIndex(Phase, Male, Mood, 1, value)
	endIf
endFunction

function SetModifier(int Phase, int Gender, int id, int value)
	if Gender == Female || Gender == MaleFemale
		SetIndex(Phase, Female, Modifier, id, value)
	endIf
	if Gender == Male || Gender == MaleFemale
		SetIndex(Phase, Male, Modifier, id, value)
	endIf
endFunction

function SetPhoneme(int Phase, int Gender, int id, int value)
	if Gender == Female || Gender == MaleFemale
		SetIndex(Phase, Female, Phoneme, id, value)
	endIf
	if Gender == Male || Gender == MaleFemale
		SetIndex(Phase, Male, Phoneme, id, value)
	endIf
endFunction

function EmptyPhase(int Phase, int Gender)
	float[] Preset = new float[32]
	SetPhase(Phase, Gender, Preset)
	Phases[Gender] = PapyrusUtil.ClampInt((Phases[Gender] - 1), 0, 5)
	CountPhases()
	if Phases[0] == 0 && Phases[1] == 0
		Enabled = false
	endIf
endFunction

function AddPhase(int Phase, int Gender)
	float[] Preset = GenderPhase(Phase, Gender)
	if Preset[31] == 0.0 || Preset[30] < 0.0 || Preset[30] > 16.0
		Preset[30] = 7.0
		Preset[31] = 0.5
	endIf
	SetPhase(Phase, Gender, Preset)
	Phases[Gender] = PapyrusUtil.ClampInt((Phases[Gender] + 1), 0, 5)
	Enabled = true
endFunction

; ------------------------------------------------------- ;
; --- Phase Accessors                                 --- ;
; ------------------------------------------------------- ;

bool function HasPhase(int Phase, Actor ActorRef)
	if !ActorRef || Phase < 1
		return false
	endIf
	int Gender = ActorRef.GetLeveledActorBase().GetSex()
	return (Gender == 1 && Phase <= PhasesFemale) || (Gender == 0 && Phase <= PhasesMale)
endFunction

float[] function GenderPhase(int Phase, int Gender)
	float[] Preset
	if Gender == Male
		if Phase == 1
			Preset = Male1
		elseIf Phase == 2
			Preset = Male2
		elseIf Phase == 3
			Preset = Male3
		elseIf Phase == 4
			Preset = Male4
		elseIf Phase == 5
			Preset = Male5
		endIf
	else
		if Phase == 1
			Preset = Female1
		elseIf Phase == 2
			Preset = Female2
		elseIf Phase == 3
			Preset = Female3
		elseIf Phase == 4
			Preset = Female4
		elseIf Phase == 5
			Preset = Female5
		endIf
	endIf
	if Preset.Length != 32
		return new float[32]
	endIf
	return Preset
endFunction

function SetPhase(int Phase, int Gender, float[] Preset)
	if Gender == Male
		if Phase == 1
			Male1 = Preset
		elseIf Phase == 2
			Male2 = Preset
		elseIf Phase == 3
			Male3 = Preset
		elseIf Phase == 4
			Male4 = Preset
		elseIf Phase == 5
			Male5 = Preset
		endIf
	else
		if Phase == 1
			Female1 = Preset
		elseIf Phase == 2
			Female2 = Preset
		elseIf Phase == 3
			Female3 = Preset
		elseIf Phase == 4
			Female4 = Preset
		elseIf Phase == 5
			Female5 = Preset
		endIf
	endIf
endFunction

float[] function GetPhonemes(int Phase, int Gender)
	float[] Output = new float[16]
	float[] Preset = GenderPhase(Phase, Gender)
	int i
	while i <= PhonemeIDs
		Output[i] = Preset[Phoneme + i]
		i += 1
	endWhile
	return Output
endFunction

float[] function GetModifiers(int Phase, int Gender)
	float[] Output = new float[14]
	float[] Preset = GenderPhase(Phase, Gender)
	int i
	while i <= ModifierIDs
		Output[i] = Preset[Modifier + i]
		i += 1
	endWhile
	return Output
endFunction

int function GetMoodType(int Phase, int Gender)
	return GenderPhase(Phase, Gender)[30] as int
endFunction

int function GetMoodAmount(int Phase, int Gender)
	return (GenderPhase(Phase, Gender)[31] * 100.0) as int
endFunction

int function GetIndex(int Phase, int Gender, int Mode, int id)
	return (GenderPhase(Phase, Gender)[Mode + id] * 100.0) as int
endFunction

; ------------------------------------------------------- ;
; --- System Use                                      --- ;
; ------------------------------------------------------- ;

int function ValidatePreset(float[] Preset)
	if Preset.Length == 32 ; Must be appropiate size
		int i = 30
		while i
			i -= 1
			if Preset[i] > 0.0
				return 1 ; Must have alteast one phoneme or modifier value
			endIf
		endWhile
	endIf
	return 0
endFunction

int[] function ToIntArray(float[] FloatArray) global
	int[] Output = new int[32]
	int i = FloatArray.Length
	while i
		i -= 1
		if i == 30
			Output[i] = FloatArray[i] as int
		else
			Output[i] = (FloatArray[i] * 100.0) as int
		endIf
	endWhile
	return Output
endFunction

float[] function ToFloatArray(int[] IntArray) global
	float[] Output = new float[32]
	int i = IntArray.Length
	while i
		i -= 1
		if i == 30
			Output[i] = IntArray[i] as float
		else
			Output[i] = (IntArray[i] as float) / 100.0
		endIf
	endWhile
	return Output
endFunction

function CountPhases()
	; Only count the phase if previous phase existed.
	Phases = new int[2]	
	; Male phases
	Phases[0] = ValidatePreset(Male1)
	if Phases[0] == 1
		Phases[0] = Phases[0] + ValidatePreset(Male2)
	endIf
	if Phases[0] == 2
		Phases[0] = Phases[0] + ValidatePreset(Male3)
	endIf
	if Phases[0] == 3
		Phases[0] = Phases[0] + ValidatePreset(Male4)
	endIf
	if Phases[0] == 4
		Phases[0] = Phases[0] + ValidatePreset(Male5)
	endIf
	; Female phases
	Phases[1] = ValidatePreset(Female1)
	if Phases[1] == 1
		Phases[1] = Phases[1] + ValidatePreset(Female2)
	endIf
	if Phases[1] == 2
		Phases[1] = Phases[1] + ValidatePreset(Female3)
	endIf
	if Phases[1] == 3
		Phases[1] = Phases[1] + ValidatePreset(Female4)
	endIf
	if Phases[1] == 4
		Phases[1] = Phases[1] + ValidatePreset(Female5)
	endIf
	; Enable it if phases are present
	Enabled = Phases[0] > 0 || Phases[1] > 0
endFunction

function Save(int id = -1)
	CountPhases()
	Log(Name, "Expressions["+id+"]")
	parent.Save(id)
endFunction

function Initialize()
	; Gender phase counts
	Phases = new int[2]
	; Extra phase equips
	MaleEquip   = new Form[5]
	FemaleEquip = new Form[5]
	; Individual Phases
	Male1   = Utility.CreateFloatArray(0)
	Male2   = Utility.CreateFloatArray(0)
	Male3   = Utility.CreateFloatArray(0)
	Male4   = Utility.CreateFloatArray(0)
	Male5   = Utility.CreateFloatArray(0)
	Female1 = Utility.CreateFloatArray(0)
	Female2 = Utility.CreateFloatArray(0)
	Female3 = Utility.CreateFloatArray(0)
	Female4 = Utility.CreateFloatArray(0)
	Female5 = Utility.CreateFloatArray(0)
	parent.Initialize()
endFunction

bool function ExportJson()
	JsonUtil.ClearAll(File)

	JsonUtil.SetStringValue(File, "Name", Name)
	JsonUtil.SetIntValue(File, "Enabled", Enabled as int)

	JsonUtil.SetIntValue(File, "Normal", HasTag("Normal") as int)
	JsonUtil.SetIntValue(File, "Victim", HasTag("Victim") as int)
	JsonUtil.SetIntValue(File, "Aggressor", HasTag("Aggressor") as int)

	JsonUtil.FloatListCopy(File, "Male1", Male1)
	JsonUtil.FloatListCopy(File, "Male2", Male2)
	JsonUtil.FloatListCopy(File, "Male3", Male3)
	JsonUtil.FloatListCopy(File, "Male4", Male4)
	JsonUtil.FloatListCopy(File, "Male5", Male5)
	JsonUtil.FloatListCopy(File, "Female1", Female1)
	JsonUtil.FloatListCopy(File, "Female2", Female2)
	JsonUtil.FloatListCopy(File, "Female3", Female3)
	JsonUtil.FloatListCopy(File, "Female4", Female4)
	JsonUtil.FloatListCopy(File, "Female5", Female5)

	return JsonUtil.Save(File, true)
endFunction

bool function ImportJson()
	if JsonUtil.GetStringValue(File, "Name") == "" || (JsonUtil.FloatListCount(File, "Female1") != 32 && JsonUtil.FloatListCount(File, "Male1") != 32)
		Log("Failed to import "+File)
		return false
	endIf

	Name = JsonUtil.GetStringValue(File, "Name", Name)
	Enabled = JsonUtil.GetIntValue(File, "Enabled", Enabled as int) as bool

	AddTagConditional("Normal", JsonUtil.GetIntValue(File, "Normal", HasTag("Normal") as int) as bool)
	AddTagConditional("Victim", JsonUtil.GetIntValue(File, "Victim", HasTag("Victim") as int) as bool)
	AddTagConditional("Aggressor", JsonUtil.GetIntValue(File, "Aggressor", HasTag("Aggressor") as int) as bool)

	if JsonUtil.FloatListCount(File, "Male1") == 32
		Male1 = new float[32]
		JsonUtil.FloatListSlice(File, "Male1", Male1)
		if Male1[30] > 14 ; Prevent issues with OpenMouth
			Male1[30] = 0
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Male2") == 32
		Male2 = new float[32]
		JsonUtil.FloatListSlice(File, "Male2", Male2)
		if Male2[30] > 14 ; Prevent issues with OpenMouth
			Male2[30] = 0
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Male3") == 32
		Male3 = new float[32]
		JsonUtil.FloatListSlice(File, "Male3", Male3)
		if Male3[30] > 14 ; Prevent issues with OpenMouth
			Male3[30] = 0
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Male4") == 32
		Male4 = new float[32]
		JsonUtil.FloatListSlice(File, "Male4", Male4)
		if Male4[30] > 14 ; Prevent issues with OpenMouth
			Male4[30] = 0
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Male5") == 32
		Male5 = new float[32]
		JsonUtil.FloatListSlice(File, "Male5", Male5)
		if Male5[30] > 14 ; Prevent issues with OpenMouth
			Male5[30] = 0
		endIf
	endIf

	if JsonUtil.FloatListCount(File, "Female1") == 32
		Female1 = new float[32]
		JsonUtil.FloatListSlice(File, "Female1", Female1)
		if Female1[30] > 14 ; Prevent issues with OpenMouth
			Female1[30] = 0
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Female2") == 32
		Female2 = new float[32]
		JsonUtil.FloatListSlice(File, "Female2", Female2)
		if Female2[30] > 14 ; Prevent issues with OpenMouth
			Female2[30] = 0
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Female3") == 32
		Female3 = new float[32]
		JsonUtil.FloatListSlice(File, "Female3", Female3)
		if Female3[30] > 14 ; Prevent issues with OpenMouth
			Female3[30] = 0
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Female4") == 32
		Female4 = new float[32]
		JsonUtil.FloatListSlice(File, "Female4", Female4)
		if Female4[30] > 14 ; Prevent issues with OpenMouth
			Female4[30] = 0
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Female5") == 32
		Female5 = new float[32]
		JsonUtil.FloatListSlice(File, "Female5", Female5)
		if Female5[30] > 14 ; Prevent issues with OpenMouth
			Female5[30] = 0
		endIf
	endIf

	CountPhases()

	return true
endFunction

; ------------------------------------------------------- ;
; --- DEPRECATED                                      --- ;
; ------------------------------------------------------- ;

function ApplyTo(Actor ActorRef, int Strength = 50, bool IsFemale = true, bool OpenMouth = false)
	Apply(ActorRef, Strength, IsFemale as int)
	if OpenMouth
		OpenMouth(ActorRef)
	endIf
endFunction

int[] function GetPhase(int Phase, int Gender)
	return ToIntArray(GenderPhase(Phase, Gender))
endFunction

int[] function PickPreset(int Strength, bool IsFemale)
	return GetPhase(CalcPhase(Strength, IsFemale), (IsFemale as int))
endFunction

int function CalcPhase(int Strength, bool IsFemale)
	return PickPhase(Strength, (IsFemale as int))
endFunction

function ApplyPreset(Actor ActorRef, int[] Preset) global
	ApplyPresetFloats(ActorRef, ToFloatArray(Preset))
endFunction

; ------------------------------------------------------- ;
; --- REFACTOR DEPRECATION                            --- ;
; ------------------------------------------------------- ;

; int[] function GetPhase(int Phase, int Gender)
; endFunction
; function SetPhase(int Phase, int Gender, int[] Preset)
; endFunction
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
	Int t1 = MfgConsoleFunc.GetPhoneme(act, number)
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
		MfgConsoleFunc.SetPhoneme(act, number, t1)
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
Int Function SmoothSetExpression(Actor act, Int number, Int exp_dest, int exp_value, float modifier = 1.0) global
	int safeguard = 0
	Int t2
	Int speed = 2
	exp_dest = (exp_dest * modifier) as Int
	While (exp_value != exp_dest)
		t2 = (exp_dest - exp_value) / Math.Abs(exp_dest - exp_value) as Int
		exp_value = exp_value + t2 * speed
		If ((exp_dest - exp_value) / t2 < 0)
			exp_value = exp_dest
		EndIf
		act.SetExpressionOverride(number, exp_value)
	EndWhile
	return exp_value
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