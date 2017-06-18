#include "initUtilities.sqf"



//initialize the attributes
cl_lapsToWin = [1, paramsArray select 0] select isMultiplayer;
cl_currentLap = 1;
cl_checkpoints = [];
cl_finishTime = -1;
cl_checkpointArrow = objNull;
cl_directionalArrow = objNull;
cl_checkpointSound = "FD_Start_F";



//** FUNCTION DEFINITIONS:
	//* misc functions
cl_fnc_debug = { 
	playSound "FD_Start_F"; 
	"** cl_fnc_debug called" call BIS_fnc_error;
};
cl_fnc_moveInDriver = {
	player moveInDriver (player getVariable ["sxf_assignedKart", objNull]);
	player allowDamage false;
	(vehicle player) allowDamage false;
};

	//* checkpoint functions
cl_fnc_resetCheckpointHandler = { 
	removeAllMissionEventHandlers "EachFrame"; 
};
cl_fnc_assignNextCheckpoint = {
	//move the checkpoint arrow to the new location
	if (cl_checkpointArrow isEqualTo objNull) then {
		cl_checkpointArrow = "Sign_Arrow_Large_Pink_F" createVehicleLocal [0,0,0];
	};
	cl_checkpointArrow setPosASL [
			getPosASL (cl_checkpoints select 0) select 0,
			getPosASL (cl_checkpoints select 0) select 1,
			(getPosASL (cl_checkpoints select 0) select 2) + 1.25
	];
	cl_checkpointArrow setVectorUp [0,0,1];
	
	if (cl_directionalArrow isEqualTo objNull) then {
		cl_directionalArrow = "Sign_Arrow_Direction_Pink_F" createVehicleLocal [0,0,0];
	};
	
	addMissionEventHandler ["EachFrame", cl_fnc_onEachFrame];
};
cl_fnc_createNewLap = {
	cl_checkpoints = "trgcp_" call sxf_fnc_getEntitiesByPrefix;
	//cl_checkpoints = sv_checkpoints;
	cl_checkpoints pushBack (cl_checkpoints select 0); //the first one is also the finish line
	if (!isNil "cl_currentLap") then { cl_currentLap = cl_currentLap + 1; };
	player setVariable ["sxf_lapNumber", cl_currentLap, true];
	call cl_fnc_assignNextCheckpoint; 
};

	//* event functions
cl_fnc_onEachFrame = {
	if ( player inArea (cl_checkpoints select 0) ) then {
		call cl_fnc_handleReachedCheckpoint;
	};
	cl_directionalArrow setPosASL [
		(getPosASL player select 0) + (1.5 * sin (getDirVisual player)),
		(getPosASL player select 1) + (1.5 * cos (getDirVisual player)),
		(getPosASL player select 2) + 0.2
	];
	cl_directionalArrow setDir (player getDir cl_checkpointArrow);
	
	if (player inArea trg_outOfBounds) then {
		call cl_fnc_handleOutOfBounds;
	};
};
cl_fnc_handleOutOfBounds = {
	"3DEN_notificationWarning" remoteExec ["playSound", player];
	_lastCheckpoint = sv_checkpoints select ( ( (sv_checkpoints find (cl_checkpoints select 0) ) - 1 ) max 0 );
	_position = getPosASL _lastCheckpoint;
	_position set [2, (_position select 2) + 3];
	(vehicle player) setPosASL _position;
	(vehicle player) setVelocity [0,0,0];
	(vehicle player) setVectorUp [0,0,1];
	//  for some reason, triggers don't seem to have a direction/rotation when you're actually playing!
	//(vehicle player) setDir (getDir _lastCheckpoint);
};
cl_fnc_handleReachedCheckpoint = {
	if (count cl_checkpoints > 1) then { "CheckpointReached" call BIS_fnc_showNotification; };
	//cutRsc ["IconImage","PLAIN"];
	cl_checkpoints deleteAt 0;
	call cl_fnc_resetCheckpointHandler;
	playSound cl_checkpointSound;
	
	if (count cl_checkpoints <= 0) then { 
		cl_currentLap = cl_currentLap + 1;
		if (cl_currentLap > cl_lapsToWin) then { 
			call cl_fnc_handlePlayerHasCompletedRace;			
			[] spawn {
				sleep 2;
				(vehicle player) setPos (position teleportHereAfterFinishing); //it's a game logic that was placed in the editor
			};
		} else {
			call cl_fnc_createNewLap;
		};
	} else { call cl_fnc_assignNextCheckpoint; };
};
cl_fnc_handlePlayerHasCompletedRace = {
	if (count cl_checkpoints > 0) exitWith {}; //this player has not actually completed the race yet so nevermind
	if (! (cl_checkpointArrow isEqualTo objNull) ) then { deleteVehicle cl_checkpointArrow; };
	if (! (cl_directionalArrow isEqualTo objNull) ) then { deleteVehicle cl_directionalArrow; };
	cl_finishTime =  diag_tickTime - (player getVariable ["sxf_raceStartTime", 9999]);
	//["RaceEnd"] call BIS_fnc_showNotification;
	
	//tell the server that we have completed the race
	[player, { 
		_this call sv_fnc_handlePlayerHasCompletedRace;
	}] remoteExec ["bis_fnc_call", 2];
};

	//* gui functions
cl_fnc_setRaceInfoPanelText = { //-- TODO: make the info panel contain useful information
	_text = _this;
	_ctrl = (uiNamespace getVariable "RaceInfoPanel") displayCtrl 28211;
	ctrlSetText [_ctrl, _text];
};



//*** Handle player inputs
sxf_fnc_handleKey_F1 = {
	if (isTouchingGround vehicle player) then {
		(vehicle player) setPosASL [
			(getPosASL vehicle player) select 0,
			(getPosASL vehicle player) select 1,
			((getPosASL vehicle player) select 2) + 3
		];
		(vehicle player) setVectorUp [0,0,1];
		(vehicle player) setVelocity [0,0,-5];
	};
};
waituntil {!(IsNull (findDisplay 46))};
(findDisplay 46) displayRemoveAllEventHandlers "KeyDown";
(findDisplay 46) displayAddEventHandler [
	"KeyDown", 
	{
		if ( (_this select 1) in ( (actionKeys 'User1') + [0x3b] ) ) then {call sxf_fnc_handleKey_F1;};
	}
];


	//* CLIENT ENTRY POINT
cl_fnc_main = {
	//all race participants should be civilian
	if (! (side player isEqualTo civilian) ) exitWith {};
	
	waitUntil {time>0};
	
	cl_checkpoints = "trgcp_" call sxf_fnc_getEntitiesByPrefix;

	//TODO - spawn the race info panel widget containing useful info
	//("Race_Info_Panel" call BIS_fnc_rscLayer) cutRsc ["RaceInfoPanel", "PLAIN"];

	//move player back into her kart when she gets out
	(player getVariable ["sxf_assignedKart", objNull]) addEventHandler ["GetOut", cl_fnc_moveInDriver];
	_kart = ( missionNamespace getVariable "kart_" +  ( ( (vehicleVarName player) splitString "_" ) select 1 ) );
	player setVariable ["sxf_assignedKart", _kart];
	call cl_fnc_moveInDriver;
	
	{ //attempt to make all players and cars pass through eachother
		_x disableCollisionWith player;
		_x disableCollisionWith vehicle player;
		vehicle _x  disableCollisionWith player;
		vehicle _x  disableCollisionWith vehicle player;
	} forEach (call BIS_fnc_listPlayers);
};