params ["_unit", "_didJIP"];

if (_didJIP) exitWith { 
	_unit setDamage 1;
	"The game says that you joined after the race actually started, so we had to change you into a spectator.  Sorry!" remoteExec ["hint", _unit];
	deleteVehicle _unit;
};