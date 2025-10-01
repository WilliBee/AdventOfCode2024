using DataStructures
using BenchmarkTools

const DIR = (CartesianIndex(-1, 0), CartesianIndex(0, 1), CartesianIndex(1, 0), CartesianIndex(0, -1))
const UNITS = (DIR[2], DIR[3])

@inline check_bounds(pos, x1, x2, y1, y2) = (x1 ≤ pos[1] ≤ x2) && (y1 ≤ pos[2] ≤ y2)

# Label track with distances from start
function label_track!(distances, maze, S, E)
    fill!(distances, -1)
    pos, k = S, 0
    distances[pos] = k
    while pos != E
        for dir in DIR
            if maze[pos + dir] == '.' && distances[pos + dir] == -1
                pos += dir
                k += 1
                distances[pos] = k
                break
            end
        end
    end
end

# Find shortcuts by matching pattern
@inline function find_shortcut_pattern!(savings, maze, distances, I)
    for unit in UNITS
        pos1, pos2 = I - unit, I + unit
        if maze[pos1] == '.' && maze[pos2] == '.'
            if distances[pos1] > distances[pos2]
                pos1, pos2 = pos2, pos1
            end
            saving = distances[pos2] - distances[pos1] - 2
            push!(savings, saving)
        end
    end
end

# Find shortcuts for Part 1
function find_shortcuts_part1!(savings, maze, distances)
    empty!(savings)
    H, W = size(maze)
    
    for I in CartesianIndices(maze)
        maze[I] != '#' && continue
        !check_bounds(I, 2, H-1, 2, W-1) && continue
        find_shortcut_pattern!(savings, maze, distances, I)
    end
end

@inline function find_shortcut_manhattan!(savings, distances, I, L, H, W)
    # Examine cells no further than L in Manhattan distance
    for i in -L:L, j in -(L-abs(i)):(L-abs(i))
        new = I + CartesianIndex(i, j)
        (!check_bounds(new, 2, H-1, 2, W-1) || distances[new] == -1) && continue

        saving = distances[new] - distances[I] - (abs(i) + abs(j))
        saving > 0 && push!(savings, saving)
    end
end

# Find shortcuts for Part 2
function find_shortcuts_part2!(savings, maze, distances, L)
    empty!(savings)
    H, W = size(maze)
    for I in CartesianIndices(maze)
        distances[I] == -1 && continue
        find_shortcut_manhattan!(savings, distances, I, L, H, W)
    end
end

function solve_part(distances, savings, maze, args...; cutoff=0)
    if length(args) == 0    # Part 1
        find_shortcuts_part1!(savings, maze, distances)
    else                    # Part 2
        find_shortcuts_part2!(savings, maze, distances, args[1])
    end
    count(≥(cutoff), savings)
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    maze = permutedims(reduce(hcat, collect.(readlines(filename))))
    S, E = findfirst(==('S'), maze), findfirst(==('E'), maze)
    maze[S], maze[E] = '.', '.'

    # --- RUN
    distances = Matrix{Int}(undef, size(maze))
    label_track!(distances, maze, S, E)
    savings = Int[]

    println("Answer part 1: ", solve_part(distances, savings, maze, cutoff=100))
    println("Answer part 2: ", solve_part(distances, savings, maze, 20, cutoff=100))

    # --- BENCHMARKING
    println("Benchmarking label_track!: ")
    @btime label_track!($distances, $maze, $S, $E)
    println("Benchmarking part 1: ")
    @btime solve_part($distances, $savings, $maze, cutoff=100)
    println("Benchmarking part 2: ")
    @btime solve_part($distances, $savings, $maze, 20, cutoff=100)
end

main()