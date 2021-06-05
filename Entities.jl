module Entities


using Colors: Vector
using GLFW
using ModernGL

export AbstractEntity, AbstractGroup, Entity, Group

abstract type AbstractEntity end
abstract type AbstractGroup end

mutable struct Entity <: AbstractEntity
    pos::Vector{GLfloat}
    dpos::Vector{GLfloat}
    ang::GLfloat
    dang::GLfloat
    bounds::Vector{Vector{GLfloat}}
    status::Dict{String, Any}
    function Entity(pos::Vector{GLfloat}, ang::GLfloat, size::Vector{GLfloat}, status_list::Vector{Tuple{String, T}} = Tuple{String, Any}[]) where {T <: Any}
        box_size = [abs(size[2]*sin(ang)) + abs(size[1]*cos(ang)), abs(size[1]*sin(ang)) + abs(size[2]*cos(ang))]
        bounds = [pos - box_size/2, pos + box_size/2] # [[xmin, ymin], [xmax, ymax]]
        status = Dict{String, Any}()
        for s in status_list
            status[s[1]] = s[2]
        end
        return new(pos, [0., 0.], ang, 0., bounds, status)
    end
end

mutable struct Group <: AbstractGroup
    type_id::String
    n::Int64
    size::Vector{GLfloat}
    shape::Tuple{UInt32, Any}
    color::Vector{GLfloat}
    entities::Vector{Entity}
    function Group(type_id::String, size::Vector{GLfloat}, shape::Tuple{UInt32, Any}, pos_list::Vector{Vector{GLfloat}},
        ang_list::Vector{GLfloat}, color::Vector{GLfloat}, status_list::Vector{Tuple{String, T}} = Tuple{String, Any}[]) where {T <: Any}
        G = new(type_id, 0, size, shape, color, Entity[])
        for i = 1:length(pos_list)
            add!(G, Entity(pos_list[i], ang_list[i], size, status_list))
        end
        return G
    end
    function Group(type_id::String, size::Vector{GLfloat}, shape::Tuple{UInt32, Any}, color::Vector{GLfloat}, entity_list::Vector{Entity})
        G = new(type_id, 0, size, shape, color, Entity[])
        for i = 1:length(entity_list)
            add!(G, entity_list[i])
        end
        return G
    end
    function Group(type_id::String, size::Vector{GLfloat}, shape::Tuple{UInt32, Any}, color::Vector{GLfloat}, entity::Entity)
        G = new(type_id, 0, size, shape, color, Entity[])
        add!(G, entity)
        return G
    end
end

function add!(G::Group, E::AbstractEntity)
    G.n = G.n + 1
    push!(G.entities, E)
end

function remove!(G::Group, i::Int64)
    G.n = G.n - 1
    deleteat!(G.entities, i)
end

function evolve!(G::Group)
    # Q: mod angles by 2pi?
    for i = 1:G.n
        G.entities[i].pos = G.entities[i].pos + G.entities[i].dpos
        G.entities[i].ang = G.entities[i].ang + G.entities[i].dang
        box_size = [abs(G.size[2]*sin(G.entities[i].ang)) + abs(G.size[1]*cos(G.entities[i].ang)),
                    abs(G.size[1]*sin(G.entities[i].ang)) + abs(G.size[2]*cos(G.entities[i].ang))]
        G.entities[i].bounds = [G.entities[i].pos - box_size/2, G.entities[i].pos + box_size/2] # [[xmin, ymin], [xmax, ymax]]
    end
end
function evolve!(V::Vector{Group})
    for G in V
        evolve!(G)
    end
end

function draw(G::Group, program::UInt32)
    color_location = glGetUniformLocation(program, "this_color")
    glUniform3f(color_location, G.color[1], G.color[2], G.color[3])
    for i = 1:G.n
        E = G.entities[i]
        vertices = G.shape[2](E.pos, G.size[1])
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
        glDrawArrays(G.shape[1], 0, length(vertices)/2)
    end
end
function draw(VG::Vector{Group}, program::UInt32)
    # First groups in G are drawn on top (drawn last)
    for G in reverse(VG)
        draw(G::Group, program)
    end
end

function pos_list(G::Group)
    R = Vector{Vector{GLfloat}}(undef, G.n)
    for i = 1:G.n
        R[i] = G.entities[i].pos
    end
    return R
end


end
