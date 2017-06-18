/***		(str prefix) call sxf_fnc_getEntitiesByPrefix;
 *		returns the list of all variables in the mission with the given name prefix
 */
sxf_fnc_getEntitiesByPrefix = {
	_tempList = [];
	_item = objNull;
	while {
		_i = (count _tempList) + 1;
		_item = missionNamespace getVariable [(_this + str _i), objNull];
		!( (_item isEqualTo objNull) || {isNil (_this + str _i)} )
	} do {
		_tempList pushBack _item;
	};
	_tempList
};
