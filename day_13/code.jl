using StaticArrays
using BenchmarkTools

struct Machine
    A::SVector{2, Int}
    B::SVector{2, Int}
    P::SVector{2, Int}
end
const block_pat = r"^Button A: X\+(\d+), Y\+(\d+)\nButton B: X\+(\d+), Y\+(\d+)\nPrize: X=(\d+), Y=(\d+)$"ms
const costs = SVector(3, 1)

function parse_input(filename; offset=0)
    txt = read(filename, String)
    [
        let
            ax, ay, bx, by, px, py = parse.(Int, m.captures)
            Machine(SVector(ax, ay), SVector(bx, by), SVector(px+offset, py+offset))
        end
        for m in eachmatch(block_pat, txt)
    ]
end

function count_tokens(machines)
    Int(sum(
        let 
            x = [m.A m.B] \ m.P
            all(isinteger.(x)) ? costs' * x : 0
        end
        for m in machines
    ))
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")

    # --- RUN and BENCHMARKING
    println("PART 1")
    machines = parse_input(filename)
    @show count_tokens(machines)
    @btime count_tokens($machines)

    println("PART 2")
    machines = parse_input(filename, offset=10000000000000)
    @show count_tokens(machines)
    @btime count_tokens($machines)
end

main()