params ["_unit", "_didJIP"];

[ "InitializePlayer", [_unit] ] call BIS_fnc_dynamicGroups; //clientside initialization of the vanilla U-menu feature for group management 



//F1 key:  Toggle the mission status hint message loop
sxf_fnc_handleKey_F1 = {
	_temp = player getVariable ['sxf_bLoopEnabled', false];
	if (_temp) then {hintSilent '';};
	playSound ( ['AddItemFailed', 'AddItemOK'] select !_temp );
	player setVariable ['sxf_bLoopEnabled', !_temp, true];
};
//F2 key:  Holster the primary weapon
sxf_fnc_handleKey_F2 = {
	player action ['SwitchWeapon', player, player, 99];
};



//assign special key bindings for this mission
waituntil {!(IsNull (findDisplay 46))};
(findDisplay 46) displayRemoveAllEventHandlers "KeyDown";
(findDisplay 46) displayAddEventHandler [
	"KeyDown", 
	{
			if ( (_this select 1) in ( (actionKeys 'User1') + [0x3b] ) ) then {call sxf_fnc_handleKey_F1;};
			if ( (_this select 1) in ( (actionKeys 'User2') + [0x3c] ) ) then {call sxf_fnc_handleKey_F2;};
	}
];
[] spawn {	//display the helpful reminder early on into the mission
	sleep 90;
	hint parseText (
		"<br/><t size='1.5' color='#E28014' align='center'>Quick reminder!</t>" +
		"<br/><br/>" +
		format["<br/><t align='left'>Press <t color='%1'>%2</t> or <t color='%1'>%3</t> to toggle the mission status loop message.</t>",
			"#e285e0",
			keyName 0x3b, 
			[keyName (actionKeys "User1" select 0), "--UNBOUND--"] select (count actionKeys "User1" <= 0)
		] +
		"<br/><br/>" +
		format["<br/><t align='left'>Press <t color='%1'>%2</t> or <t color='%1'>%3</t> to holster your weapon so that you can run faster and save stamina.</t>",
			"#6db9e2",
			keyName 0x3c, 
			[keyName (actionKeys "User2" select 0), "--UNBOUND--"] select (count actionKeys "User2" <= 0)
		] +
		"<br/><br/><br/>"
	);
};



[
	_unit,
	briefingName,
	2,
	3,
	0,
	1
] call BIS_fnc_establishingShot;



//intro hint briefing message
hint parseText (
	format["<br/><t size='1.5' color='#E28014' align='center'>%1</t>", briefingName] +
	"<br/>by sixtyfour<br/>" +
	"<br/><br/>" +
	"<br/>Mission Settings:" +
	format ["<br/><t align='left'>Toggle 'Status Loop' Key:</t><t align='right'>%1 or %2</t>", 
		keyImage 0x3b, 
		keyImage (actionKeys "User1" select 0)
	] +
	"<br/><t align='left'>Medical Preset:</t><t align='right'>Vanilla Revive</t>" +
	"<br/><t align='left'>Bleed Out Duration:</t><t align='right'>3 minutes</t>" +
	"<br/><t align='left'>Revive Duration:</t><t align='right'>10 seconds</t>" +
	"<br/><t align='left'>Who Can Revive?:</t><t align='right'>Medics only</t>" +
	"<br/><t align='left'>First-Aid Kit required?:</t><t align='right'>No</t>" +
	"<br/><t align='left'>Consume First-Aid Kit?</t><t align='right'>No</t>" +
	"<br/><t align='left'>On Death:</t><t align='right'>Switch to Spectator</t>" +
	"<br/><t align='left'>AI Difficulty level:</t><t align='right'>4 of 7</t>" + 
	"<br/><br/><br/>"
);