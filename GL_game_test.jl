
import GLFW

using ModernGL
using GLAbstraction
using LinearAlgebra

include("util.jl")

## General Constants

res = (540, 540)

unit_4mat = GLfloat[1. 0. 0. 0.;
                    0. 1. 0. 0.;
                    0. 0. 1. 0.;
                    0. 0. 0. 1.]

function hex_data(r, a)
    # for use with GL_TRIANGLE_FAN
    # r is position of center of hexagon
    # a is width of hexagon
    q = sin(pi/3)
    p = cos(pi/3)
    data_local = GLfloat[
        0.0, 0.0,
        a/2, 0.0,
        a/2 * p, a/2 * q,
        -a/2 * p, a/2 * q,
        -a/2, 0.0,
        -a/2 * p, -a/2 * q,
        a/2 * p, -a/2 * q,
        a/2, 0.0
    ]
    translate = GLfloat[
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2]
    ]
    return data_local + translate
end
function oct_data(r, a)
    # for use with GL_TRIANGLE_FAN
    # r is position of center of octagon
    # a is width of octagon
    q = cos(pi/4)
    data_local = GLfloat[
    0.0, 0.0,
    a/2, 0.0,
    a/2 * q, a/2 * q,
    0, a/2,
    -a/2 * q, a/2 * q,
    -a/2, 0.0,
    -a/2 * q, -a/2 * q,
    0, -a/2,
    a/2 * q, -a/2 * q,
    a/2, 0.0
    ]
    translate = GLfloat[
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2],
        r[1], r[2]
    ]
    return data_local + translate
end

function ortho_projection(l, b, r, t)
    return GLfloat[2. /(r-l)  0.         0. -(r+l)/(r-l);
                   0.         2. /(t-b)  0. -(t+b)/(t-b);
                   0.         0.         1. 0.;
                   0.         0.         0. 1.]
end

function rand_2vecs_square(n, bounds)
    V = Vector{Vector{GLfloat}}(undef, n)
    range = [bounds[2][1] - bounds[1][1], bounds[2][2] - bounds[1][2]]
    for i = 1:n
        V[i] = rand(Float64, 2) .* range .+ bounds[1]
    end
    return V
end

## Game-Specific Constants

player_width = GLfloat(0.1)
player_speed = GLfloat(0.3)

tree_width = GLfloat(0.05)

rock_width = GLfloat(0.075)

player_shape = (GL_TRIANGLE_FAN, oct_data)
rock_shape = (GL_TRIANGLE_FAN, oct_data)
tree_shape = (GL_TRIANGLE_FAN, oct_data)

tree_growth_rate = GLfloat(0.3)
tree_death_rate = GLfloat(0.25)
tree_max_num = 3000

zoom_speed = 1.0

### Create A New Tree

function closest_2_trees(gt, i0)
    if gt.n < 3
        throw("There must be at least 5 trees in gt for this function to work properly.")
    end
    p0 = gt.entities[i0].pos
    dmin1 = GLfloat(Inf)
    dmin2 = GLfloat(Inf + 1)
    imin1 = 0
    imin2 = 0
    for i in 1:gt.n
        d = norm(gt.entities[i].pos - p0, 2)
        if 0 < d < dmin1
            dmin1 = d
            imin1 = i
        elseif dmin1 < d < dmin2
            dmin2 = d
            imin2 = i
        end
    end
    tmin1 = gt.entities[imin1]
    tmin2 = gt.entities[imin2]

    return (tmin1, tmin2)
end
function new_tree_pos(p0, p1, p2, k = GLfloat(0.5), l = GLfloat(3.5))
    r1 = p1 - p0
    r2 = p2 - p0
    r1m = norm(r1, 2)
    r2m = norm(r2, 2)
    r1r2m = norm(r1 + r2, 2)
    r3h = GLfloat.(-(r1 + r2)/r1r2m)
    r3m = GLfloat(k*(1 - tanh(l*(r1m + r2m)/2)))
    return p0 + r3m*r3h
end
function create_new_tree!(gt, i0, k = GLfloat(0.5), l = GLfloat(3.5))
    p0 = gt.entities[i0].pos
    (t1, t2) = closest_2_trees(gt, i0)
    p1 = t1.pos
    p2 = t2.pos
    p3 = new_tree_pos(p0, p1, p2, k, l)
    abort = false # Prevent overcrowding & degenerate trees
                  # Can probably make this faster by tracking which trees each tree has 'mated' with
                  #     and preventing duplicates that way
    for t in gt.entities
        ri = t.pos - p3
        if GLfloat(norm(ri, 2)) < tree_width/2
            abort = true
            break
        end
    end
    if !abort
        t3 = Entity(p3, GLfloat(0.), sz_t)
        Entities.add!(gt, t3)
    end
end

### End Create A New Tree

## Initialize Variables

t0 = GLfloat(time()) # time is in seconds
t = GLfloat(0.)

zoom = GLfloat(1.)

player = Entity(GLfloat[0., 0.], GLfloat(0.), [player_width, player_width])
gp = Group("player", [player_width, player_width], player_shape, GLfloat[1.0, 1.0, 1.0], player)

n_t = 10
sz_t = [tree_width, tree_width]
pos_t = rand_2vecs_square(n_t, [[-0.5, -0.5], [0.5, 0.5]])
ang_t = zeros(GLfloat, n_t)
c_t = GLfloat[0.0, 0.9, 0.0]
gt = Group("tree", sz_t, tree_shape, pos_t, ang_t, c_t)

n_r = 130
sz_r = [rock_width, rock_width]
pos_r = rand_2vecs_square(n_r, [[-1, -1], [1, 1]])
ang_r = zeros(GLfloat, n_r)
c_r = GLfloat[0.55, 0.55, 0.55]
gr = Group("Rock", sz_r, rock_shape, pos_r, ang_r, c_r)

groups = [gp, gt, gr]

## Initialize GL

GLFW.Init()
window = GLFW.CreateWindow(res[1], res[2], "Simple Example")
GLFW.MakeContextCurrent(window)
glViewport(0, 0, res[1], res[2])

const vsh = """
    #version 300 es
    precision highp float;
    uniform mat4 projection;
    in vec2 position;
    void main() {
        gl_Position = projection * vec4(position, 0.0, 1.0);
    }
"""

const fsh = """
    #version 300 es
    precision highp float;
    out vec4 outColor;
    uniform vec3 this_color;
    void main() {
        outColor = vec4(this_color, 1.0);
    }
"""

## Main Loop

while !GLFW.WindowShouldClose(window)
    t_prev = t
    global t = time() - t0
    dt = t - t_prev
    fps = 1/dt
    #println(fps)

    wasd = [GLFW.GetKey(window, GLFW.KEY_W), GLFW.GetKey(window, GLFW.KEY_A), GLFW.GetKey(window, GLFW.KEY_S), GLFW.GetKey(window, GLFW.KEY_D)]

    plusminus = [GLFW.GetKey(window, GLFW.KEY_EQUAL), GLFW.GetKey(window, GLFW.KEY_MINUS)]

    ### Physics
    drdt = player_speed * GLfloat[wasd[4] - wasd[2], wasd[1] - wasd[3]]
    drdtnorm = norm(drdt, 2)

    drdt = if drdtnorm > 0
        drdt/drdtnorm
    else
        GLfloat[0., 0.]
    end
    player.dpos = drdt*dt

    Entities.evolve!(gp)

    if gt.n < tree_max_num
        for i in 1:gt.n
            if rand() < tree_growth_rate * dt
                create_new_tree!(gt, i)
            elseif rand() < tree_death_rate * dt
                Entities.remove!(gt, i)
            end
        end
    end
    ## End Physics

    ## Control Camera
    global zoom = zoom + zoom * zoom_speed * GLfloat(plusminus[1] - plusminus[2]) * dt
    projection = ortho_projection(player.pos[1]-zoom, player.pos[2]-zoom, player.pos[1]+zoom, player.pos[2]+zoom)
    ## End Control Camera

    vao = glGenVertexArray()
    glBindVertexArray(vao)
    vbo = glGenBuffer()
    glBindBuffer(GL_ARRAY_BUFFER, vbo)

    vertexShader = createShader(vsh, GL_VERTEX_SHADER)
    fragmentShader = createShader(fsh, GL_FRAGMENT_SHADER)
    program = createShaderProgram(vertexShader, fragmentShader)
    glUseProgram(program)

    positionAttribute = glGetAttribLocation(program, "position");
    glEnableVertexAttribArray(positionAttribute)
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)

    projection_uniform = glGetUniformLocation(program, "projection")
    glUniformMatrix4fv(projection_uniform, 1, GL_FALSE, projection)

    glClearColor(GLfloat(0.), GLfloat(0.), GLfloat(0.), GLfloat(1.))
    glClear(GL_COLOR_BUFFER_BIT)
    Entities.draw(groups, program)

    GLFW.PollEvents()
    GLFW.SwapBuffers(window)
end

## Exit

GLFW.Terminate()
