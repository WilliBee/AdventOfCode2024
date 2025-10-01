using DelimitedFiles
using BenchmarkTools

const INDEXTYPE = CartesianIndex{2}
const DIRS = (
    INDEXTYPE(0, 1),
    INDEXTYPE(0, -1),
    INDEXTYPE(1, 0),
    INDEXTYPE(-1, 0)
)

@inline check_bounds(pos, R, C) = (1 ≤ pos[1] ≤ R) && (1 ≤ pos[2] ≤ C)

# --- PART 1 
@inline fuse!(a::Set, b::Set) = union!(a, b)

function search!(path_tracker::Matrix{T}, world, pos) where {T}
    # Search and return all 9s connected to current node at `pos`
    R, C = size(world)
    val = world[pos]

    # Terminal condition; return singleton
    (val == 9) && return push!(T(), pos)

    # Early stopping
    !isempty(path_tracker[pos]) && return path_tracker[pos]
    
    # Continue search
    for dir in DIRS
        if check_bounds(pos+dir, R, C) && world[pos + dir] == val + 1
            fuse!(path_tracker[pos], search!(path_tracker, world, pos + dir))
        end
    end
    return path_tracker[pos] 
end

function init_tracker(size, ::Type{T}) where {T}
    # Initialize a Set/Vector of indices at each location to keep track 
    # of all 9s reachable from that location.
    # This allows for short-circuiting the recursive search when
    # reaching a non empty Set/Vector.
    path_tracker = Matrix{T}(undef, size...)
    for i in eachindex(path_tracker)
        path_tracker[i] = T()
    end
    path_tracker
end

function sum_scores(world, path_tracker)
    # Look for trailheads in `world`, search and count all 9s connected to it.
    sum(
        search!(path_tracker, world, trailhead) |> length
        for trailhead in findall(==(0), world)
    )
end

part1(world) = let
    path_tracker = init_tracker(size(world), Set{INDEXTYPE})
    sum_scores(world, path_tracker)
end

# --- PART 2
@inline fuse!(a::Vector, b::Vector) = append!(a, b)

part2(world) = let 
    path_tracker = init_tracker(size(world), Vector{INDEXTYPE})
    sum_scores(world, path_tracker)
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    world = hcat([parse.(Int, collect(row)) for row in readdlm(filename, String)]...)

    # --- RUN 
    println("Answer part 1 :")   
    pt = init_tracker(size(world), Set{INDEXTYPE})
    @show sum_scores(world, copy(pt))

    println("Answer part 2 :")   
    pt = init_tracker(size(world), Vector{INDEXTYPE})
    @show sum_scores(world, copy(pt))

    # --- BENCHMARKING
    println("Benchmarking core loop part 1 : ")
    @btime sum_scores($world, $pt)
    println("Benchmarking whole loop part 1 : ")
    @btime part1($world) 
    println("Benchmarking core loop part 2 : ")
    @btime sum_scores($world, $pt)
    println("Benchmarking whole loop part 2 : ")
    @btime part2($world) 
end

main()