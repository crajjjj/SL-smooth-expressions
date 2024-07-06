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

int[] MaleLipFixed
int[] FemaleLipFixed

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
	if !ActorRef
		return
	endIf

	if Phase <= Phases[Gender]
		Form akWorn = ActorRef.GetWornForm(0x80000000)
		Form akItem
		if !IsLipFixedPhase(Phase, Gender) || !IsMouthOpen(ActorRef)
			akItem = GetEquipmentPhase(Phase, Gender)
		endIf

		if !akItem
			if akWorn
				UnequipFaceItem(ActorRef, akWorn)
				Form EmptyItem = Game.GetFormFromFile(0x8FC65, "SexLab.esm") ; SexLabFaceItemEmpty "Empty" [ARMO:0808FC65]
				If EmptyItem && EmptyItem.GetType() == 26 && EmptyItem != akWorn && ActorRef.GetItemCount(EmptyItem) > 0
					ActorRef.EquipItem(EmptyItem, false, true)
				EndIf
			endIf
		endIf

		;	TransitPresetFloats(ActorRef, GetCurrentMFG(ActorRef), GenderPhase(Phase, Gender)) 
			ApplyPresetFloats(ActorRef, GenderPhase(Phase, Gender))

			EquipFaceItem(ActorRef, akItem)
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
	sslExpression_util.resetPhonemesSmooth(ActorRef)
endFunction
function ClearModifier(Actor ActorRef) global
	sslExpression_util.resetModifiersSmooth(ActorRef)
endFunction

function OpenMouth(Actor ActorRef) global
	OpenMouthScaled(ActorRef, 1.0)
endFunction

function OpenMouthScaled(Actor ActorRef, float Scale = 1.0) global
;	ClearPhoneme(ActorRef)
;	if SexLabUtil.GetConfig().HasMFGFix
;		MfgConsoleFunc.SetPhonemeModifier(ActorRef, 0, 1, SexLabUtil.GetConfig().OpenMouthSize) 
;	else
;		ActorRef.SetExpressionPhoneme(1, (SexLabUtil.GetConfig().OpenMouthSize as float / 100.0))
;	endIf
	bool isRealFemale = ActorRef.GetLeveledActorBase().GetSex() == 1
	int OpenMouthExpression = SexLabUtil.GetConfig().GetOpenMouthExpression(isRealFemale)
	float[] Phonemes = SexLabUtil.GetConfig().GetOpenMouthPhonemes(isRealFemale)											 
	Int i = 0
	Int s = 0
	Int value
	int MouthScale = (StorageUtil.GetFloatValue(ActorRef, "SexLab.MouthScale", 1.0) * Scale * 100) as Int
	if MouthScale < 20
		MouthScale = 20
	ElseIf MouthScale > 200
		MouthScale = 200
	EndIf
	; Set expression
	value = PapyrusUtil.ClampInt((MouthScale * (SexLabUtil.GetConfig().OpenMouthSize as float / 100.0)) as int, 0, 100)
	if (GetExpression(ActorRef, true) as int != OpenMouthExpression || GetExpression(ActorRef, false) != value as float / 100.0)
		sslExpression_util.SmoothSetExpression(ActorRef, OpenMouthExpression, value, 0)
	endIf
	; Set Phoneme
	Bool PhonemeUpdated = false
	while i < Phonemes.length
		value = PapyrusUtil.ClampInt((MouthScale * Phonemes[i]) as int, 0, 100)
		if (GetPhoneme(ActorRef, i) != value as float / 100.0)
			sslExpression_util.SmoothSetPhoneme(ActorRef,0,value)
			PhonemeUpdated = True
		endIf
		if Phonemes[i] >= Phonemes[s] ; seems to be required to prevet issues
			s = i
		endIf
		i += 1
	endWhile
	if PhonemeUpdated
		value = PapyrusUtil.ClampInt((MouthScale * Phonemes[s]) as int, 0, 100)
		sslExpression_util.SmoothSetPhoneme(ActorRef, s, value)
	endIf
	Utility.WaitMenuMode(0.1)
endFunction

function CloseMouth(Actor ActorRef) global
	ClearPhoneme(ActorRef)
	sslExpression_util.SmoothSetExpression(ActorRef,7,70, GetExpression(ActorRef,true) as Int)
	Utility.WaitMenuMode(0.1)
endFunction

bool function IsMouthOpen(Actor ActorRef) global
	bool isRealFemale = ActorRef.GetLeveledActorBase().GetSex() == 1
	int MinMouthScale = 20
	int OpenMouthExpression = SexLabUtil.GetConfig().GetOpenMouthExpression(isRealFemale)
;	return GetPhoneme(ActorRef, 1) >= MinMouthSize && (GetExpression(ActorRef, true) as Int == OpenMouthExpression && GetExpression(ActorRef, false) >= MinMouthSize)
	if GetExpression(ActorRef, true) as Int == OpenMouthExpression && GetExpression(ActorRef, false) >= (MinMouthScale * (SexLabUtil.GetConfig().OpenMouthSize as float / 100.0))
		return true
	endIf
	float[] Phonemes = SexLabUtil.GetConfig().GetOpenMouthPhonemes(isRealFemale)											 
	Int i = 0
	while i < Phonemes.length
		if (GetPhoneme(ActorRef, i) < (MinMouthScale * Phonemes[i]) / 100)
			return false
		endIf
		i += 1
	endWhile
	return true
endFunction

function ClearMFG(Actor ActorRef) global
	sslExpression_util.resetMFGSmooth(ActorRef)
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
	bool bMouthOpen = IsMouthOpen(ActorRef)
	float fMouthScale= StorageUtil.GetFloatValue(ActorRef, "SexLab.MouthScale", 1.0)
	if fMouthScale < 0.2
		fMouthScale = 0.2
	ElseIf fMouthScale > 2.0
		fMouthScale = 2.0
	EndIf
	int iMouthScale = (fMouthScale * 100) as Int
	; Set expression
	float currExpr = GetExpression(ActorRef, true)
	int currValue = PapyrusUtil.ClampInt((iMouthScale * GetExpression(ActorRef, false)) as int, 0, 100)
	if !bMouthOpen
		if currExpr != Preset[30]
			;reduce curr expression to 0
			sslExpression_util.SmoothSetExpression(ActorRef, currExpr as int, 0, currValue)
		endIf
	endIf
	sslExpression_util.ApplyExpressionPreset(ActorRef, Preset, bMouthOpen, fMouthScale)
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

int function GetLipFixedPhase(int Phase, int Gender)
	if Phase > 0 && Phase <= 5 
		if Gender == Male
			If !MaleLipFixed || MaleLipFixed.Length != 5
				MaleLipFixed = new int[5]
			EndIf
			return MaleLipFixed[Phase - 1]
		else
			If !FemaleLipFixed || FemaleLipFixed.Length != 5
				FemaleLipFixed = new int[5]	; Fix for external expressions like in the zbfSexLab
			EndIf
			return FemaleLipFixed[Phase - 1]
		endIf
	endIf
	return 0
endFunction

function SetLipFixedPhase(int Phase, int Gender, int value)
	if Phase > 0 && Phase <= 5 
		if Gender == Male || Gender == MaleFemale
			If !MaleLipFixed || MaleLipFixed.Length != 5
				MaleLipFixed = new int[5]	; Fix for external expressions like in the zbfSexLab
			EndIf
			MaleLipFixed[Phase - 1] = value
		endIf
		if Gender == Female || Gender == MaleFemale
			If !FemaleLipFixed || FemaleLipFixed.Length != 5
				FemaleLipFixed = new int[5]
			EndIf
			FemaleLipFixed[Phase - 1] = value
		endIf
	endIf
endFunction

int[] function GetLipFixedValues(int Gender)
	int[] Output = new int[5]
	int i = Output.Length
	while i
		i -= 1
		Output[i] = GetLipFixedPhase(i + 1, Gender)
	endWhile
	return Output
endFunction

function SetLipFixedValues(int Gender, int[] values)
	if values && values.Length <= 5 
		int i = values.Length
		while i
			i -= 1
			SetLipFixedPhase(i + 1, Gender, values[i]) 
		endWhile
	endIf
endFunction

bool function IsLipFixedPhase(int Phase, int Gender)
	return GetLipFixedPhase(Phase, Gender) > 0
endFunction

Form function GetEquipmentPhase(int Phase, int Gender)
	if Phase > 0 && Phase <= 5 
		if Gender == Male
			return MaleEquip[Phase - 1]
		else
			return FemaleEquip[Phase - 1]
		endIf
	endIf
	return none
endFunction

function SetEquipmentPhase(int Phase, int Gender, Form akItem)
	if Phase > 0 && Phase <= 5 
		if Gender == Male || Gender == MaleFemale
			MaleEquip[Phase - 1] = akItem
		endIf
		if Gender == Female || Gender == MaleFemale
			FemaleEquip[Phase - 1] = akItem
		endIf
	endIf
endFunction

Form[] function GetEquipments(int Gender)
	Form[] Output = new Form[5]
	int i = Output.Length
	while i
		i -= 1
		Output[i] = GetEquipmentPhase(i + 1, Gender)
	endWhile
	return Output
endFunction

function SetEquipments(int Gender, Form[] akItems)
	if akItems && akItems.Length <= 5 
		int i = akItems.Length
		while i
			i -= 1
			SetEquipmentPhase(i + 1, Gender, akItems[i]) 
		endWhile
	endIf
endFunction

Form function GetEquipmentByStrength(int Strength, int Gender)
	return GetEquipmentPhase(PickPhase(Strength, Gender), Gender)
endFunction

function SetEquipmentByStrength(int Strength, int Gender, Form akItem)
	SetEquipmentPhase(PickPhase(Strength, Gender), Gender, akItem)
endFunction

function EquipFaceItem(Actor ActorRef, Form akItem) global
	if !ActorRef || !akItem
		return
	endIf

	armor akArmor = akItem as Armor
	if akArmor && Math.LogicalAnd(akArmor.GetSlotMask(), 0x80000000) == 0x80000000 && ActorRef.GetItemCount(akItem) > 0
		if !ActorRef.IsEquipped(akItem)
			ActorRef.EquipItem(akItem, false, true)
			Debug.Trace("SEXLAB - EquipFaceItem("+akItem+") ItemSlotMask:"+akArmor.GetSlotMask()+" - "+ 0x80000000)
			Utility.Wait(0.1)
			if Game.GetCameraState() && !ActorRef.IsOnMount()
			;	if ActorRef == Game.GetPlayer()
					Game.UpdateThirdPerson()
			;	endif
				Utility.Wait(0.1)
			endif
			ActorRef.EquipItem(akItem, false, true)
		Else
			ActorRef.EquipItem(akItem, false, true)
			Debug.Trace("SEXLAB - EquipFaceItem("+akItem+") ItemSlotMask:"+akArmor.GetSlotMask()+" - "+ 0x80000000)
		endif
	endIf
endFunction

function UnequipWornFaceItem(Actor ActorRef, sslBaseExpression oldExpression, sslBaseExpression newExpression = none) global
	if !ActorRef || !oldExpression
		return
	endIf

	if oldExpression != newExpression
		Form akWorn = ActorRef.GetWornForm(0x80000000)
		int Gender = ActorRef.GetLeveledActorBase().GetSex()
		if akWorn && oldExpression.GetEquipments(Gender).Find(akWorn) != -1 ;&& (!newExpression || newExpression.GetEquipments(Gender).Find(akWorn) == -1)
			UnequipFaceItem(ActorRef, akWorn)
		;	ActorRef.RemoveItem(akWorn, 1, true)
		endIf
	endIf
endFunction

function UnequipFaceItem(Actor ActorRef, Form akItem = none) global
	if !ActorRef
		return
	endIf

	Form akWorn
	if akItem
		armor akArmor = akItem as Armor
		if akArmor && Math.LogicalAnd(akArmor.GetSlotMask(), 0x80000000) == 0x80000000
			akWorn = akItem
		endIf
	else
		akWorn = ActorRef.GetWornForm(0x80000000)
	endif
	if akWorn
		Form[] TempFaceItems = SexLabUtil.GetConfig().GetFaceItems()
		if !TempFaceItems || TempFaceItems.Find(akWorn) != -1
			int i = 25
			while i && ActorRef.IsEquipped(akWorn)
				ActorRef.UnequipItem(akWorn, false, true)
				Utility.Wait(0.1)
				i -= 1
			endWhile
			if Game.GetCameraState() && !ActorRef.IsOnMount()
			;	if ActorRef == Game.GetPlayer()
					Game.UpdateThirdPerson()
			;	endif
				Utility.Wait(0.1)
			endif
		endif
	endif
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
	else
		Preset[i] = PapyrusUtil.ClampInt(Preset[i] as int, 0, 16) as float
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
	if id < 1 ; 0 - Dialogue Anger cause errors on the SSE version of SetExpressionOverride()
		id = 8 ; 8 - Mood Anger
	endIf
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
		return Utility.ResizeFloatArray(Preset, 32, 0.0)
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
	; Extra effects
	MaleEquip   = new Form[5]
	FemaleEquip = new Form[5]
	MaleLipFixed   = new int[5]
	FemaleLipFixed = new int[5]

	parent.Initialize()
endFunction

bool function ExportJson()
	JsonUtil.ClearAll(File)

	JsonUtil.SetStringValue(File, "Name", Name)
	JsonUtil.SetIntValue(File, "Enabled", Enabled as int)

	JsonUtil.SetIntValue(File, "Normal", HasTag("Normal") as int)
	JsonUtil.SetIntValue(File, "Victim", HasTag("Victim") as int)
	JsonUtil.SetIntValue(File, "Aggressor", HasTag("Aggressor") as int)

	JsonUtil.StringListCopy(File, "Tags", GetTags())

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

	JsonUtil.FormListCopy(File, "MaleEquip", MaleEquip)
	JsonUtil.FormListCopy(File, "FemaleEquip", FemaleEquip)
	JsonUtil.IntListCopy(File, "MaleLipFixed", MaleLipFixed)
	JsonUtil.IntListCopy(File, "FemaleLipFixed", FemaleLipFixed)
	
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

	string[] currentTags = GetTags()
	int i = currentTags.Length
	While i > 0
		i -= 1
		RemoveTag(currentTags[i])
	EndWhile
	AddTags(JsonUtil.StringListToArray(File, "Tags"))

	if JsonUtil.FloatListCount(File, "Male1") == 32
		Male1 = new float[32]
		JsonUtil.FloatListSlice(File, "Male1", Male1)
		if Male1[30] > 14 || Male1[30] < 0 ; Prevent issues with OpenMouth
			Male1[30] = 8
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Male2") == 32
		Male2 = new float[32]
		JsonUtil.FloatListSlice(File, "Male2", Male2)
		if Male2[30] > 14 || Male2[30] < 0 ; Prevent issues with OpenMouth
			Male2[30] = 8
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Male3") == 32
		Male3 = new float[32]
		JsonUtil.FloatListSlice(File, "Male3", Male3)
		if Male3[30] > 14 || Male3[30] < 0 ; Prevent issues with OpenMouth
			Male3[30] = 8
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Male4") == 32
		Male4 = new float[32]
		JsonUtil.FloatListSlice(File, "Male4", Male4)
		if Male4[30] > 14 || Male4[30] < 0 ; Prevent issues with OpenMouth
			Male4[30] = 8
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Male5") == 32
		Male5 = new float[32]
		JsonUtil.FloatListSlice(File, "Male5", Male5)
		if Male5[30] > 14 || Male5[30] < 0 ; Prevent issues with OpenMouth
			Male5[30] = 8
		endIf
	endIf

	if JsonUtil.FloatListCount(File, "Female1") == 32
		Female1 = new float[32]
		JsonUtil.FloatListSlice(File, "Female1", Female1)
		if Female1[30] > 14 || Female1[30] < 0 ; Prevent issues with OpenMouth
			Female1[30] = 8
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Female2") == 32
		Female2 = new float[32]
		JsonUtil.FloatListSlice(File, "Female2", Female2)
		if Female2[30] > 14 || Female2[30] < 0 ; Prevent issues with OpenMouth
			Female2[30] = 8
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Female3") == 32
		Female3 = new float[32]
		JsonUtil.FloatListSlice(File, "Female3", Female3)
		if Female3[30] > 14 || Female3[30] < 0 ; Prevent issues with OpenMouth
			Female3[30] = 8
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Female4") == 32
		Female4 = new float[32]
		JsonUtil.FloatListSlice(File, "Female4", Female4)
		if Female4[30] > 14 || Female4[30] < 0 ; Prevent issues with OpenMouth
			Female4[30] = 8
		endIf
	endIf
	if JsonUtil.FloatListCount(File, "Female5") == 32
		Female5 = new float[32]
		JsonUtil.FloatListSlice(File, "Female5", Female5)
		if Female5[30] > 14 || Female5[30] < 0 ; Prevent issues with OpenMouth
			Female5[30] = 8
		endIf
	endIf

	if JsonUtil.FormListCount(File, "MaleEquip") == 5
		MaleEquip = new Form[5]
		JsonUtil.FormListSlice(File, "MaleEquip", MaleEquip)
	endIf
	if JsonUtil.FormListCount(File, "FemaleEquip") == 5
		FemaleEquip = new Form[5]
		JsonUtil.FormListSlice(File, "FemaleEquip", FemaleEquip)
	endIf

	if JsonUtil.IntListCount(File, "MaleLipFixed") == 5
		MaleLipFixed = new int[5]
		JsonUtil.IntListSlice(File, "MaleLipFixed", MaleLipFixed)
	endIf
	if JsonUtil.IntListCount(File, "FemaleLipFixed") == 5
		FemaleLipFixed = new int[5]
		JsonUtil.IntListSlice(File, "FemaleLipFixed", FemaleLipFixed)
	endIf

	CountPhases()

	JsonUtil.Unload(File, false, false)

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
