using BenchmarkTools

# Cache (stone, remaining steps) => number of children
const CACHE = Dict{Tuple{Int,Int},Int}()

function blink(x, step)
    # Terminal node
    step == 0 && return 1
    # Short-circuit recursion if pattern in CACHE
    get!(CACHE, (x, step)) do
        nd = ndigits(x)
        if x == 0
            blink(1, step - 1)
        elseif iseven(nd)
            d = (10 ^ (nd ÷ 2))
            a = x ÷ d
            b = x - a * d
            blink(a, step - 1) + blink(b, step - 1)
        else
            blink(x * 2024, step - 1)
        end
    end
end

count_stones(data, steps) = sum(s -> blink(s, steps), data)

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    data = parse.(Int, split(read(filename, String)))

    # --- RUN 
    println("Answer part 1 :")   
    @show count_stones(data, 25)
    println("Answer part 2 :")   
    @show count_stones(data, 75)

    # --- BENCHMARKING
    println("Benchmarking whole loop part 1 : ")
    @btime count_stones($data, 25)
    println("Benchmarking whole loop part 2 : ")
    @btime count_stones($data, 75)
end

main()