using StaticArrays
using BenchmarkTools

# → Vector{ Tuple{Int, SVector{N,Int}} }  with N determined per line
function read_eqs(path)
    out = Vector{Tuple{Int,SVector}}()
    for line in eachline(path)
        t, rest = split(line, ": ")
        nums = split(rest, ' ')
        N = length(nums)
        target = parse(Int, t)
        els = ntuple(i -> parse(Int, nums[i]), N)
        push!(out, (target, SVector(els)))
    end
    out
end

# --- PART 1 

@inline function try_target(t, els, base_ops)
    N = length(els) - 1
    M = length(base_ops)
    2 <= M <= 3 || error("base_ops can only contain 2 or 3 operations")

    # Precompute operation functions (compile-time constants)
    if M == 2
        op1, op2 = base_ops
    else
        op1, op2, op3 = base_ops
    end
    for ops in Iterators.product(ntuple(_ -> 1:M, Val(N))...)
        acc = els[1]
        @inbounds for i in 1:N
            idx = ops[i]
            el = els[i+1]
            acc = idx == 1 ? op1(acc, el) : idx == 2 ? op2(acc, el) : op3(acc, el)
            acc > t && @goto next
        end
        acc == t && return t
        @label next
    end
    0
end

function sum_correct_eq(eqs, base_ops)
    s = 0
    for (t, els) in eqs
        s += try_target(t, els, base_ops)
    end
    s
end

# --- PART 2

@inline cat_ints(a, b) = a * 10^ndigits(b) + b

const OPS1 = (+, *)
const OPS2 = (+, *, cat_ints)

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    eqs = read_eqs(filename)

    # --- RUN
    println("Answer part 1 : ")
    @show sum_correct_eq(eqs, OPS1)
    println("Answer part 2 : ")
    @show sum_correct_eq(eqs, OPS2)
    
    # --- BENCHMARKING
    println("Benchmarking part 1 : ")
    @btime sum_correct_eq($eqs, $OPS1)
    println("Benchmarking part 2 : ")
    @btime sum_correct_eq($eqs, $OPS2)
end

main()