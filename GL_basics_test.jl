
import GLFW
using ModernGL
using GLAbstraction

include("util.jl")

GLFW.Init()
window = GLFW.CreateWindow(500, 500, "Simple Example")
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

L = 500
for i = 1:L
    #println(i)

    kbin = GLFW.GetKey(window, GLFW.KEY_A)
    println(kbin)

    if kbin
        data = GLfloat[
            1. - 0.5*(i/L), 0.5,
            -0.5, -0.5,
            0.5,-0.5,
            1.0, 0.0
        ]
    else
        data = GLfloat[
            0.5*(i/L), 0.5,
            -0.5, -0.5,
            0.5,-0.5,
            1.0, 0.0
        ]
    end

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
    glDrawArrays(GL_TRIANGLES, 0, 3)
    glDrawArrays(GL_TRIANGLES, 1, 3)
    #glDrawArrays(primitive, starting point, count)

    GLFW.PollEvents()
    GLFW.SwapBuffers(window)
end


#=while !GLFW.WindowShouldClose(window)
    glClearColor(0.0, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
end=#

GLFW.Terminate()
