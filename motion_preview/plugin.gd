@tool
extends EditorPlugin


var preview_window: Window
var viewport_container: SubViewportContainer
var viewport: SubViewport

var preview_object: Node3D

func _enter_tree() -> void:
	_create_preview_window()
	
func _exit_tree() -> void:
	if preview_window:
		preview_window.queue_free()
		

func _create_preview_window() -> void:
	preview_window = Window.new()
	
	preview_window.title = "Motion Preview"
	preview_window.size = Vector2i(500, 400)
	
	add_child(preview_window)
	
	_create_viewport()
	
	preview_window.popup_centered()


func _create_viewport() -> void:
	viewport_container = SubViewportContainer.new()
	
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	preview_window.add_child(viewport_container)
	
	var button := Button.new()
	
	button.text = "▶ Preview Current Script"
	
	preview_window.add_child(button)
	
	button.pressed.connect(_preview_current_script)
	
	viewport = SubViewport.new()
	
	
	viewport.size = Vector2i(500, 400)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	viewport_container.add_child(viewport)
	
	
	var camera := Camera3D.new()
	
	#camera.position = Vector3(5, 5, 5)
	
	camera.look_at_from_position(Vector3(4, 4, 4), Vector3.ZERO)
	
	viewport.add_child(camera)
	
	preview_object = MeshInstance3D.new()
	var cube_mesh := BoxMesh.new()
	
	preview_object.mesh = cube_mesh
	
	viewport.add_child(preview_object)
	
	var light := DirectionalLight3D.new()
	
	light.rotation_degrees = Vector3(-45, -30, 0)
	
	viewport.add_child(light)
	

func _preview_current_script() -> void:
	print("Preview button pressed")
	
	_reset_cube()
	
	var script_editor := EditorInterface.get_script_editor()
	
	var current_script := script_editor.get_current_script()
	
	if current_script == null:
		print("No script is currently open")
		return
		
	print("Current script: " + current_script.resource_path)
	
	var source = current_script.get_source_code()
	
	print("Source: " + source)
	
	var preview_function := _extract_preview_function(source)
	
	if preview_function.is_empty():
		print("No _preview_process() found.")
		
		return
	
	print("Found preview function: " + preview_function)
	
	var generated_script := _generate_preview_script(preview_function)
	
	print("Generated script: " + generated_script)
	
	_write_preview_script(generated_script)
	
	_load_preview_script()

func _extract_preview_function(source: String) -> String:
	
	var lines := source.split("\n")
	
	var result: Array[String] = []
	
	var inside_function := false
	
	for line in lines:
		
		if line.begins_with("func _preview_process"):
			
			inside_function = true
			
			result.append(line)
			
			continue
			
			
		if inside_function:
			
			if line.begins_with("func "):
				break
				
			result.append(line)
			
	if result.is_empty():
		return ""
		
	return "\n".join(result)
	
func _generate_preview_script(function_source: String) -> String:

	var result := function_source


	result = result.replace(
		"func _preview_process",
		"func _process"
	)


	return "@tool\nextends Node3D\n\n" + result

func _write_preview_script(source: String) -> void:

	var path := "res://.motion_preview.gd"


	var file := FileAccess.open(
		path,
		FileAccess.WRITE
	)


	if file == null:

		print("ERROR: Could not create preview script.")

		return


	file.store_string(source)

	file.close()


	print("Preview script written to:")
	print(path)

func _load_preview_script() -> void:

	var path := "res://.motion_preview.gd"


	var script := load(path)


	if script == null:

		print("ERROR: Could not load preview script.")

		return


	print("Preview script loaded.")


	preview_object.set_script(script)

	preview_object.set_process(true)
	
	print("Preview script attached to cube.")

func _reset_cube() -> void:
	preview_object.set_script(null)
	
	preview_object.global_transform = Transform3D.IDENTITY
