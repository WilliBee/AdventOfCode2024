using BenchmarkTools
using StaticArrays

function parse_problem(filename)
    lines = read(filename, String)
    locks = SVector{5, Int}[]
    keys  = SVector{5, Int}[]

    for blk in split(lines, "\n\n")
        rows = split(blk, "\n")
        islock   = all(collect(first(rows)) .== '#')
        heights  = @SVector zeros(Int, length(first(rows)))

        @inbounds for l in (islock ? rows[2:end] : rows[1:end-1])
            heights += collect(l) .== '#'
        end
       push!(islock ? locks : keys, heights)
    end
    locks, keys
end

# --- PART 1
compatible_pairs(locks, keys) = sum(all(l .+ k .< 6) for l in locks, k in keys)

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    locks, keys = parse_problem(filename)

    # --- RUN
    println("Answer part 1 :")
    @show compatible_pairs(locks, keys)

    # --- BENCHMARKING
    println("Benchmarking part 1: ")
    @btime compatible_pairs($locks, $keys)
end

main()