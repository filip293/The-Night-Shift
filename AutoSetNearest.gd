@tool
extends EditorScript

func _run() -> void:
	var root = get_scene()
	if not root:
		printerr("Error: No active scene open. Open a scene in the editor first.")
		return
		
	var updated_count = _process_node(root)
	print("Scene scan complete. Materials updated to Nearest: ", updated_count)

func _process_node(node: Node) -> int:
	var count = 0
	
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			
			# 1. Check Surface Material Overrides
			var override_mat = node.get_surface_override_material(i)
			if override_mat and override_mat is BaseMaterial3D:
				if override_mat.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST:
					override_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					count += 1
			
			# 2. Check Base Mesh Materials
			var mesh_mat = node.mesh.surface_get_material(i)
			if mesh_mat and mesh_mat is BaseMaterial3D:
				if mesh_mat.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST:
					mesh_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					count += 1

	# Traverse children recursively
	for child in node.get_children():
		count += _process_node(child)
		
	return count
