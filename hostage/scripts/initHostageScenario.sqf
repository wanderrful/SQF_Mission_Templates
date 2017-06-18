//Made by sixtyfour, 19 July 2016
//-------------------------------
/* 
known bugs:
-you're still able to steal the hostage from another player, which shouldn't be possible (or at least handled in the script)
-i should implement interaction with vehicles...
*/



#include "initUtilities.sqf"

//#SERVERSIDE
sv_hostageGroup = createGroup civilian;
sv_hostageList = []; publicVariable "sv_hostageList";
sv_extractionStatus = [];
sv_extractedHostages = [];
sv_extractionZones = [];



//find all hostages in the mission and configure them
sv_hostageList = ("hostage_" call sxf_fnc_getEntitiesByPrefix); publicVariable "sv_hostageList";
{
	sv_extractionStatus pushBack false;	
	[_x] joinSilent sv_hostageGroup;
	_x setVariable ["bCarried", false, true];
	//_x switchMove "Acts_AidlPsitMstpSsurWnonDnon01";	//initial animation: sitting down and tied up
	_x disableAI "AUTOCOMBAT";
	_x disableAI "FSM";
	_x disableAI "CHECKVISIBLE";
	_x disableAI "TARGET";
	_x disableAI "PATH";
	_x disableAI "MOVE";
	
	_x setVariable ["NOAI",1,false]; //disables VCOM AI initialization
	_x setCaptive true;
	_x setUnconscious true;


	_trg = createTrigger ["EmptyDetector", [0,0,0], false];
	_trg setTriggerActivation ["NONE", "PRESENT", false];
	_trg setTriggerStatements 
	[
		"!alive " + (vehicleVarName _x), 
		"'HostageKilled' call sxf_fnc_handleMissionFailed;",
		""
	];
} forEach sv_hostageList;



//find all extraction zones in the mission and configure them
sv_extractionZones = ("trg_extractionZone_" call sxf_fnc_getEntitiesByPrefix); publicVariable "sv_hostageList";
{
	_x setTriggerActivation ["ANY", "PRESENT", true];
	_x setTriggerStatements
	[
		"this && {!(_x in sv_extractedHostages) && (_x in sv_hostageList)} count thisList > 0",
		"{_x call sxf_fnc_setHostageExtracted;} forEach thisList; ['TaskSucceeded', ['', 'A hostage has been extracted!']] call BIS_fnc_showNotification;",
		""
	];
} forEach sv_extractionZones;

_trg = createTrigger ["EmptyDetector", [0,0,0], false];	//victory trigger
_trg setTriggerActivation ["ANY", "PRESENT", false];
_trg setTriggerStatements 
[
	"{_x} count sv_extractionStatus == count sv_hostageList",
	"true call sxf_fnc_handleMissionCompleted;",
	""
];



//#CLIENTSIDE (initialization for each player)
{
	if (hasInterface) then 
	{
		{
			player setVariable 
			[
				("carryAction_" + vehicleVarName _x), 
				_x addAction
				[
					"Carry the hostage",
					{
						params ["_theHostage", "_thePlayer", "_actionID", "_args"];
						
						_bCarried = _theHostage getVariable "bCarried";
						if (_bCarried) then 
						{	//drop the hostage		
							_thePlayer disableCollisionWith _theHostage;
							_thePlayer switchMove "";
							_theHostage playMove "Acts_PercMstpSlowWrflDnon_handup2";
							sleep 0.1;
							_theHostage switchMove "Acts_AidlPsitMstpSsurWnonDnon01";
							detach _theHostage;
							_thePlayer enableCollisionWith _theHostage;
						
							_theHostage setUserActionText [_actionID, "Carry the hostage"];
							_theHostage setVariable ["bCarried", !_bCarried, true];
						}
						else 
						{	//make sure the player can only carry one hostage at a time
							if (count attachedObjects _thePlayer <= 0) then
							{	//carry the hostage
								_position = [0,-.1,-1.2];
								_direction = (getDir _thePlayer) + 180;

								_thePlayer switchMove "AcinPercMstpSnonWnonDnon";
								_theHostage playMove "AinjPfalMstpSnonWnonDf_carried_dead";
								sleep 0.1;
								_theHostage switchMove "AinjPfalMstpSnonWnonDf_carried_dead";
								_theHostage attachTo [_thePlayer, _position, "LeftShoulder"];
							
								_theHostage setUserActionText [_actionID, "Drop the hostage"];
								_theHostage setVariable ["bCarried", !_bCarried, true];
							};
						};
					},
					[],
					6,
					true,
					true,
					"",
					"(count attachedObjects _this <= 0)  || { (count attachedObjects _this) > 0 && {_target in (attachedObjects _this)} }",
					2.75,
					false
				]
			];
		} forEach sv_hostageList;
	};
} remoteExecCall ["bis_fnc_call"];



sxf_fnc_setHostageExtracted = 
{	//this function requires a single hostage unit reference (ex: hostage1 call sxf_fnc_setHostageExtracted)
	_temp = sv_hostageList find _this;
	if (_temp != -1) then
	{
		if ( !(sv_extractionStatus select _temp) ) then
		{
			sv_extractionStatus set [_temp, true];
			sv_extractedHostages pushBack _this;
		};
	} 
	else
	{
		diag_log "ERROR: sxf_fnc_setHostageExtracted INVALID ARGUMENT (initHostageScenario.sqf)";
	};
};



//end of file
diag_log "initHostageScenario.sqf loaded successfully!";