using StaticArrays
using BenchmarkTools

# --- PART 1
# Check if :
# - The levels are either all increasing or all decreasing.
# - Any two adjacent levels differ by at least one and at most three.

is_safe(report) = let d = diff(report)
    all(0 .< d .< 4) || all(-4 .< d .< 0)
end

# --- PART 2
# check if same conditions as Part 1 apply + tolerate a single bad level

function check_report_tol(report::SVector)
    is_safe(report) && return true
    
    d = diff(report)
    
    # Direction criterion
    direction = count(==(1), sign.(d)) > count(==(-1), sign.(d)) ? 1 : -1
    dir_check = x -> sign(x) != direction
    
    # Magnitude criterion
    magnitude_check = x -> abs(x) > 3 || abs(x) < 1

    # Tolerate a single bad level
    if count(magnitude_check, d) == 1
        idx = findfirst(magnitude_check, d)
    elseif count(dir_check, d) == 1
        idx = findfirst(dir_check, d)
    else
        return false
    end
    
    for i in SVector(idx, idx + 1)
        modified = deleteat(report, i)
        is_safe(modified) && return true
    end

    return false
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")

    data = open(joinpath(@__DIR__, filename)) do io
        [SVector(parse.(Int, split(line))...) for line in eachline(io)]
    end

    # --- RUN
    answer_1 = count(is_safe, data)
    println("Answer part 1 : $answer_1")

    answer_2 = count(check_report_tol, data)
    println("Answer part 2 : $answer_2")

    # --- BENCHMARKING
    println("Benchmarking part 1 : ")
    @btime count(is_safe, $data)
    println("Benchmarking part 2 : ")
    @btime count(check_report_tol, $data)
end

main()