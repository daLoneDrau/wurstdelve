class_name DDEntityManager
extends EntityManager


## Entity tags for DD-specific entities
# const TAG_PLAYER: int = 1 << 0


## Determines if an Entity is tagged as a PC
func is_pc(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.PC)


## Determines if an Entity is tagged as an item
func is_item(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.ITEM)


func is_unique(e: Entity) -> bool:
	return e.tags.has(EntityTags.Tag.UNIQUE)


## Kill all active combat effects/spells on an entity
func kill_spells_on(e_id: String) -> void:
	var entity := get_entity_by_id(e_id)
	if not entity:
		return

	var effects_comp: EffectsComponent = entity.get_component("EffectsComponent") as EffectsComponent
	if effects_comp:
		# Remove all combat-duration effects
		effects_comp.on_combat_end()

func unequip_from_inventory(_player_entity: Entity, _item_entity: Entity) -> bool:
	return false

func send_init_script_event(_entity: Entity) -> void:
	pass


## —————————————————————————————————————————————
#region Adventurer creation
## —————————————————————————————————————————————

## Creates a PC adventurer entity from an authored record and queues it for registration.
## The entity is registered on the next update(), or right away if immediate is true.
## Records are loaded and validated at startup by DDAssetsLibrary, for example:
##   create_adventurer(GameEngine_auto.dd_assets().get_adventurer_record("hinterlander"))
##
## Each adventurer gets its own instance of the script class named by the record's "script".
##
## Not built yet: Inventory, Equipment (record "starting_items"), Model and PartyMembership.
## The record's "suggested_*" fields are used only at Party Setup.
func create_adventurer(record: Dictionary, immediate: bool = false) -> Entity:
	var record_id: String = str(record.get("id", ""))
	if record_id.is_empty():
		push_error("DDEntityManager: adventurer record has no id.")
		return null

	# Load the script first, so a failure leaves nothing half-built.
	var script_class: GDScript = load(str(record.get("script", ""))) as GDScript
	if script_class == null:
		push_error("DDEntityManager: adventurer %s has no loadable script." % record_id)
		return null

	var e: Entity = Entity.new()
	# the id must be set before any component is added
	e.id = "adv_%s" % record_id
	e.tags.add(EntityTags.Tag.PC)

	# --- identity ---
	var name_comp: NameComponent = NameComponent.new(str(record.get("name", "")))
	name_comp.internal_id = StringName(record_id)
	e.set_component(name_comp)

	var description: DescriptionComponent = DescriptionComponent.new()
	description.lore = str(record.get("biography", ""))
	e.set_component(description)

	var adventurer: AdventurerComponent = AdventurerComponent.new()
	adventurer.crime = str(record.get("crime", ""))
	adventurer.homeland = str(record.get("homeland", ""))
	for class_key in record.get("classes", []):
		var class_tag: int = ClassTags.from_key(str(class_key))
		if class_tag == 0:
			push_error("DDEntityManager: unknown class '%s' on adventurer %s." % [class_key, record_id])
			continue
		adventurer.classes.add(class_tag)
	e.set_component(adventurer)

	# --- attributes and Luck (base values only; PlayerSystem computes effective values) ---
	var attrs_data: Dictionary = record.get("attributes", {})
	var attributes: AttributesComponent = AttributesComponent.new()
	for key in AttributesComponent.ATTRIBUTE_KEYS:
		if attrs_data.has(str(key)):
			var base: int = clampi(
					int(attrs_data[str(key)]),
					AttributesComponent.MIN_ATTRIBUTE,
					AttributesComponent.MAX_ATTRIBUTE
			)
			attributes.set_ability_score(key, base)
	# Luck can never exceed MAG
	var luck: int = clampi(
			int(record.get("luck", 0)),
			0,
			attributes.base_value(AttributesComponent.MAG)
	)
	attributes.set_ability_score(AttributesComponent.LUCK, luck)
	e.set_component(attributes)

	# --- health: max HP is twice CON; a new adventurer has 0 Wounds ---
	var max_hp: float = float(2 * attributes.base_value(AttributesComponent.CON))
	var health: HealthComponent = HealthComponent.new()
	health.max_hp = max_hp
	health.current_hp = max_hp
	e.set_component(health)

	# --- GP and XP (WalletComponent.gold and ProgressionComponent.experience only) ---
	var wallet: WalletComponent = WalletComponent.new()
	wallet.gold = clampi(int(record.get("gp", 0)), 0, DDAssetsLibrary.MAX_COUNTER)
	e.set_component(wallet)

	var progression: ProgressionComponent = ProgressionComponent.new(
			1, clampi(int(record.get("xp", 0)), 0, DDAssetsLibrary.MAX_COUNTER)
	)
	e.set_component(progression)

	# --- Skills and Weaknesses (ids only; definitions come later) ---
	var skills: SkillsComponent = SkillsComponent.new()
	for skill_id in record.get("skills", []):
		skills.add_skill(StringName(str(skill_id)))
	e.set_component(skills)

	var weaknesses: WeaknessesComponent = WeaknessesComponent.new()
	for weakness_id in record.get("weaknesses", []):
		weaknesses.add_weakness(StringName(str(weakness_id)))
	e.set_component(weaknesses)

	# --- scripting: this adventurer's own script, plus the variables it reads and writes ---
	var script_comp: DDScriptComponent = DDScriptComponent.new()
	script_comp.main_script = script_class.new() as EntityScript
	script_comp.role_hint = "adventurer"
	e.set_component(script_comp)
	e.set_component(ScriptVariableSet.new())

	# AdventurerComponent extends PlayerComponent and DDScriptComponent extends ScriptComponent.
	# Both parents are slot roots, so each must be found under its parent's name. If these fail,
	# the slot-root lookup is not behaving as assumed.
	assert(e.has_component("PlayerComponent"), "AdventurerComponent not in PlayerComponent slot")
	assert(e.has_component("ScriptComponent"), "DDScriptComponent not in ScriptComponent slot")

	add_entity(e)
	if immediate:
		add_entity_immediately(e.id)
	return e

#endregion
