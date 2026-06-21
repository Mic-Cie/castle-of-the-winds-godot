class_name MessageTemplates
extends RefCounted

const SECRET_DOOR_FOUND := "You find a secret door!"
const FLOOR_EMPTY := "Floor is Empty!"

const EXAMINE_UNSEEN_LOCATION := "You haven't seen that location!"
const EXAMINE_HEADER_SEE := "You see:"
const EXAMINE_HEADER_DETECT := "You detect:"
const EXAMINE_HEADER_MAP := "Your map shows:"
const EXAMINE_DUNGEON_FLOOR := "The dungeon floor"
const EXAMINE_ROCK := "Rock"
const EXAMINE_OPEN_DOOR := "An open door"
const EXAMINE_CLOSED_DOOR := "A closed door"
const EXAMINE_BROKEN_DOOR := "A broken door"

const COMMAND_LOOK := "Look"
const COMMAND_OPEN := "Open"
const COMMAND_CLOSE := "Close"
const COMMAND_ABORTED := "Command Aborted."

const CANT_REACH := "You can't reach it!"
const IN_THE_WAY := "You're in the way!"
const DONE := "Done"
const NOTHING_TO_OPEN := "Nothing there to open!"
const NOTHING_TO_CLOSE := "Nothing there to close!"

const MONSTER_HEALTH_UNINJURED := "Uninjured"
const MONSTER_HEALTH_BARELY_SCRATCHED := "Barely scratched"
const MONSTER_HEALTH_SLIGHTLY_INJURED := "Slightly injured"
const MONSTER_HEALTH_INJURED := "Injured"
const MONSTER_HEALTH_HEAVILY_INJURED := "Heavily injured"
const MONSTER_HEALTH_CRITICALLY_INJURED := "Critically injured"


static func format_monster_hits_you(monster_name: String) -> String:
	return "The %s hits you!" % monster_name


static func format_you_hit_monster(monster_name: String) -> String:
	return "You hit the %s!" % monster_name


static func format_you_miss_monster(monster_name: String) -> String:
	return "You miss the %s!" % monster_name


static func format_monster_misses_you(monster_name: String) -> String:
	return "The %s misses you!" % monster_name


static func format_command_pending(command_name: String) -> String:
	return "Command Pending: %s..." % command_name
