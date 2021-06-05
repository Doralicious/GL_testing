
import GLFW

using ModernGL
using GLAbstraction
using LinearAlgebra

include("util.jl")

## General Constants

res = (540, 540)

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

function ortho_projection(x0, y0, w, h)
    x1 = x0 + w
    y1 = y0 + w
    return [2/(y1-x0) 0         0 -(y1+x0)/(y1-x0);
            0         2/(x1-y0) 0 -(x1+y0)/(x1-y0);
            0         0         1 0;
            0         0         0 1]
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

a = GLfloat(0.1) # player width
s = GLfloat(0.3) # player speed in screen units per second

player_shape = (GL_TRIANGLE_FAN, oct_data)
rock_shape = (GL_TRIANGLE_FAN, oct_data)

## Initialize Variables

t0 = GLfloat(time()) # time is in seconds
t = GLfloat(0.)

player = Entity(GLfloat[0., 0.], GLfloat(0.), GLfloat[a, a])
gp = Group("player", GLfloat[a, a], player_shape, GLfloat[1.0, 1.0, 1.0], player)

n_r = 130
sz_r = GLfloat[0.05, 0.05]
pos_r = rand_2vecs_square(n_r, [[-1, -1], [1, 1]])
ang_r = zeros(GLfloat, n_r)
c_r = GLfloat[0.55, 0.55, 0.55]
gr = Group("Rock", sz_r, rock_shape, pos_r, ang_r, c_r)


## Initialize GL

GLFW.Init()
window = GLFW.CreateWindow(res[1], res[2], "Simple Example")
GLFW.MakeContextCurrent(window)
glViewport(0, 0, res[1], res[2])

const vsh = """
    #version 300 es
    precision highp float;
    in vec2 position;
    uniform mat4 persp;
    void main() {
        gl_Position = vec4(position, 0.0, 1.0);
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
    println(fps)

    wasd = [GLFW.GetKey(window, GLFW.KEY_W), GLFW.GetKey(window, GLFW.KEY_A), GLFW.GetKey(window, GLFW.KEY_S), GLFW.GetKey(window, GLFW.KEY_D)]

    ### Physics
    drdt = s * GLfloat[wasd[4] - wasd[2], wasd[1] - wasd[3]]
    drdtnorm = norm(drdt, 2)

    drdt = if drdtnorm > 0
        drdt/drdtnorm
    else
        GLfloat[0., 0.]
    end
    player.dpos = drdt*dt

    Entities.evolve!(gp)
    ## End Physics

    ## Control Camera
    Vx = round(Int32, -player.pos[1]/2 .* res[1])
    Vy = round(Int32, -player.pos[2]/2 .* res[2])
    glViewport(Vx, Vy, res[1], res[2])
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

    glClearColor(GLfloat(0.), GLfloat(0.), GLfloat(0.), GLfloat(1.))
    glClear(GL_COLOR_BUFFER_BIT)
    Entities.draw([gp, gr], program)

    GLFW.PollEvents()
    GLFW.SwapBuffers(window)
end

## Exit

GLFW.Terminate()
