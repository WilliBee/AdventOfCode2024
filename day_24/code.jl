using BenchmarkTools

const GATE_PATTERN = r"^(\w+)\s+(XOR|OR|AND)\s+(\w+)\s+->\s+(\w+)$"

struct Gate
    inA::String
    op::String
    inB::String
    out::String
end

function parse_problem(filename)
    lines   = readlines(filename)
    blank   = findfirst(isempty, lines)
    input_lines = lines[1:blank-1]
    link_lines = lines[blank+1:end]

    inputs = Dict{String, Bool}()
    gates = Dict{String, Gate}()
    fan = Dict{String, Vector{String}}()    # who uses gate g?

    for l in input_lines
        in, bit = split(l, ": ")
        inputs[in] = parse(Bool, bit)
    end

    for l in link_lines
        g = match(GATE_PATTERN, l)
        gate = Gate(g...)
        gates[gate.out] = gate
        push!(get!(fan, gate.inA, String[]), gate.op)
        push!(get!(fan, gate.inB, String[]), gate.op)
    end

    zgates = filter(startswith('z'), keys(gates)) |> collect |> sort

    inputs, gates, zgates, fan
end

function comp(INPUTS, GATES, output_name)
    if haskey(INPUTS, output_name)
        return INPUTS[output_name]
    else
        gate = GATES[output_name]
        inA = gate.inA
        inB = gate.inB
        op = gate.op
        if op == "XOR"
            return comp(INPUTS, GATES, inA) ⊻ comp(INPUTS, GATES, inB)
        elseif op == "AND"
            return comp(INPUTS, GATES, inA) && comp(INPUTS, GATES, inB)
        elseif op == "OR"
            return comp(INPUTS, GATES, inA) || comp(INPUTS, GATES, inB)
        else
            error("unknown operation")
        end
    end
end

# --- PART 1
function output!(buff, zgates, INPUTS, GATES, )
    @inbounds for i in eachindex(zgates)
        buff[i] = comp(INPUTS, GATES, zgates[i])
    end
    evalpoly(2, buff)
end

# --- PART 2
# Adapted solutions from :
# - https://github.com/alan-turing-institute/advent-of-code-2024/blob/main/day-24/python_radka-j/day24.py
# - https://www.bytesizego.com/blog/aoc-day24-golang
#
# A typical Ripple-carry adder performs this set of operation:
#   1. z₀ = x₀ XOR y₀
#   2. zᵢ = (xᵢ XOR yᵢ) XOR cᵢ
#   3. cᵢ₊₁ = (xᵢ AND yᵢ) OR (cᵢ AND (xᵢ XOR yᵢ))

# Then for a zᵢ₊₁ (i+1≥1, i+1≤44) :
# zᵢ₊₁ = dfg XOR rty
#       dfg = xᵢ  XOR yᵢ
#       rty = iop OR hjk
#           iop = xᵢ  AND yᵢ
#           hjk = ert AND cvb
#               ert = ...
#               cvb = xᵢ  XOR yᵢ
#
# Any gate that violates the expected operand / operation pairing is flagged.
# This set of rules allows for a one-pass scan of all gates.

function find_wrong_gates!(candidates, gates, fan)
    for (g, gate) in gates
        a, b, op = gate.inA, gate.inB, gate.op

        # hard-wired exceptions (first and last bit of the adder)
        g == "z00" && op == "XOR" && continue   # z00 is allowed to be XOR
        g == "z45" && op == "OR"  && continue   # z45 is allowed to be OR

        # Every intermediate sum bit zᵢ (i≥1, i≤44) must be an XOR
        g[1] == "z" && op != "XOR" && 
            push!(candidates, g)

        # A XOR gate must have x/y inputs or feed a z output.
        # Otherwise it is an intermediate XOR that should not exist.
        op == "XOR" &&
            (a[1], b[1]) ∉ (('x', 'y'), ('y', 'x')) && 
            g[1] ≠ 'z' &&
            push!(candidates, g)

        # Every AND gate (except the first half-adder) must feed into an OR
        # (because AND produces the partial carry that must be OR-ed with the ripple carry)
        op == "AND" &&
            (a, b) ∉ (("x00", "y00"), ("y00", "x00")) && 
            "OR" ∉ get(fan, g, String[]) &&
            push!(candidates, g)

        # A XOR result must never feed an OR gate, only XOR and AND
        # (OR inputs are only AND outputs or other OR outputs)
        op == "XOR" &&
            "OR" ∈ get(fan, g, String[]) &&
            push!(candidates, g)
    end
end

function sorted_string_wrong_gates(gates, fan)
    candidates = Set{String}()
    find_wrong_gates!(candidates, gates, fan)
    join(sort!(collect(candidates)), ',')
end

# --- MAIN
function main()
    # --- RUN
    filename = joinpath(@__DIR__, "input.txt")
    INPUTS, GATES, ZGATES, FAN = parse_problem(filename)
    buff = falses(size(ZGATES))

    println("Answer part 1 :")
    @show output!(buff, ZGATES, INPUTS, GATES)

    println("Answer part 2 :")
    @show sorted_string_wrong_gates(GATES, FAN)

    # --- BENCHMARKING
    println("Benchmarking part 1 (core computation): ")
    @btime comp($INPUTS, $GATES, "z00")
    println("Benchmarking part 1 (whole solution): ")
    @btime output!($buff, $ZGATES, $INPUTS, $GATES)
    println("Benchmarking part 2: ")
    candidates = Set{String}()
    @btime find_wrong_gates!($candidates, $GATES, $FAN)
end

main()