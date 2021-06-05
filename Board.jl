module Board


using LinearAlgebra: norm
using Colors: RGB
using ModernGL: GLfloat

import Main.Entities: Group, Entity

export Board, View

# Utility Functions (move to other module?)
rotate(ph) = [cos(ph) -sin(ph); sin(ph) cos(ph)]

mutable struct Board
    size::Tuple{Float64, Float64}
    groups::Vector{Group}
    background::Array{RGB{Float64}, 2}
    function Board(size::Tuple{Float64, Float64}, groups::Vector{Group}, background::Array{RGB{Float64}, 2})
        return new(size, groups, background)
    end
end

mutable struct View
    scene::Scene
    res::Tuple{Int64, Int64}
    fps::Float64
    pos::Vector{Float64}
    zoom::Float64
    image::Array{RGB{Float64}, 2}
    function View(scene::Scene, res::Tuple{Int64, Int64}, pos::Vector{Float64}, zoom::Float64)
        return new(scene, res, 30, pos, zoom, zeros(RGB{Float64}, res))
    end
end

function clear!(B::Board, V::View)
    V.image = copy(B.background)
end

function draw_entity!(B::Board, V::View, G::Group)

end
function draw_entity!(B::Board, V::View)
    # Groups at lower indices are drawn on top
    # That is, closer to the beginning of the vector of groups = higher priority
    for i = length(B.groups):-1:1
        draw_entity!(B, V, B.groups[i])
    end
end

function draw_line!(B::Board, r1::Vector{Float64}, r2::Vector{Float64}, c::RGB{Float64})
    # TODO: make work with View type
    r1 = r1 * B.size[1]
    r2 = r2 * B.size[2]
    drh = (r2 .- r1)./norm(r2 .- r1, 2)
    lx = r1[1]:drh[1]:r2[1]
    ly = r1[2]:drh[2]:r2[2]
    Lp = Vector{Tuple{Int64, Int64}}(undef, length(lx))
    for i = 1:length(lx)
        Lp[i] = Int64.(round.((clamp(lx[i], 1, B.size[1]), clamp(ly[i], 1, B.size[2]))))
    end
    Lp = unique(push!(Lp, Int64.(round.((clamp(r2[1], 1, B.size[1]), clamp(r2[2], 1, B.size[2]))))))
    for I in Lp
        B.image[I[1], I[2]] = c
    end
end

function display!(V::View, Frame::Observable{Array{RGB{Float64}, 2}})

end


end
