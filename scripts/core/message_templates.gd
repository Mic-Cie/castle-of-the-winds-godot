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
const COMMAND_ABORTED := "Command Aborted."


static func format_command_pending(command_name: String) -> String:
	return "Command Pending: %s..." % command_name
