using DataStructures
using BenchmarkTools

function parse_problem(filename)
    lines   = readlines(filename)
    colors = [codeunits(s) for s in split(lines[1], ", ")]
    patterns = lines[3:end]
    colors, patterns
end

# --- PART 1
function count_ways!(ways, colors, pat)
    T = codeunits(pat)
    n = length(T)
    
    # Initialize DP array: contains number of ways to reach position i
    fill!(ways, 0)
    ways[1] = 1
    
    # Process each position
    @inbounds for i in 1:n
        ways[i] == 0 && continue
        for color in colors
            L = length(color)
            j = i + L - 1           # End index in pat
            j > n && continue       # Skip if color extends beyond pattern
            view(T, i:j) == color || continue
            ways[j + 1] += ways[i]
        end
    end
    ways[n+1]
end

function count_all(ways, colors, patterns)
    feasible = 0
    total = 0
    for pat in patterns
        comb = count_ways!(ways, colors, pat)
        feasible += (comb != 0)
        total += comb
    end
    feasible, total
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    colors, patterns = parse_problem(filename)

    # --- RUN
    max_len = maximum(length.(patterns))
    ways = Vector{Int}(undef, max_len + 1)

    println("PART 1 & 2")
    @show count_all(ways, colors, patterns)

    # --- BENCHMARKING
    @btime count_all($ways, $colors, $patterns)
end

main()