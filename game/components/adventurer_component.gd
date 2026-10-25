## Adventurer-specific data, extending PlayerComponent.
##
## PlayerComponent is a slot root, so this component is still stored and found under the name
## "PlayerComponent" (entity.get_component("PlayerComponent")). Death state is
## PlayerComponent.is_alive, which is the single source of truth for adventurers. Entity.alive
## must stay true until the entity is deliberately removed, because EntityManager.update()
## destroys any entity whose alive flag is false.
##
## Defeated is not stored: it is HealthComponent.current_hp == 0 while is_alive is true.
## Wounds are not stored either: they are max_hp - current_hp on HealthComponent.
##
## Data only. Rules (gaining, cancelling and lengthening conditions, clearing turn state)
## belong in systems.
class_name AdventurerComponent
extends PlayerComponent

enum FightStatus {
	NOT_IN_FIGHT,
	FIGHTING,
	ESCAPED,
}

enum CombatStance {
	NONE,  # not in a fight, or no stance chosen yet this turn
	ASSAULT,
	GUARD,
}

## An adventurer carries at most this many Heavy Items. Only a Skill or a magic Item can raise
## it, so the effective limit is computed by a system and never stored.
const BASE_HEAVY_LIMIT: int = 2

@export_group("Identity")

## Flavor only. Authored.
@export var crime: String = ""

## Flavor only. Plain text for now. Authored.
@export var homeland: String = ""

## Class tags (ClassTags.Tag bits). Static. Items, Skills and encounters check these.
@export var classes: FlagSet = FlagSet.new()

@export_group("Conditions")

## Status conditions (ConditionTags.Tag bits), one FlagSet per zone on the sheet.
## A condition appears at most once across the three.
@export var conditions_fight_round: FlagSet = FlagSet.new()
@export var conditions_end_of_fight: FlagSet = FlagSet.new()
@export var conditions_recovery: FlagSet = FlagSet.new()

@export_group("Turn State")

@export var fight_status: FightStatus = FightStatus.NOT_IN_FIGHT

## Chosen each turn in a fight.
@export var combat_stance: CombatStance = CombatStance.NONE

## Ids of monster entities this adventurer destroyed. Cleared after looting.
@export var trophies: Array[String] = []

## Ids of Skills and Items whose action was used this turn. Cleared by the turn system.
@export var actions_used_this_turn: Array[StringName] = []


## Returns the FlagSet for one of the sheet's three condition zones.
func conditions_for(duration: ConditionTags.Duration) -> FlagSet:
	match duration:
		ConditionTags.Duration.FIGHT_ROUND:
			return conditions_fight_round
		ConditionTags.Duration.END_OF_FIGHT:
			return conditions_end_of_fight
		_:
			return conditions_recovery


## Determines if a condition is active in any zone.
func has_condition(tag: int) -> bool:
	return conditions_fight_round.has(tag) \
			or conditions_end_of_fight.has(tag) \
			or conditions_recovery.has(tag)
