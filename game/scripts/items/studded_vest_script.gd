## The Studded Vest's script.
##
## The Vest is not Heavy if its owner's STR is 8 or more. The STR value is the script variable
## "not_heavy_min_str", which comes from the record's script_vars. If the variable is missing the
## Vest is Heavy as printed.
class_name StuddedVestScript
extends DDItemScript

const MIN_STR_VAR: String = "not_heavy_min_str"


func heavy_for(owner_id: StringName, printed_heavy: bool, entity_manager: EntityManager) -> bool:
	if not printed_heavy:
		return false
	var minimum: Variant = get_var(MIN_STR_VAR)
	if minimum == null or entity_manager == null:
		return printed_heavy
	var attributes: AttributesComponent = entity_manager.get_component(
			String(owner_id), AttributesComponent
	) as AttributesComponent
	if attributes == null:
		return printed_heavy
	return attributes.full(AttributesComponent.STR) < int(minimum)
