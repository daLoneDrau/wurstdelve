## The Hinterlander's script. No game logic yet.
##
## Handlers are added as methods named on_<event> (see ScriptEvent), which subscribe
## automatically. The adventurer's Luck rule is the first thing planned for this script: gain
## 1 Luck when Stealth is used to avoid a fight while Outside.
class_name HinterlanderScript
extends EntityScript