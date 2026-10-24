## Concrete script component for Dungeon Degenerates.
##
## The framework's ScriptComponent is abstract, so this is the one every scripted entity gets.
## It is stored under the "ScriptComponent" slot (ScriptComponent is a slot root), which is the
## name ScriptSystem looks for. The entity's own EntityScript instance goes in main_script.
## Each adventurer gets its own instance of its own script class, because an EntityScript keeps
## per-entity state (entity id, variables, subscriptions).
class_name DDScriptComponent
extends ScriptComponent
