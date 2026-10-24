## The Corpse Burner's script. No game logic yet.
##
## Handlers are added as methods named on_<event> (see ScriptEvent), which subscribe automatically.
## The Luck rule on the character sheet is the first thing planned for this script: when you win a
## fight, if you destroyed any Undead, make a MRL Test and gain 1 Luck if you pass.
class_name CorpseBurnerScript
extends EntityScript
