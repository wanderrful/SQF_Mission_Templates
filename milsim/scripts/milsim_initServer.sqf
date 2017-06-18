enableEnvironment false;

sv_debug = (count call BIS_fnc_listPlayers <= 1); publicVariable "sv_debug";

[ "Initialize" ] call BIS_fnc_dynamicGroups; //serverside initialization of the vanilla U-menu feature for group management



sxf_fnc_checkMissionCompleted = { !alive hvt };
sxf_fnc_checkMissionFailed = { !sv_debug };

sxf_fnc_handleMissionCompleted = {
	"MissionSuccess" remoteExec ["BIS_fnc_showNotification"];
	"MissionSuccessObjectiveCompleted" remoteExec ["playSound"];
	"EveryoneWon" call BIS_fnc_endMissionServer;
	( parseText format["<br/><br/><t size='1.5' color='#E28014' align='center'>Mission Success</t><br/>Objective Completed<br/><br/><br/><br/>", nil] ) remoteExec ["hint"];
};
sxf_fnc_handleMissionFailed = {
	if (_this) then { //true->team wiped out
		"MissionFail" remoteExec ["BIS_fnc_showNotification"];
		"MissionFailureYourTeamWasWipedOut" remoteExec ["playSound"];
		( parseText format["<br/><br/><t size='1.5' color='#E28014' align='center'>Mission Failure</t><br/>Your team was wiped out.<br/><br/><br/><br/>", nil] ) remoteExec ["hint"];
	} else { //false->hostage killed
		"MissionFailHostageKilled" remoteExec ["BIS_fnc_showNotification"];
		"MissionFailureYourTeamWasWipedOut" remoteExec ["playSound"];
		( parseText format["<br/><br/><t size='1.5' color='#E28014' align='center'>Mission Failure</t><br/>A hostage was killed.<br/><br/><br/><br/>", nil] ) remoteExec ["hint"];
	};
	"EveryoneLost" call BIS_fnc_endMissionServer;
};

[ "itemAdd", [ 
	"checkMissionCompleted", {
		true call sxf_fnc_handleMissionCompleted;
		["itemRemove", ["checkMissionCompleted"]] call BIS_fnc_loop;
	}, 
	1, "seconds", 
	call sxf_fnc_checkMissionCompleted || { opfor countSide allUnits <= 0 }
] ] call BIS_fnc_loop; 
[ "itemAdd", [ 
	"checkMissionFailed", {
		true call sxf_fnc_handleMissionFailed; 
		["itemRemove", ["checkMissionFailed"]] call BIS_fnc_loop;
	}, 
	1, "seconds", 
	call sxf_fnc_checkMissionFailed && { blufor countSide allUnits <= 0 }
] ] call BIS_fnc_loop;



sxf_fnc_loopMessage = {	
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
};
[ "itemAdd", [ "loopMessage", { call sxf_fnc_loopMessage; }, 1, "seconds", {  {_x getVariable ["sxf_bLoopEnabled", false]} count (call BIS_fnc_listPlayers) > 0  } ] ] call BIS_fnc_loop;