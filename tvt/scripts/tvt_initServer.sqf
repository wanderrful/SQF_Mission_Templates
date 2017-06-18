enableEnvironment false;

sv_debug = (count call BIS_fnc_listPlayers <= 1); publicVariable "sv_debug";

[ "Initialize" ] call BIS_fnc_dynamicGroups; //serverside initialization of the vanilla U-menu feature for group management



//*** Handle the win/fail conditions for all teams
sxf_fnc_handleTeamWins = {
	//_this must be a team (e.g. blufor, opfor, independent, civilian)
	"MissionSuccess" remoteExec ["BIS_fnc_showNotification", _this];
	"MissionSuccessObjectiveCompleted" remoteExec ["playSound", _this];
	( parseText format["<br/><br/><t size='1.5' color='#E28014' align='center'>Mission Success</t><br/>Objective Completed<br/><br/><br/><br/>", nil] ) remoteExec ["hint", _this];
};
sxf_fnc_handleTeamLoses = {
	//_this must be a team (e.g. blufor, opfor, independent, civilian)
	"MissionFail" remoteExec ["BIS_fnc_showNotification", _this];
	"MissionFailureYourTeamWasWipedOut" remoteExec ["playSound", _this];
	( parseText format["<br/><br/><t size='1.5' color='#E28014' align='center'>Mission Failure</t><br/>Your team was wiped out.<br/><br/><br/><br/>", nil] ) remoteExec ["hint", _this];
};
if (!(blufor countSide allUnits isEqualTo 0)) then {
	[ "itemAdd", [ 
		"checkBluforWins", {
			blufor call sxf_fnc_handleTeamWins;
			opfor call sxf_fnc_handleTeamLoses;		
			independent call sxf_fnc_handleTeamLoses;
			civilian call sxf_fnc_handleTeamLoses;
			"SideScore" call BIS_fnc_endMissionServer;
			["itemRemove", ["checkBluforWins"]] call BIS_fnc_loop;
		}, 
		1, "seconds", { opfor countSide allUnits isEqualTo 0 && {independent countSide allUnits isEqualTo 0} }
	] ] call BIS_fnc_loop; 
};
if (!(opfor countSide allUnits isEqualTo 0)) then {
	[ "itemAdd", [ 
		"checkOpforWins", {
			blufor call sxf_fnc_handleTeamLoses;
			opfor call sxf_fnc_handleTeamWins;		
			independent call sxf_fnc_handleTeamLoses;
			"SideScore" call BIS_fnc_endMissionServer;
			["itemRemove", ["checkOpforWins"]] call BIS_fnc_loop;
		}, 
		1, "seconds", { blufor countSide allUnits isEqualTo 0 && {independent countSide allUnits isEqualTo 0} }
	] ] call BIS_fnc_loop; 
};
if (!(independent countSide allUnits isEqualTo 0)) then {
	[ "itemAdd", [ 
		"checkIndependentWins", {
			blufor call sxf_fnc_handleTeamLoses;
			opfor call sxf_fnc_handleTeamLoses;		
			independent call sxf_fnc_handleTeamWins;
			"SideScore" call BIS_fnc_endMissionServer;
			["itemRemove", ["checkIndependentWins"]] call BIS_fnc_loop;
		}, 
		1, "seconds", { blufor countSide allUnits isEqualTo 0 && {opfor countSide allUnits isEqualTo 0} }
	] ] call BIS_fnc_loop; 
};



//*** When a player dies, strip them of all their equipment so that nothing can be stolen!
addMissionEventHandler [
	"EntityKilled",
	{
		params ["_killed", "_killer", "_instigator", "_useEffects"];
		
		if (_killed isKindOf "Man") then {
			deleteVehicle _killed;
		};
	}
];



//*** Initialize the looping hint message functionality
sxf_fnc_getPlayerStatusText = {
	_color = "#666666";	//dead color by default
	if (alive _this) then {
		_color = ["#FFFFFF", "#F1BD1D"] select ( lifeState _this isEqualTo "INCAPACITATED" );
	};
	
	
	
	format [
		"<t align='left' size='0.9'>  +  <t color='%1'>%2</t> </t><br/>", 
		_color, 
		name _this
	]
};
sxf_fnc_loopMessage = {	
	_output = "";
	_livingPlayersMessage = "";
	_timerMessage = "";
	_enemyTeam = [opfor, blufor] select (side player isEqualTo blufor);
	

	
	_livingPlayersMessage = "<t align='left' size='1.3'>Players remaining:</t><br/>";
	
	_bluforList = []; _opforList = []; _independentList = []; _civilianList = [];
	{
		switch (side _x) do {
			case blufor: { _bluforList pushBack _x; };
			case opfor: { _opforList pushBack _x; };
			case independent: { _independentList pushBack _x; };
			case civilian: { _civilianList pushBack _x; };
		};
	} forEach ([allUnits, call BIS_fnc_listPlayers] select isMultiplayer);
	
	if (count _bluforList != 0) then {
		_livingPlayersMessage = _livingPlayersMessage + "<br/><br/>" + "> BLUFOR" + "<br/>";
		{ _livingPlayersMessage = _livingPlayersMessage + (_x call sxf_fnc_getPlayerStatusText); } forEach _bluforList;
	};
	if (count _opforList != 0) then {
		_livingPlayersMessage = _livingPlayersMessage + "<br/><br/>" + "> OPFOR" + "<br/>";
		{ _livingPlayersMessage = _livingPlayersMessage + (_x call sxf_fnc_getPlayerStatusText); } forEach _opforList;
	};
	if (count _independentList != 0) then {
		_livingPlayersMessage = _livingPlayersMessage + "<br/><br/>" + "> INDEPENDENT" + "<br/>";
		{ _livingPlayersMessage = _livingPlayersMessage + (_x call sxf_fnc_getPlayerStatusText); } forEach _independentList;
	};
		
	
	
	if (!isNil "sv_currentTime") then {
		_timerMessage = _timerMessage + "<t size='1.3'>Time remaining:</t><br/>";
		_timerMessage = _timerMessage + format["<t size='2' align='center' color='#F1BD1D'>%1m %2s</t>", floor (sv_currentTime/60), sv_currentTime%60];
	};

	
	
	_output = (
		"<br/><t align='left'>" +
		_timerMessage +
		"<br/><br/>" +
		_livingPlayersMessage +
		"<br/><br/></t>"
	);
	
	{	//show the mission info hint message only to the players who have their loop message turned ON
		if (_x getVariable ["sxf_bLoopEnabled", false]) then {
			(parseText _output) remoteExec ["hintSilent", _x];
		};
	} forEach (call BIS_fnc_listPlayers);
};

//*** Initialize the mission status hint message loop
waitUntil { time>0 };
[ "itemAdd", [ "loopMessage", { call sxf_fnc_loopMessage; }, 1, "seconds", {  {_x getVariable ["sxf_bLoopEnabled", false]} count (call BIS_fnc_listPlayers) > 0  } ] ] call BIS_fnc_loop;



//*** Initialize the countdown timer for all players
sv_currentTime = 5*60;
[ "itemAdd", [ 
	"countdownTimer", {		
		sv_currentTime = sv_currentTime - 1;
		if (sv_currentTime isEqualTo 0) then {
			sv_currentTime = nil;
			"EveryoneLost" call BIS_fnc_endMissionServer;
		};
	}, 
	1, "seconds", {
		!isNil "sv_currentTime" && {sv_currentTime >= 0}
	}
] ] call BIS_fnc_loop; 