using DataStructures
using LinearAlgebra: ⋅
using BenchmarkTools

const H, W = 71, 71
const START = CartesianIndex(1, 1)
const GOAL  = CartesianIndex(H, W)
const OFFSET = CartesianIndex(1, 1)     # 1-based index
const DIR = Dict(
    '^' => CartesianIndex(-1, 0),
    '>' => CartesianIndex( 0, 1),
    'v' => CartesianIndex( 1, 0),
    '<' => CartesianIndex( 0,-1)
)

read_obstacles(filename) = [
    CartesianIndex(parse.(Int, x)...)
    for x in split.(readlines(filename), ",")
]

@inline checkbounds(pos) = (1 ≤ pos[1] ≤ H) && (1 ≤ pos[2] ≤ W)

function bfs!(best, Q, maze, start, goal)
    empty!(best)
    empty!(Q)
    enqueue!(Q, (start, '>') => 0)
    best[(start, '>')] = 0

    while !isempty(Q)
        (pos, dir), cost = popfirst!(Q)
        cost > get(best, (pos, dir), typemax(Int)) && continue
        pos == goal && break                                        # Reached target

        for new_dir in keys(DIR)
            nxt       = pos + DIR[new_dir]
            !checkbounds(nxt) && continue
            maze[nxt] == '#' && continue
            new_cost = cost + 1
            old_cost = get!(best, (nxt, new_dir), typemax(Int))

            if new_cost < old_cost
                best[(nxt, new_dir)] = new_cost
                Q[(nxt, new_dir)]  = new_cost
            end
        end
    end
    return minimum(get(best, (goal, d), typemax(Int)) for d in keys(DIR))
end

function init_buffers()
    best  = Dict{Tuple{CartesianIndex{2},Char},Int}()
    queue = PriorityQueue{Tuple{CartesianIndex{2},Char},Int}()
    best, queue
end

function solve(maze, best, queue, obstacles, n)
    # Initialize maze
    maze .= '.'

    # Part 1 : Make obstacles fall and find shortest path
    for i in 1:n
        maze[obstacles[i] + OFFSET] = '#'
    end

    pt1 = bfs!(best, queue, maze, START, GOAL)

    # Part 2 : Binary search on remaining bytes
    lo, hi = n+1, length(obstacles)
    while lo < hi
        mid = (lo + hi) ÷ 2

        # Mark new obstacles
        for i in (n+1):mid
            maze[obstacles[i] + OFFSET] = '#'
        end

        cost = bfs!(best, queue, maze, START, GOAL)

        # Next search
        if cost == typemax(Int)          # path blocked
            hi = mid                     # answer ≤ mid
        else
            lo = mid + 1                 # answer > mid
        end

        # Rollback for next iteration
        for i in (n+1):mid
            maze[obstacles[i] + OFFSET] = '.'
        end
    end
    return pt1, obstacles[lo]
end

# --- MAIN
function main()
    obstacles = read_obstacles(joinpath(@__DIR__, "input.txt"))

    # --- RUN
    maze = Matrix{Char}(undef, H, W)
    best, queue = init_buffers()
    n = 1024
    println("PART 1 & 2")
    @show solve(maze, best, queue, obstacles, n)

    # --- BENCHMARKING
    println("Benchmark hot loop")
    @btime solve($maze, $best, $queue, $obstacles, $n)
end

main()