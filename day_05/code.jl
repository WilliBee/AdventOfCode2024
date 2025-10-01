using IterTools
using DataStructures
using StaticArrays
using BenchmarkTools

function read_data(filename)
    rules = Set{NTuple{2, Int}}()
    updates = Vector{Int}[]

    open(filename) do io
        for line in eachline(io)
            isempty(strip(line)) && break
            a, b = split(line, '|')
            push!(rules, (parse(Int, a), parse(Int, b)))
        end
        
        for line in eachline(io)
            push!(updates, [parse(Int, x) for x in split(line, ',')])
        end
    end
    rules, updates
end

# --- PART 1
function filter_add_page_number(rules, updates)
    s = 0

    for update in updates
        ok = true
        for i in firstindex(update):(lastindex(update)-1)
            (update[i], update[i+1]) ∉ rules && (ok = false; break)
        end
        ok && (s += update[(end+1)÷2])
    end
    return s
end

# --- PART 2

const USE_MVECTOR = false
#include("naive_reorder.jl")
#include("svector_reorder.jl")
include("topological_sort_reorder.jl")
#(const USE_MVECTOR = true) && include("mvector_reorder.jl")

function filter_reorder(rules, updates)
    s = 0
    
    if USE_MVECTOR
    	size_buffer = maximum(length.(updates))
        eltype_buffer = eltype(first(updates))
        BUILT_BUFF    = MVector{size_buffer, eltype_buffer}(undef)
        REMAIN_BUFF   = MVector{size_buffer, eltype_buffer}(undef)
    end

    for update in updates
        ok = true
        for i in firstindex(update):(lastindex(update)-1)
            (update[i], update[i+1]) ∉ rules && (ok = false; break)
        end
        if !(ok)
            if USE_MVECTOR
                corrected_update = reorder(BUILT_BUFF, REMAIN_BUFF, update, rules)
            else
                corrected_update = reorder(update, rules)
            end
            s += corrected_update[(end+1)÷2] 
        end
    end
    return s
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    rules, updates = read_data(filename)

    # --- RUN
    answer_1 = filter_add_page_number(rules, updates)
    println("Answer part 1 : $answer_1")
    answer_2 = filter_reorder(rules, updates)
    println("Answer part 2 : $answer_2")

    # BENCHMARKING
    println("Benchmarking part 1 : ")
    @btime filter_add_page_number($rules, $updates)
    println("Benchmarking part 2 : ")
    @btime filter_reorder($rules, $updates)
end

main()