params ["_unit", "_didJIP"];

//please execute this serverside
if (isNil "sxf_fnc_paradrop") then { 
	sxf_fnc_paradrop = { 
		_guy = _this;
		_paraPos = position _guy;
		if (! (vehicle _guy isEqualTo _guy) ) then { 
			_guy action ["GetOut", vehicle _guy]; 
		} else {
			_paraPos set [2, 155]; //combat jump altitude
			[_guy, _paraPos] remoteExec ["setPosATL", _guy];
			_guy setPosATL _paraPos;
		};
		//(parseText "You will be placed into a NON-steerable parachute for safety reasons in six seconds.<br/><br/>Enjoy the ride!") remoteExec ["hint", _guy];
		sleep 3;
		_paraPos = getPosASL _guy;
		_parachute =  createVehicle ["NonSteerable_Parachute_F", _paraPos, [], 0, "CAN_COLLIDE"];
		_parachute setDir (direction _guy);
		_parachute setPosASL _paraPos;
		[_guy, _parachute] remoteExec ["moveInDriver", _guy];
	};
};

if (!isNil "sxf_enableParadrop") then {
	if (!_didJIP) then {
		_unit call sxf_fnc_paradrop;
	} else {
		titleText ["(Sorry, but it isn't safe for JIPs to parachute!)", "PLAIN DOWN"];
	};
};

/***
 *		To use the the paradrop intro with this template, make a game logic and assign the variable "sxf_enableParadrop" to something.
 *		To use the helicopter paradrop feature with this template, don't do the above thing but instead call it from an editor trigger on a helicopter
 *
 */