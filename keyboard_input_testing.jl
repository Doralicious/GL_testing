# Made by adamslc on discourse.julialang.org (https://discourse.julialang.org/t/polling-keyboard-input-looking-for-e-g-q-in-a-loop-to-gracefully-terminate-execution/812) & modified by me

function monitorInput()
    # Put STDIN in 'raw mode'
    ccall(:jl_tty_set_mode, Int32, (Ptr{Nothing}, Int32), stdin.handle, true) == 0 || throw("FATAL: Terminal unable to enter raw mode.")

    inputBuffer = Channel{Char}(100)

    @async begin
        while true
            c = read(stdin, Char)
            put!(inputBuffer, c)
        end
    end
    return inputBuffer
end

inputBuffer = monitorInput()
exit = false
i = 0
while !exit
    global i = i + 1
    if isready(inputBuffer)# && take!(inputBuffer) == 'q'
        kbin = take!(inputBuffer)
        println(kbin)
        if kbin == 'p'
            global exit = true
        end
    end
    sleep(1/256)
end

println("\nPlease have a nice day!")
