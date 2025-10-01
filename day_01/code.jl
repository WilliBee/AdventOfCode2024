using StatsBase: countmap
using DelimitedFiles: readdlm
using BenchmarkTools

# --- PART 1 
total_distance(left, right) = sum(abs.(sort(left) .- sort(right)))

# --- PART 2
function similarity_score(left, right)
    occ_left = countmap(left)
    occ_right = countmap(right)
    sum(
        el * count * get(occ_right, el, 0)
        for (el, count) in occ_left
    )
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    m = readdlm(filename, Int)

    # --- RUN
    left  = view(m, :, 1)
    right = view(m, :, 2)

    println("Answer part 1 : ", total_distance(left, right))
    println("Answer part 2 : ", similarity_score(left, right))

    # --- BENCHMARKING
    println("Benchmarking part 1 : ")
    @btime total_distance($left, $right)
    println("Benchmarking part 2 : ")
    @btime similarity_score($left, $right)
end

main()