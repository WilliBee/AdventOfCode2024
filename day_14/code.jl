using StaticArrays
using SparseArrays
using BenchmarkTools

struct Robot
    p::SVector{2, Int}
    v::SVector{2, Int}
end
const pat = r"p=(-?\d+),(-?\d+) v=(-?\d+),(-?\d+)"
const W = 101
const T = 103

function parse_input(filename)
    txt = read(filename, String)
    [let
        px, py, vx, vy = parse.(Int, r.captures)
        Robot(SVector(px, py), SVector(vx, vy))
    end
    for r in eachmatch(pat, txt)]
end

@inline move(r) = Robot(mod.(r.p + r.v, (W, T)), r.v)
@inline qrange(x, lo, mid, hi) = lo ≤ x < mid ? 1 : (mid+1 ≤ x < hi ? 2 : 0)

# --- PART 1
function calculate_safety_factor!(robots; iter=100)
    for _ in 1:iter
        robots .= move.(robots)
    end
    counts = zero(MVector{4,Int})
    for r in robots
        x, y = r.p
        qx = qrange(x, 0, W÷2, W)
        qy = qrange(y, 0, T÷2, T)
        if qx ≠ 0 && qy ≠ 0             # skip the middle lines
            counts[2(qy-1) + qx] += 1
        end
    end
    *(counts...)
end

# --- PART 2
function visualize!(robots, map; offset_i=0, max_iter=20, disp_all=true)
    for i in 1:max_iter
        map .= 0
        dropzeros!(map)
        robots .= move.(robots)
        for r in robots
            map[(r.p .+ 1)...] += 1
        end
        offset_i += 1
        if disp_all || i == max_iter
            @show offset_i
            display(map')
        end
    end
    offset_i
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    robots_o = parse_input(filename)

    # --- RUN
    println("PART 1")
    @show calculate_safety_factor!(copy(robots_o))

    println("PART 2")
    robots = copy(robots_o)
    map = sparse(zeros(Int, W, T))
    k = 0
    k = visualize!(robots, map, offset_i=k, max_iter=115, disp_all=false)
    k = visualize!(robots, map, offset_i=k, max_iter=101, disp_all=false)
    k = visualize!(robots, map, offset_i=k, max_iter=101*60, disp_all=false)
    k = visualize!(robots, map, offset_i=k, max_iter=101, disp_all=false)

    # --- BENCHMARKING
    println("Benchmarking core loop : ")
    @btime calculate_safety_factor!($robots_o)
end

main()
