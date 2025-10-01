using DelimitedFiles
using BenchmarkTools

# --- HELPERS

# read file → Matrix{UInt8}
read_world(file) = map(UInt8, hcat([collect(row) for row in readdlm(file)]...))

# Check if position is within bounds
@inline check_bounds(pos, R, C) = (1 ≤ pos[1] ≤ R) && (1 ≤ pos[2] ≤ C)

# Determine what the coordinate increment and change of direction will be
const DIR_TO_INT = Dict(UInt8('^')=>1, UInt8('>')=>2, UInt8('v')=>3, UInt8('<')=>4)
const NEXT_STEP = (
    ( (0, -1), 2),   # 1 (^)  -> (Δr, Δc), new_dir
    ( (1,  0), 3),   # 2 (>)
    ( (0,  1), 4),   # 3 (v)
    ((-1,  0), 1),   # 4 (<)
)

# --- PART 1 
function count_positions(world)
    world = copy(world)
    R, C = size(world)
    pos = findfirst(∈(keys(DIR_TO_INT)), world).I
    dir = DIR_TO_INT[world[pos...]]
    world[pos...] = UInt8('X')
    count = 1

    while true
        Δ, nd = NEXT_STEP[dir]
        next = pos .+ Δ
        check_bounds(next, R, C) || break
        if world[next...] == UInt8('#')
            dir = nd
        else
            pos = next
            if world[pos...] == UInt8('.')
                world[pos...] = UInt8('X')
                count += 1
            end
        end
    end
    count
end

# --- PART 2
@inline function step_world!(world, pos, Δ, nd, dir_visit, dir)
    next = pos .+ Δ
    if world[next...] == UInt8('#')
        return pos, nd          # turned
    else
        pos = next
        world[pos...] == UInt8('.') && (world[pos...] = UInt8('X'))
        dir_visit[pos..., dir] = true
        return pos, dir
    end
end

function count_loops(world)
    world = copy(world)
    R, C = size(world)
    
    # Directions in which a cell was visited
    seen_dir = falses(R, C, 4)
    
    # Obstacle positions already tested for creating a loop
    tried_obst = falses(R, C)

    # Initial variables
    pos = findfirst(∈(keys(DIR_TO_INT)), world).I
    dir = DIR_TO_INT[world[pos...]]
    world[pos...] = UInt8('X')
    loops = 0

    # Temporary variables for testing loops
    t_world = similar(world)
    t_seen  = similar(seen_dir)

    while true
        Δ, nd = NEXT_STEP[dir]
        next = pos .+ Δ
        check_bounds(next, R, C) || break

        # Try putting an obstacle at next tile if never tried before
        if world[next...] != UInt8('#') && !tried_obst[next...]
            # Copy current state
            t_world .= world
            t_seen  .= seen_dir

            # Put obstacle
            t_world[next...] = UInt8('#')
            tried_obst[next...] = true
            tpos, tdir = pos, dir

            while true
                tΔ, tnd = NEXT_STEP[tdir]
                tnext = tpos .+ tΔ
                check_bounds(tnext, R, C) || break
                t_seen[tnext..., tdir] && (loops += 1; break)
                tpos, tdir = step_world!(t_world, tpos, tΔ, tnd, t_seen, tdir)
            end
        end

        # Advance guard normally
        pos, dir = step_world!(world, pos, Δ, nd, seen_dir, dir)
    end
    loops
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    world = read_world(filename)

    # --- RUN
    answer_1 = count_positions(world)
    println("Answer part 1 : $answer_1")
    answer_2 = count_loops(world)
    println("Answer part 2 : $answer_2")

    # --- BENCHMARKING
    println("Benchmarking part 1 : ")
    @btime count_positions($world)
    println("Benchmarking part 2 : ")
    @btime count_loops($world)
end

main()
