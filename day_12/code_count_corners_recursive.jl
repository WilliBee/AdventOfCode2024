using DelimitedFiles
using BenchmarkTools

@enum Direction N S E W
const STEP = Dict(
    N => CartesianIndex(0, 1),
    S => CartesianIndex(0, -1),
    E => CartesianIndex(1, 0),
    W => CartesianIndex(-1, 0)
)
const CORNER_PATS_DIAG = (                          # Diagonal corner masks
    CartesianIndex( 1, 1),
    CartesianIndex(-1, 1), 
    CartesianIndex( 1,-1),
    CartesianIndex(-1,-1),
)
const CORNER_PATS_L = (                             # L-shaped corner masks
    (CartesianIndex( 1, 0),CartesianIndex( 0, 1)), 
    (CartesianIndex( 1, 0),CartesianIndex( 0,-1)),
    (CartesianIndex(-1, 0),CartesianIndex( 0, 1)), 
    (CartesianIndex(-1, 0),CartesianIndex( 0,-1)),
)
@inline check_bounds(pos, R, C) = (1 ≤ pos[1] ≤ R) && (1 ≤ pos[2] ≤ C)
@inline mask(ci::CartesianIndex{N}, dim, val=0) where {N} =
    CartesianIndex(ntuple(d -> d == dim ? val : ci.I[d], Val(N)))

# Recursively explore all cells of regions and track the sides
function explore_region!(world, pos_tracker, pos, c)
    R, C = size(world)

    # If already visited, return area=0
    pos_tracker[pos] && return 0, 0, 0

    # Mark current position as explored and increase area
    pos_tracker[pos] = true 
    area = 1
    perimeter = 0
    corners = 0

    # Detect corners
    for pat in CORNER_PATS_DIAG
        if check_bounds(pos + pat, R, C) && world[pos + pat]!=c &&
           world[pos + mask(pat, 1)]==c && world[pos + mask(pat, 2)]==c
            corners += 1
        end
    end
    for (pat1, pat2) in CORNER_PATS_L
        if !(check_bounds(pos + pat1, R, C) && world[pos + pat1]==c) &&
           !(check_bounds(pos + pat2, R, C) && world[pos + pat2]==c)
            corners += 1
        end
    end

    # Explore other directions
    for (dir, step) in STEP
        # If next position is a map edge or a boundary
        if !check_bounds(pos + step, R, C) || (world[pos + step] != c )
            perimeter += 1
        else
            a, p, co = explore_region!(world, pos_tracker, pos + step, c)
            area += a
            perimeter += p
            corners += co
        end
    end
    return area, perimeter, corners
end

function fencing_price(world, pos_tracker)
    pos_tracker .= false
    part1, part2 = 0, 0
    for pos in CartesianIndices(world) 
        pos_tracker[pos] ? 0 : let
            area, perimeter, corners = explore_region!(world, pos_tracker, pos, world[pos])
            part1 += area * perimeter
            part2 += area * corners
        end
    end
    part1, part2
end

function fencing_price(world)
    pos_tracker = falses(size(world))
    fencing_price(world, pos_tracker)
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    world = hcat([collect(row) for row in readdlm(filename, String)]...)

    # --- RUN 
    println("Answer part 1 :")  
    @show fencing_price(world)

    # --- BENCHMARKING
    println("Benchmarking core loop : ")
    t = falses(size(world))
    @btime fencing_price($world, $t)

    println("Benchmarking whole loop : ")
    @btime fencing_price($world)
end

main()