using DelimitedFiles
using BenchmarkTools

# --- HELPERS

read_world(file) = hcat([collect(row) for row in readdlm(file)]...)
@inline check_bounds(pos, R, C) = (1 ≤ pos[1] ≤ R) && (1 ≤ pos[2] ≤ C)

# --- PART 1
function count_antinodes(world, mark_antinodes_func)
    R, C = size(world)
    antenna_locations = Dict(
        c => findall(==(c), world)
        for c in unique(world) if c != '.'
    )
    antinodes_locations = falses(R, C)
    mark_all_antinodes!(antinodes_locations, antenna_locations, R, C, mark_antinodes_func)
    sum(antinodes_locations)
end

# For all pairs of locations, mark location of antinodes
@inline function mark_all_antinodes!(antinodes, locations, R, C, mark_antinodes_func)
    for (_, coords_list) in locations
        n = length(coords_list)
        # Loops through all pairs without allocating; equivalent to using `Combinatorics.combinations`
        @inbounds for i in 1:n, j in i+1:n
            a, b = coords_list[i], coords_list[j]
            diff = b .- a
            mark_antinodes_func(antinodes, a, diff, -, R, C)
            mark_antinodes_func(antinodes, b, diff, +, R, C)
        end
    end
end

# Mark location of antinode as defined by part 1 of the puzzle
@inline function mark_antinodes!(antinodes, pos, diff, f, R, C)
    pos = f.(pos, diff)
    check_bounds(pos, R, C) && (antinodes[pos] = true)
end

# --- PART 2
# Mark location of antinode as defined by part 2 of the puzzle
@inline function mark_antinodes_resonance!(antinodes, pos, diff, f, R, C)
    antinodes[pos] = true
    while true
        pos = f.(pos, diff)
        (check_bounds(pos, R, C) && (antinodes[pos] = true)) || break
    end
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    world = read_world(filename)

    # --- RUN
    answer_1 = count_antinodes(world, mark_antinodes!)
    println("Answer part 1 : $answer_1")
    answer_2 = count_antinodes(world, mark_antinodes_resonance!)
    println("Answer part 2 : $answer_2")

    # --- BENCHMARKING
    println("Benchmarking part 1 : ")
    @btime count_antinodes($world, $mark_antinodes!)
    println("Benchmarking part 2 : ")
    @btime count_antinodes($world, $mark_antinodes_resonance!)
end

main()