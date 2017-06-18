enableEnvironment false;

sv_debug = (count call BIS_fnc_listPlayers <= 1); publicVariable "sv_debug";
execVM "scripts\initHostageScenario.sqf";

[ "Initialize" ] call BIS_fnc_dynamicGroups; //serverside initialization of the vanilla U-menu feature for group management



sxf_fnc_handleMissionCompleted = {
	"MissionSuccess" remoteExec ["BIS_fnc_showNotification"];
	"MissionSuccessObjectiveCompleted" remoteExec ["playSound"];
	"EveryoneWon" call BIS_fnc_endMissionServer;
	( parseText format["<br/><br/><t size='1.5' color='#E28014' align='center'>Mission Success</t><br/>Objective Completed<br/><br/><br/><br/>", nil] ) remoteExec ["hint"];
};
sxf_fnc_handleMissionFailed = {
	switch (_this) do {
		case "TeamWipedOut": {
			"MissionFail" remoteExec ["BIS_fnc_showNotification"];
			"MissionFailureYourTeamWasWipedOut" remoteExec ["playSound"];
			( parseText format["<br/><br/><t size='1.5' color='#E28014' align='center'>Mission Failure</t><br/>Your team was wiped out.<br/><br/><br/><br/>", nil] ) remoteExec ["hint"];
		};
		case "HostageKilled": {
			"MissionFailHostageKilled" remoteExec ["BIS_fnc_showNotification"];
			"MissionFailureAHostageWasKilled" remoteExec ["playSound"];
			( parseText format["<br/><br/><t size='1.5' color='#E28014' align='center'>Mission Failure</t><br/>A hostage was killed.<br/><br/><br/><br/>", nil] ) remoteExec ["hint"];
		};
	};
	
	"EveryoneLost" call BIS_fnc_endMissionServer;
};



//fundamental win and fail conditions
[ "itemAdd", [ 
	"checkEnemiesWipedOut", {
		true call sxf_fnc_handleMissionCompleted;
		["itemRemove", ["checkEnemiesWipedOut"]] call BIS_fnc_loop;
	}, 
	1, "seconds", 
	{ opfor countSide allUnits <= 0 }
] ] call BIS_fnc_loop; 
[ "itemAdd", [ 
	"checkTeamWipedOut", {
		"TeamWipedOut" call sxf_fnc_handleMissionFailed; 
		["itemRemove", ["checkTeamWipedOut"]] call BIS_fnc_loop;
	}, 
	1, "seconds", 
	{ !sv_debug && {blufor countSide allUnits <= 0} }
] ] call BIS_fnc_loop;



[ "itemAdd", 
	[ "loopMessage", 
		{	
			_output = "";
			
			_enemyCountMessage = format [ "<br/><t size='1.5'><t align='left'>Enemies remaining:</t> <t color='#E28014' align='right'>%1</t></t><br/>", opfor countSide allUnits ];
			
			_livingPlayersMessage = "<t align='left' size='1.3'>Players remaining:</t><br/>";
			{
				if (isPlayer _x && {! ( str side _x isEqualTo "LOGIC" ) }) then {
					_color = "#666666";	//dead color by default
					if (alive _x) then {
						_color = ["#FFFFFF", "#F1BD1D"] select ( lifeState _x isEqualTo "INCAPACITATED" );
					};
					_livingPlayersMessage = _livingPlayersMessage + format [
						"<t align='left'>  +  <t color='%1'>%2</t><br/>", 
						_color, 
						name _x
					];
				};
			} forEach ( [allUnits, call BIS_fnc_listPlayers] select isMultiplayer );
			
			_output = (
				_enemyCountMessage + 
				"<br/><br/>" +
				_livingPlayersMessage +
				"<br/><br/>"
			);
			
			{	//show the mission info hint message only to the players who have their loop message turned ON
				if (_x getVariable ["sxf_bLoopEnabled", false]) then {
					(parseText _output) remoteExec ["hintSilent", _x];
				};
			} forEach (call BIS_fnc_listPlayers);
		},
		1, "seconds",
		{  
			{_x getVariable ["sxf_bLoopEnabled", false]} count (call BIS_fnc_listPlayers) > 0  
		}		
	] 
] call BIS_fnc_loop;