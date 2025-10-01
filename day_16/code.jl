using DataStructures
using LinearAlgebra: ⋅
using SparseArrays
using BenchmarkTools

const DIR = Dict(
    '^' => CartesianIndex(-1, 0),
    '>' => CartesianIndex( 0, 1),
    'v' => CartesianIndex( 1, 0),
    '<' => CartesianIndex( 0,-1)
)
const COST_FORWARD = 1
const COST_TURN    = 1000

# -- PART 1 & 2
@inline function dijkstra!(best, Q, prev::Dict{T,Vector{T}}, maze, start, goal) where T
    enqueue!(Q, (start, '>') => 0)
    best[(start, '>')] = 0

    while !isempty(Q)
        (pos, dir), cost = popfirst!(Q)
        cost > get(best, (pos, dir), typemax(Int)) && continue
        pos == goal && break                                        # Reached target

        for new_dir in keys(DIR)
            DIR[new_dir].I ⋅ DIR[dir].I == -1 && continue           # 180° turn not allowed
            nxt       = pos + DIR[new_dir]
            maze[nxt] == '#' && continue

            turn_cost = (new_dir == dir ? 0 : COST_TURN)
            new_cost = cost + turn_cost + COST_FORWARD
            old_cost = get!(best, (nxt, new_dir), typemax(Int))

            parents = get!(prev, (nxt, new_dir)) do
                T[]
            end

            if new_cost < old_cost                                  # Strictly better path
                best[(nxt, new_dir)] = new_cost
                Q[(nxt, new_dir)]  = new_cost
                empty!(parents)
            end
            if new_cost ≤ old_cost                                  # Equally good or better path
                push!(parents, (pos, dir))
            end
        end
    end
    return minimum(get(best, (goal, d), typemax(Int)) for d in keys(DIR))
end

# Back-track all optimal (pos, dir) states
function trace_optimal!(seen, frontier, best, prev, goal)
    best_cost = minimum(get(best, (goal, d), typemax(Int)) for d in keys(DIR))
    isinf(best_cost) && error("no path")

    # Seed frontier with every direction that achieves best cost
    for d in keys(DIR)
        if get(best, (goal, d), typemax(Int)) == best_cost
            push!(frontier, (goal, d))
        end
    end

    while !isempty(frontier)
        state = pop!(frontier)
        state ∈ seen && continue
        push!(seen, state)
        haskey(prev, state) && append!(frontier, prev[state])
    end
    return seen
end

function init_buffers()
    best  = Dict{Tuple{CartesianIndex{2},Char},Int}()
    queue = PriorityQueue{Tuple{CartesianIndex{2},Char},Int}()
    prev = Dict{Tuple{CartesianIndex{2},Char},Vector{Tuple{CartesianIndex{2},Char}}}()
    seen   = Set{Tuple{CartesianIndex{2},Char}}()
    frontier = Tuple{CartesianIndex{2},Char}[]
    solution = Set{CartesianIndex{2}}()
    best, queue, prev, seen, frontier, solution
end

function solve!(best, queue, prev, seen, frontier, solution, maze, start, goal)
    best_cost = dijkstra!(best, queue, prev, maze, start, goal)
    seen_states = trace_optimal!(seen, frontier, best, prev, goal)
    for (pos, _) in seen_states                             # Unique positions
        push!(solution, pos)
    end
    best_cost, solution
end

function solve(maze, start, goal)
    buffers = init_buffers()
    solve!(buffers..., maze, start, goal)
end

function benchmark_maze(buffers, maze, start, goal)
    b, q, p, s, f, sol = buffers
    map(empty!, (b, q, s, f, sol))
    for v in values(p)
        empty!(v)
    end
    solve!(b, q, p, s, f, sol, maze, start, goal)
end

# --- MAIN
function main()
    maze  = permutedims(reduce(hcat, collect.(readlines(joinpath(@__DIR__, "input.txt")))))
    S = findfirst(==('S'), maze)
    E  = findfirst(==('E'), maze)

    # --- RUN
    println("PART 1 & 2")
    best_cost, best_path = solve(maze, S, E)
    @show best_cost
    @show length(best_path)

    # Visualize path
    dm = zeros(size(maze)) |> sparse
    dm[collect(best_path)] .= 1
    display(dm)

    # --- BENCHMARKING
    buffers = init_buffers()
    println("Benchmark init_buffers")
    @btime init_buffers()
    println("Benchmark hot loop")
    @btime benchmark_maze($buffers, $maze, $S, $E)
end

main()