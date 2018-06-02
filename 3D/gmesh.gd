tool
extends Resource

func get_barycentric(v, a, b, c):
	var mat1 = Matrix3(a, b, c)
	var det = mat1.determinant()
	var mat2 = Matrix3(v, b, c)
	var factor_alpha = mat2.determinant()
	var mat3 = Matrix3(v, c, a)
	var factor_beta = mat3.determinant()
	var alpha = factor_alpha / det
	var beta = factor_beta / det
	var gamma = 1.0 - alpha - beta
	return Vector3(alpha, beta, gamma)

class Vertex:
	# A Vertex in a mesh
	var index = -1
	var position = Vector3()
	var normal = Vector3()
	var pointiness = 0.0
	var crease = 0.0

	var edges = [] # edges connected to this vertex
	var loops = [] # loops that use this vertex
	var faces = [] # faces connected to this vertex

	var mesh = null

	var bones = PoolIntArray()
	var weights = PoolRealArray()

	var selected = false

	func _init(position = Vector3(), index = -1):
		self.index = index
		self.position = position
		return self

	func make_dirty():
		if(is_valid()):
			for loop in loops:
				loop.dirty = true

	func copy_from(other):
		position = other.position
		normal = other.normal

		edges = other.edges.duplicate()
		loops = other.loops.duplicate()
		faces = other.faces.duplicate()
		return self

	func calc_normal():
		normal = Vector3()
		if(faces.size() > 0):
			for face in faces:
				normal += face.normal
			normal = normal.normalized()
		return self

	func remove():
		index = -1
		for edge in edges:
			edge.remove()
		for loop in loops:
			loop.remove()
		for face in faces:
			face.remove()
		return self

	func is_valid():
		return mesh != null

	func set_smooth(smooth):
		for loop in loops:
			loop.set_smooth(smooth)

	func calc_pointiness():
		var p = 0.0
		var fPI = 1.0/PI
		if(loops.size() > 0):
			var n = Vector3()
			for loop in loops:
				n += (loop.next.vert.position - loop.vert.position).normalized()
			p = (acos(clamp(normal.dot(n/(loops.size())),-1.0,1.0)) * fPI)
		self.pointiness = p
		return p

	func calc_crease():
		var c = 0.0
		var fPI = 1.0/PI
		if(edges.size() > 0):
			for edge in edges:
				c += acos(edge.get_face_angle()) * fPI
			c /= edges.size()
		self.crease = c
		return c

class Edge:
	# An edge connecting to verticies
	var index = -1
	var smooth = false

	var verts = [] # the verticies this edge uses (always 2)
	var loops = [] # the loops this edge connects
	var faces = [] # faces connected to this edge (0-2)

	var mesh = null

	var selected = false

	func _init(verts, index = -1):
		self.index = index
		self.verts = verts.duplicate()
		return self


	func make_dirty():
		if(is_valid()):
			for loop in loops:
				loop.dirty = true

	func copy_from(other):
		smooth = other.smooth

		verts = other.verts.duplicate()
		loops = other.loops.duplicate()
		faces = other.faces.duplicate()
		return self

	func get_face_angle():
		if(faces.size() == 2):
			return clamp(faces[0].normal.normalized().dot(faces[1].normal.normalized()),-1.0,1.0)
		return 1.0

	func get_length():
		return verts[0].distance_to(verts[1])
	func get_length_squared():
		return verts[0].distance_squared_to(verts[1])

	func remove():
		index = -1
		verts[0].edges.erase(self)
		verts[1].edges.erase(self)
		for loop in loops:
			loop.edge = null
		for face in faces:
			face.edges.erase(self)
		verts.clear()
		loops.clear()
		faces.celar()

		mesh.edges.erase(self)
		mesh = null

		return self

	func is_valid():
		return mesh != null && verts.size() == 2

	func set_smooth(smooth):
		for loop in loops:
			loop.set_smooth(smooth)

	func get_normal():
		return (verts[1].position - verts[0].position).normalized()



class Loop:
	# per face vertex data, and a corner of a face
	var dirty = true setget set_dirty,get_dirty
	var index = -1
	var edge = null
	var vert = null
	var face = null
	var mesh = null

	var next = null
	var prev = null

	var color = Color()
	var tangent = Vector3()
	var uv = Vector2()
	var uv2 = Vector2()
	var normal = Vector3() # this is the loop's normal

	var smooth = false

	func _init(vert, index = -1):
		self.index = index
		self.vert = vert
		return self


	func set_dirty(d):
		if(is_valid()):
			if(dirty == false && d == true):
				pass #mesh.update_mesh_data(self)

			dirty = d
		else:
			dirty = true

	func get_dirty():
		return dirty


	func copy_from(other):
		self.edge = other.edge
		self.vert = other.vert
		self.face = other.face
		self.next = other.next
		self.prev = other.prev

		self.color = other.color
		self.tangent = other.tangent
		self.uv = other.uv
		self.uv2 = other.uv2
		self.normal = other.normal
		self.smooth = other.smooth

		return self

	func remove():
		index = -1
		vert.loops.erase(self)
		vert = null
		edge.loops.erase(self)
		edge = null
		face.loops.erase(self)
		face = null
		next.prev = null
		next = null
		prev.next = null
		prev = null

		mesh.loops.erase(self)
		mesh = null
		return self

	func is_valid():
		return mesh != null && vert != null && edge != null && face != null && next != null && prev != null

	func flip():
		var n = next
		next = prev
		prev = n
		return self

	func set_smooth(smooth):
		self.smooth = smooth
		calc_normal()
		return self

	func calc_normal():
		normal = Vector3()
		if(is_valid()):
			if(smooth):
				normal = vert.normal
			else:
				normal = face.normal
		return normal

class Face:
	# face with 3 loops
	var index = -1
	var normal = Vector3()
	var area = 0.0

	var verts = [] # verts of this face
	var edges = [] # edges of this face
	var loops = [] # loops of this face

	var mesh = null

	var selected = false

	func _init(loops, index = -1):
		self.index = index
		self.loops = loops
		return self

	func make_dirty():
		if(is_valid()):
			for loop in loops:
				loop.dirty = true


	func copy_from(other):
		self.normal = other.normal

		self.verts = other.verts.duplicate()
		self.edges = other.edges.duplicate()
		self.loops = other.loops.duplicate()
		return self

	func remove():
		loops[0].remove()
		loops[1].remove()
		loops[2].remove()

		verts.clear()
		edges.clear()
		loops.clear()

		mesh.faces.erase(self)
		mesh = null
		return self

	func calc_normal():
		normal = Vector3()
		if(is_valid()):
			normal = (-(verts[1].position - verts[0].position).cross(verts[2].position - verts[0].position)).normalized()
		return normal

	func flip():
		if(is_valid()):
			loops[0].flip()
			loops[1].flip()
			loops[2].flip()

			loops.invert()
			verts.invert()
		return self

	func is_valid():
		return mesh != null && loops.size() == 3  && verts.size() == 3 && edges.size() == 3

	func set_smooth(smooth):
		if(is_valid()):
			loops[0].set_smooth(smooth)
			loops[1].set_smooth(smooth)
			loops[2].set_smooth(smooth)
		return self

	func get_center():
		return (verts[0].position + verts[1].position + verts[2].position) / 3.0;

	func vector_to_uv(v):
		var bc = get_barycentric(v,loops[0].vert.position, loops[1].vert.position, loops[2].vert.position)
		return (loops[0].uv * bc.x) + (loops[1].uv * bc.y) + (loops[2].uv * bc.z);

	func uv_to_vector(uv):
		var bc = get_barycentric(Vector3(uv.x,uv.y,0),Vector3(loops[0].uv.x,loops[0].ux.y,0), Vector3(loops[1].uv.x,loops[1].ux.y,0), Vector3(loops[2].uv.x,loops[2].ux.y,0))
		return (loops[0].vert.position * bc.x) + (loops[1].vert.position * bc.y) + (loops[2].vert.position * bc.z);

	func backfacing(normal):
		return self.normal.dot(normal) < 0.0

	func calc_area():
		var ab = loops[1].vert.position - loops[0].vert.position
		var ac = loops[2].vert.position - loops[0].vert.position
		self.area = ab.cross(ac).length() * 0.5
		return self.area


"""
---------------------------------------------------------------------------------------
START OF GMESH
---------------------------------------------------------------------------------------
"""


"""TODO
- Add "auto_weld" function (weld_distance), and use that on from_mesh
- use edge_hash and face_hash for tracking if something exists
- remove vertex hash because that'll be handled by auto weld
"""

var verts = [] # all the verts in this mesh
var edges = [] # all the edges in this mesh
var loops = [] # all the loops in this mesh
var faces = [] # all the faces in this mesh

var _data = MeshDataTool.new()
var _surface_tool = SurfaceTool.new()

var _edge_hash = {}
var _face_hash = {}

func _init():
	pass

func make_dirty():
	for loop in loops:
		loop.dirty = true

func clear():
	_edge_hash = {}
	_face_hash = {}

	verts = []
	edges = []
	loops = []
	faces = []

	_data.clear()

func set_smooth(smooth):
	for loop in loops:
		loop.set_smooth(smooth)

func add_vertex(v):
	assert(typeof(v) == TYPE_VECTOR3)
	var vert = Vertex.new(v,verts.size())
	vert.mesh = self
	verts.append(vert)
	return vert

func add_edge(v1,v2):
	assert(v1 is Vertex)
	assert(v2 is Vertex)

	var key = [v1,v2]
	key.sort_custom(self,"_sort_by_index")

	if(_edge_hash.has(key) == false):
		var edge = Edge.new([v1,v2],edges.size())
		edge.mesh = self
		edges.append(edge)
		v1.edges.append(edge)
		v2.edges.append(edge)
		_edge_hash[key] = edge

	return _edge_hash[key]

func has_edge(v1,v2):
	assert(v1 is Vertex)
	assert(v2 is Vertex)

	var key = [v1,v2]
	key.sort_custom(self,"_sort_by_index")

	return _edge_hash.has(key)

func add_loop(v):
	assert(v is Vertex)
	var l = Loop.new(v,loops.size())
	v.loops.append(l)
	l.mesh = self
	loops.append(l)

	return l

func add_face(v1,v2,v3):
	assert(v1 is Vertex)
	assert(v2 is Vertex)
	assert(v3 is Vertex)

	var key = [v1,v2,v3]
	key.sort_custom(self,"_sort_by_index")

	if(_face_hash.has(key) == false):

		#this will check the edge hash
		var e1 = add_edge(v1,v2)
		var e2 = add_edge(v2,v3)
		var e3 = add_edge(v3,v1)

		#loops are always unique to the face
		var l1 = add_loop(v1)
		var l2 = add_loop(v2)
		var l3 = add_loop(v3)

		var f = Face.new([l1,l2,l3],faces.size())

		l1.next = l2
		l2.next = l3
		l3.next = l1
		l3.prev = l2
		l2.prev = l1
		l1.prev = l3

		l1.edge = e1
		l2.edge = e2
		l3.edge = e3
		e1.loops.append(l1)
		e2.loops.append(l2)
		e3.loops.append(l3)

		v1.faces.append(f)
		v2.faces.append(f)
		v3.faces.append(f)

		e1.faces.append(f)
		e2.faces.append(f)
		e3.faces.append(f)

		l1.face = f
		l2.face = f
		l3.face = f

		f.verts.append(v1)
		f.verts.append(v2)
		f.verts.append(v3)

		f.edges.append(e1)
		f.edges.append(e2)
		f.edges.append(e3)

		f.mesh = self
		faces.append(f)
		_face_hash[key] = f

	return _face_hash[key]


func from_mesh(mesh,surface = 0,auto_merge=true):

	if(mesh is PrimitiveMesh):
		var arr = mesh.get_mesh_arrays()
		var mat = mesh.material
		mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
		surface = mesh.get_surface_count()-1

	clear()
	_data.create_from_surface(mesh,surface)

	var _vert_hash = {}

	for i in range(_data.get_face_count()):

		var v1i = _data.get_face_vertex(i,0)
		var v2i = _data.get_face_vertex(i,1)
		var v3i = _data.get_face_vertex(i,2)

		var v1p = _data.get_vertex(v1i)
		var v2p = _data.get_vertex(v2i)
		var v3p = _data.get_vertex(v3i)

		var v1
		var v2
		var v3
		if(auto_merge):
			if(_vert_hash.has(v1p)):
				v1 = _vert_hash[v1p]
			else:
				v1 = add_vertex(v1p)
				_vert_hash[v1p] = v1

			if(_vert_hash.has(v2p)):
				v2 = _vert_hash[v2p]
			else:
				v2 = add_vertex(v2p)
				_vert_hash[v2p] = v2

			if(_vert_hash.has(v3p)):
				v3 = _vert_hash[v3p]
			else:
				v3 = add_vertex(v3p)
				_vert_hash[v3p] = v3
		else:
			v1 = add_vertex(v1p)
			v2 = add_vertex(v2p)
			v3 = add_vertex(v3p)

		if(v1.index == v2.index || v1.index == v3.index || v2.index == v3.index):
			continue


		var face = add_face(v1,v2,v3)

		face.normal = _data.get_face_normal(i)
		var l1 = face.loops[0]
		var l2 = face.loops[1]
		var l3 = face.loops[2]

		v1.bones = _data.get_vertex_bones(v1i)
		v2.bones = _data.get_vertex_bones(v2i)
		v3.bones = _data.get_vertex_bones(v3i)

		v1.weights = _data.get_vertex_weights(v1i)
		v2.weights = _data.get_vertex_weights(v2i)
		v3.weights = _data.get_vertex_weights(v3i)

		l1.color = _data.get_vertex_color(v1i)
		l2.color = _data.get_vertex_color(v2i)
		l3.color = _data.get_vertex_color(v3i)

		l1.normal = _data.get_vertex_normal(v1i)
		l2.normal = _data.get_vertex_normal(v2i)
		l3.normal = _data.get_vertex_normal(v3i)

		l1.tangent = _data.get_vertex_tangent(v1i)
		l2.tangent = _data.get_vertex_tangent(v2i)
		l3.tangent = _data.get_vertex_tangent(v3i)

		l1.uv = _data.get_vertex_uv(v1i)
		l2.uv = _data.get_vertex_uv(v2i)
		l3.uv = _data.get_vertex_uv(v3i)

		l1.uv2 = _data.get_vertex_uv2(v1i)
		l2.uv2 = _data.get_vertex_uv2(v2i)
		l3.uv2 = _data.get_vertex_uv2(v3i)

		l1.smooth = l1.normal != face.normal
		l2.smooth = l2.normal != face.normal
		l3.smooth = l3.normal != face.normal

		face.calc_area()

	for vert in verts:
		vert.calc_normal()
		vert.calc_pointiness()
		vert.calc_crease()


func commit(primitive = Mesh.PRIMITIVE_TRIANGLES, mesh = null):
	_surface_tool.clear()
	_surface_tool.begin(primitive)

	for face in faces:
		var l1 = face.loops[0]
		var l2 = face.loops[1]
		var l3 = face.loops[2]

		_commit_loop(l1)
		_commit_loop(l2)
		_commit_loop(l3)

	_surface_tool.index()
	return _surface_tool.commit(mesh)


func _commit_loop(loop):
	_surface_tool.add_normal(loop.normal)
	_surface_tool.add_uv(loop.uv)
	_surface_tool.add_uv2(loop.uv2)
	_surface_tool.add_color(loop.color)
	#_surface_tool.add_bones(loop.vert.bones)
	#_surface_tool.add_weights(loop.vert.weights)
	_surface_tool.add_vertex(loop.vert.position)


func flip():
	for face in faces:
		face.flip()

func calc_normals():
	for face in faces:
		face.calc_normal()
	for vert in verts:
		vert.calc_normal()

	for loop in loops:
		loop.calc_normal()

func grow(amount = 1.0):
	for vert in verts:
		vert.position += vert.normal * amount


func _sort_by_index(a,b):
	return a.index < b.index

# need to read up about bmesh and see if I can do something similar
"""
need a structure for editing a mesh
- Need to be able to edit the mesh, then commit the change or not if we want
- need to be able to visualize that
- need to have a good method for constructing a mesh easily
- will probably need my own data structures that hold info like bmesh does
"""
