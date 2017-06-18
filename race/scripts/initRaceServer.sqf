#include "initUtilities.sqf"



//initialize the attributes
sv_raceInProgress = false;
sv_raceStartTime = 0;
sv_results = [ [], [] ]; //0->player references, 1->player finish times
sv_checkpoints = [];
cl_currentLap = 0; publicVariable "cl_currentLap";



//** FUNCTION DEFINITIONS:
	//* event functions
sv_fnc_handleBeginStartCountdown = {
	{
		_x allowDamage false;
		if (!isPlayer driver _x ) then { deleteVehicle (driver _x); };
		if (driver _x isEqualTo objNull) then { deleteVehicle _x; };
	} forEach ("kart_" call sxf_fnc_getEntitiesByPrefix);
	for "_i" from 1 to 5 do {
		parseText format["<br/><br/><t align='left'>The race begins in:</t><br/><br/><t size='8'>%1</t><br/><br/><br/><br/>", str (6 - _i)] remoteExec ["hint"];
		sleep 1;
	};
	parseText "<br/><br/><br/><br/><t size='8'>GO!</t><br/><br/><br/><br/>" remoteExec ["hint"];
	
	//assign the start time for the race and propogate it to all players so they can check clientside
	sv_raceStartTime = diag_tickTime;
	
	call sv_fnc_handleRaceHasStarted;
};
sv_fnc_handleRaceHasStarted = {
	{
		if ( !(side player isEqualTo civilian) || {!hasInterface}) exitWith {};
		(vehicle player) setFuel 1;
		["RaceStart"] remoteExec ["BIS_fnc_showNotification"];
		call cl_fnc_createNewLap;
	} remoteExec ["bis_fnc_call"];
	sv_raceStartTime = diag_tickTime;
	[] spawn {
		["itemAdd", ["loopMessage", {
			(call sv_fnc_getResultsData) remoteExec ["hint"];
		}, 0.2]] call BIS_fnc_loop; 
	};
};
sv_fnc_handlePlayerHasCompletedRace = { 
	//called by a player when they have finished the race
	(sv_results select 0) pushBack _this;
	(sv_results select 1) pushBack (diag_tickTime - sv_raceStartTime);
	publicVariable "sv_results";
	
	[
		"RaceEnd",
		[name _this]
	] remoteExec ["BIS_fnc_showNotification"];
	
	if (count (sv_results select 0) isEqualTo (count call BIS_fnc_listPlayers)) then {
		sleep 3;
		[] spawn {
			sv_raceInProgress = false;
			"Won" call BIS_fnc_endMissionServer;
		};
	};
};

	//* text functions
sv_fnc_getResultsData = {
	_output = "";
	{
		if (side _x isEqualTo civilian) then {
			_currentTime =  diag_tickTime - (sv_raceStartTime);
			_referenceString = "p_" + str (round ((random 8) + 1));
			_textColor = [ (vehicleVarName _x) call sv_fnc_getHexColor, _referenceString call sv_fnc_getHexColor ] select ( _x in (sv_results select 0) );
			
			_playerFinishedIndex = -1; _playerFinishPlace = ""; _playerFinishTime = "";
			if (count (sv_results select 0) != 0) then {
				_playerFinishedIndex = (sv_results select 0) find _x;
				_playerFinishPlace = str (_playerFinishedIndex + 1);
				_playerFinishTime = ((sv_results select 1) select _playerFinishedIndex);
			};
			
			_output = _output + format [
				"<t align='left' color='%1'>%2 - %3</t><t align='right' color='%1'>%4    </t><br/>",
				_textColor,
				["-", _playerFinishPlace] select (_playerFinishedIndex != -1),
				name _x,
				[(str ((round (10*_currentTime))/10) + "s"), ("~*^" + str _playerFinishTime + "^*~")] select (_playerFinishedIndex != -1)
			];
		};
	} forEach call BIS_fnc_listPlayers;
	
	parseText format [
		(
			(
				format ["<t size='1.5' color='#E28014' align='center'>%1</t><br/>by sixtyfour", briefingName]
			) + (
				"<br/><br/>"
			) + (
				"<t align='left'>   Player:</t><t align='right'>Time   </t><br/>"
			) + (
				"--------------------------<br/>"
			) + (
				"%1"	//results table
			) + (
				"--------------------------<br/>"
			) + (
				"<br/><br/>"
			) + (
				"Press the F1 or UserAction1 key if stuck!"
			) + (
				"<br/><br/>"
			) + (
				format ["<t align='left'>Lap:</t><t align='right'>%1 of %2   </t>", player getVariable ["sxf_lapNumber",0], paramsArray select 0]
			)+ (
				"<br/><br/>"
			)
		),
		_output,
		_this,
		paramsArray select 0
	]
};

	//* color functions
sv_fnc_getHexColor = {
	_color = "#000000";	//black is the default, error color
	switch (_this) do
	{
		case "p_1": 	{_color = "#ff0000";}; 		//red
		case "p_2": 	{_color = "#004dff";}; 		//blue
		case "p_3": 	{_color = "#1affff";}; 		//teal
		case "p_4": 	{_color = "#b31ae6";}; 		//purple
		case "p_5": 	{_color = "#e6800d";}; 		//orange
		case "p_6": 	{_color = "#00ff00";}; 		//green
		case "p_7": 	{_color = "#ffffff";}; 		//white
		case "p_8": 	{_color = "#ffff00";}; 		//yellow
		case "p_9": 	{_color = "#4d66b3";}; 		//baby blue
		case "p_10":	{_color = "#ff51e3";}; 		//pink
		case "p_11":	{_color = "#985300";};		//brown
		case "p_12":	{_color = "#787878";};	 	//gray
	};
	_color
};
sv_fnc_getTextureColor = {
	_color = "#(argb,8,8,3)color(0,0,0,1,co)";	//black is the default, error color
	switch (vehicleVarName _this) do
	{
		case "p_1": 	{_color = "#(argb,8,8,3)color(1,0,0,0.1,co)";}; 				//red
		case "p_2": 	{_color = "#(argb,8,8,3)color(0.0,0.3,1,0.5,co)";}; 			//blue
		case "p_3": 	{_color = "#(argb,8,8,3)color(0.1,1,1,0.15,co)";}; 			//teal
		case "p_4": 	{_color = "#(argb,8,8,3)color(0.7,0.1,0.9,0.07,co)";}; 		//purple
		case "p_5": 	{_color = "#(argb,8,8,3)color(0.9,0.5,0.05,0.2,co)";}; 		//orange
		case "p_6": 	{_color = "#(argb,8,8,3)color(0,1,0,0.07,co)";}; 			//green
		case "p_7": 	{_color = "#(argb,8,8,3)color(1,1,1,0.3,co)";}; 				//white
		case "p_8": 	{_color = "#(argb,8,8,3)color(1,1,0,0.25,co)";}; 			//yellow
		case "p_9": 	{_color = "#(argb,8,8,3)color(0.3,0.4,0.7,0.9,co)";}; 		//baby blue
		case "p_10": {_color = "#(argb,8,8,3)color(1,0.318,0.89,1,co)";}; 			//pink
		case "p_11": {_color = "#(argb,8,8,3)color(0.4,0.224,0.098,1,co)";}; 		//brown    --- BUG: THIS COLOR LOOKS TOO ORANGE!
		case "p_12": {_color = "#(argb,8,8,3)color(0.471,0.471,0.471,1,co)";}; 		//gray
	};
	_color
};



//* SERVER ENTRY POINT
sv_fnc_main = {
	//find all of the checkpoint triggers for the mission
	sv_checkpoints = "trgcp_" call sxf_fnc_getEntitiesByPrefix; publicVariable "sv_checkpoints";
	
	waitUntil {time>0};
	
	{
		//assign uniform color
		_texture = _x call sv_fnc_getTextureColor;
		[_x, [0, _texture]] remoteExec ["setObjectTextureGlobal", _x];
		//make the relevant vehicle part(s) the same color as the player
		_temp = 0;
		switch (typeOf vehicle _x) do {
			case "C_Quadbike_01_F": { _temp = [1]; };
			case "C_Hatchback_01_sport_F": { _temp = [0]; };
			case "C_Plane_Civil_01_racing_F": { _temp = [0,1,2]; };
		};
		_thisPlayer = _x;
		{
			[vehicle _thisPlayer, [_x, _texture]] remoteExec ["setObjectTextureGlobal", _thisPlayer];
		} forEach _temp;
		
		//display the initial welcome message
		parseText (
			format["<br/><t size='1.5' color='#E28014' align='center'>%1</t><br/>", briefingName] + 
			"by sixtyfour<br/><br/>" +
			"<t align='left'>This is a proof of concept that I made because I wanted to play custom race maps but unfortunately the built-in bohemia thing was way too complex to figure out how to use. So I made my own system.<br/><br/>" + "
			To do:<br/>" + 
			"- make the server display a list of checkpoint times both to the player and to everyone on the server during the race<br/>" + 
			"- display a summary when all players have finished the race<br/>" +
			"- allow players to restart the race over again via a voting prompt dialog<br/>" + 
			"- make the bottom right control panel display useful information that live updates throughout the race.</t><br/>" +
			"<br/><br/><br/>" + 
			"<t size='1.3' color='#E28014'>The countdown to start will begin in 10 seconds!</t><br/>" + 
			"<br/><br/><br/>" 
		) remoteExec ["hint", _x];
	} forEach (call BIS_fnc_listPlayers);
	
	//give players time to load in, then get the party started
	sleep ([1, 10] select isMultiplayer);
	call sv_fnc_handleBeginStartCountdown;
};