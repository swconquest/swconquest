# This example assumes we have a mesh object selected

import bpy
import bmesh

# Get the active mesh
me = bpy.context.object.data


# Get a BMesh representation
#bm = bmesh.new()   # create an empty BMesh
#bm.from_mesh(me)   # fill it in from a Mesh


# Modify the BMesh, can do anything here...
#for v in bm.verts:
#    v.co.x += 1.0


# Finish up, write the bmesh back to the mesh
#bm.to_mesh(me)
#bm.free()  # free and prevent further access

#bm.uv_layers.active

vcol=me.vertex_colors.new(name="Lightmap UV Encoding")

for p in me.polygons:
    for loop in p.loop_indices:
        uv=me.uv_layers.active.data[0].uv
        vcol.data[loop].color=(uv[0],uv[1],0)


#refresh the view
for area in bpy.context.screen.areas:
    if area.type in ['IMAGE_EDITOR', 'VIEW_3D']:
        area.tag_redraw()
        
        
        
        
        
        
        
#---------------------------------------


# This example assumes we have a mesh object selected

import bpy
import bmesh

# Get the active mesh
me = bpy.context.object.data


# Get a BMesh representation
#bm = bmesh.new()   # create an empty BMesh
#bm.from_mesh(me)   # fill it in from a Mesh


# Modify the BMesh, can do anything here...
#for v in bm.verts:
#    v.co.x += 1.0


# Finish up, write the bmesh back to the mesh
#bm.to_mesh(me)
#bm.free()  # free and prevent further access

#bm.uv_layers.active

vcol=me.vertex_colors.new(name="Lightmap UV Encoding")

for p in me.polygons:
    for loop in p.loop_indices:
        uv=me.uv_layers.active.data[loop].uv
        vcol.data[loop].color=[1-uv[0],1-uv[1],0]


#refresh the view
for area in bpy.context.screen.areas:
    if area.type in ['IMAGE_EDITOR', 'VIEW_3D']:
        area.tag_redraw()
        
        
        
#-----------------------------------------------

# This example assumes we have a mesh object selected

import bpy
import bmesh

# Get the active mesh
me = bpy.context.object.data


# Get a BMesh representation
#bm = bmesh.new()   # create an empty BMesh
#bm.from_mesh(me)   # fill it in from a Mesh


# Modify the BMesh, can do anything here...
#for v in bm.verts:
#    v.co.x += 1.0


# Finish up, write the bmesh back to the mesh
#bm.to_mesh(me)
#bm.free()  # free and prevent further access

#bm.uv_layers.active

def packlm(m):
    if (m==1.0):
        return 999
    else:
        return m*
    
def decompose(n):
    n=int(n*0xffff)
    nnna=(n&0xff00)>>8
    nnnb=(n&0x00ff)
    return nnna, nnnb

def compose(na,nb):
    return (na<<8|nb)/0xffff

vcol=me.vertex_colors.new(name="Lightmap UV Encoding")

for p in me.polygons:
    for loop in p.loop_indices:
        uv=me.uv_layers.active.data[loop].uv
        vcol.data[loop].color=[uv[0],uv[1],0]


#refresh the view
for area in bpy.context.screen.areas:
    if area.type in ['IMAGE_EDITOR', 'VIEW_3D']:
        area.tag_redraw()
        
        
        

        
#-----------------------------------------------
        
# This example assumes we have a mesh object selected

import bpy
import bmesh

# Get the active mesh
me = bpy.context.object.data


# Get a BMesh representation
#bm = bmesh.new()   # create an empty BMesh
#bm.from_mesh(me)   # fill it in from a Mesh


# Modify the BMesh, can do anything here...
#for v in bm.verts:
#    v.co.x += 1.0


# Finish up, write the bmesh back to the mesh
#bm.to_mesh(me)
#bm.free()  # free and prevent further access

#bm.uv_layers.active

vcol=me.vertex_colors.new(name="Lightmap UV Encoding")
vcol=me.vertex_groups.new(name="LMU")
vcol=me.vertex_groups.new(name="LMV")

for p in me.polygons:
    for loop in p.loop_indices:
        uv=me.uv_layers.active.data[-1].uv
        vcol.data[loop].color=(uv[0],uv[1],0)
        bpy.context.object.vertex_groups[-1].add([loop],uv[0],'REPLACE')
        print(uv[0])


#refresh the view
for area in bpy.context.screen.areas:
    if area.type in ['IMAGE_EDITOR', 'VIEW_3D']:
        area.tag_redraw()
        
        
        
        
        
        
#-------------------------------------


# This example assumes we have a mesh object selected

import bpy
import bmesh

# Get the active mesh
me = bpy.context.object.data

#new everything
vcol=me.vertex_colors.new(name="Lightmap UV Encoding")
_lmu=me.vertex_groups.new(name="LMU")
_lmv=me.vertex_groups.new(name="LMV")

for p in me.polygons:
    for loop in p.loop_indices:
        uv=me.uv_layers.active.data[loop].uv
        vcol.data[loop].color=(uv[0],uv[1],0)
        bpy.context.object.vertex_groups["LMU"].add([loop],uv[0],'REPLACE')
        bpy.context.object.vertex_groups["LMV"].add([loop],uv[1],'REPLACE')

#refresh the view
for area in bpy.context.screen.areas:
    if area.type in ['IMAGE_EDITOR', 'VIEW_3D']:
        area.tag_redraw()