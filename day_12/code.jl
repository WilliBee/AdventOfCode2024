using DelimitedFiles
using BenchmarkTools

@enum Direction N S E W
const STEP = Dict(
    N => CartesianIndex(0, 1),
    S => CartesianIndex(0, -1),
    E => CartesianIndex(1, 0),
    W => CartesianIndex(-1, 0)
)
# This will help track the sides of regions; it stores :
# - :direction -> on which side of the cell is the fence
# - :level -> this will help identify sides that are aligned in their direction; 
#             for horizontal side (N,S) this is the second coordinate (y), 
#             for vertical side (E,W) it's the first coordinate (x)
# - :offset -> this is the complementary coordinate; it will help identify contiguous sides
const SideEntry = NamedTuple{(:direction, :level, :offset), Tuple{Direction,Int,Int}}

@inline check_bounds(pos, R, C) = (1 ≤ pos[1] ≤ R) && (1 ≤ pos[2] ≤ C)
 
# Simply count all sides encountered (part 1)
function update_sides_tracker!(st::Base.RefValue, _, _)
    st[] += 1
end

# Track all sides encountered and store its `SideEntry` (part 2)
function update_sides_tracker!(st::Vector{SideEntry}, dir, pos)
    push!(st, (dir, (dir ∈ (E, W) ? pos.I : reverse(pos.I))...))
end

# Recursively explore all cells of regions and track the sides
function explore_region!(world, pos_tracker, pos, c, sides_tracker)
    R, C = size(world)

    # If already visited, return area=0
    pos_tracker[pos] && return 0

    # Mark current position as explored and increase area
    pos_tracker[pos] = true 
    area = 1

    # Explore other directions
    for (dir, step) in STEP
        # If next position is a map edge or a boundary
        if !check_bounds(pos + step, R, C) || (world[pos + step] != c )
            update_sides_tracker!(sides_tracker, dir, pos)
        else
            area += explore_region!(world, pos_tracker, pos + step, c, sides_tracker)
        end
    end
    return area
end

reset_tracker!(sides_tracker::Vector{SideEntry}) = empty!(sides_tracker)
reset_tracker!(sides_tracker::Base.RefValue) = sides_tracker[] = 0
count_sides(sides::Base.RefValue) = sides[]

function count_sides(sides::Vector{SideEntry})
    # Sort so that sides with same :direction and :level are grouped together;
    # sort for :offset as well, so that 'holes' for sides at same :level can be detected 
    sort!(sides, alg=QuickSort)

    # Count contiguous sides
    count = 1
    @inbounds for i in 2:lastindex(sides)
        s = sides[i]
        s_prev = sides[i-1]

        if s.direction ≠ s_prev.direction || s.level ≠ s_prev.level
            count += 1
        else
            # If 'hole' detected
            if s.offset ≠ s_prev.offset + 1
                count += 1
            end
        end
    end
    count
end

function fencing_price(world, pos_tracker, sides_tracker)
    pos_tracker .= false    
    sum(
        pos_tracker[pos] ? 0 : let
            reset_tracker!(sides_tracker)
            area = explore_region!(world, pos_tracker, pos, world[pos], sides_tracker)
            nb_sides = count_sides(sides_tracker)
            area * nb_sides
        end
        for pos in CartesianIndices(world) 
    )
end

function fencing_price(world, sides_tracker)
    pos_tracker = falses(size(world))
    fencing_price(world, pos_tracker, sides_tracker)
end

function part1(world)
    sides_tracker = Ref(0)
    fencing_price(world, sides_tracker)
end

function part2(world)
    sides_tracker = SideEntry[]
    fencing_price(world, sides_tracker)
end


# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    world = hcat([collect(row) for row in readdlm(filename, String)]...)

    # --- RUN 
    println("Answer part 1 :")  
    @show part1(world)

    println("Answer part 2 :")  
    @show part2(world)

    # --- BENCHMARKING
    println("Benchmarking core loop part 1 : ")
    t = falses(size(world))
    st = Ref(0)
    @btime fencing_price($world, $t, $st)

    println("Benchmarking whole loop part 1: ")
    @btime part1($world)

    println("Benchmarking core loop part 2 : ")
    t = falses(size(world))
    st = SideEntry[]
    @btime fencing_price($world, $t, $st)

    println("Benchmarking whole loop part 2 : ")
    @btime part2($world)
end

main()