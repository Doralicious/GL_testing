
import GLFW
using ModernGL
using GLAbstraction
using LinearAlgebra

include("util.jl")

## General Constants

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

## Game-Specific Constants

a = GLfloat(0.1) # player width
s = GLfloat(0.3) # player speed in screen units per second

## Initialize Variables

t0 = GLfloat(time()) # time is in seconds
t = GLfloat(0.)

r = GLfloat[0., 0.]

## Initialize GL

GLFW.Init()
window = GLFW.CreateWindow(1080, 1080, "Simple Example")
GLFW.MakeContextCurrent(window)

const vsh = """
    #version 300 es
    precision highp float;
    in vec2 position;
    void main() {
        gl_Position = vec4(position, 0.0, 1.0);
    }
"""

const fsh = """
    #version 300 es
    precision highp float;
    out vec4 outColor;
    void main() {
        outColor = vec4(1.0, 1.0, 1.0, 1.0);
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

    drdt = s * GLfloat[wasd[4] - wasd[2], wasd[1] - wasd[3]]
    drdtnorm = norm(drdt, 2)
    drdt = if drdtnorm > 0
        drdt/drdtnorm
    else
        GLfloat[0.0, 0.0]
    end
    dr = drdt*dt

    global r = r + dr

    data = oct_data(r, a)

    vao = glGenVertexArray()
    glBindVertexArray(vao)
    vbo = glGenBuffer()
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW)

    vertexShader = createShader(vsh, GL_VERTEX_SHADER)
    fragmentShader = createShader(fsh, GL_FRAGMENT_SHADER)
    program = createShaderProgram(vertexShader, fragmentShader)
    glUseProgram(program)
    positionAttribute = glGetAttribLocation(program, "position");
    glEnableVertexAttribArray(positionAttribute)
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, C_NULL)

    glClearColor(0.0, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)
    glDrawArrays(GL_TRIANGLE_FAN, 0, 10)
    #glDrawArrays(primitive, starting point, count)

    GLFW.PollEvents()
    GLFW.SwapBuffers(window)
end

## Exit

GLFW.Terminate()
