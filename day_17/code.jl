using Match
using DataStructures: BinaryMinHeap
using BenchmarkTools

function parse_input(filename)
    txt = read(filename, String)

    reg = Dict{Char,Int}()
    for m in eachmatch(r"Register ([ABC]): (\d+)", txt)
        reg[m.captures[1][1]] = parse(Int, m.captures[2])
    end

    prog = Int8[]
    for m in eachmatch(r"(\d+)", match(r"Program: ([\d,]+)", txt).match)
        push!(prog, parse(Int8, m.match))
    end

    reg, prog
end

# --- PART 1

function combo(reg::Dict{Char, Int}, op::Int8)
    op ≤ 3  && return op
    op == 4 && return reg['A']
    op == 5 && return reg['B']
    op == 6 && return reg['C']
    error("Program not valid")
end

@inline dv(reg, op) = reg['A'] ÷ 2^combo(reg, op)
@inline combmod8(reg, op) = combo(reg, op) % 8

adv!(reg, op, ptr) = (reg['A'] = dv(reg, op)                ; return ptr + 2)
bdv!(reg, op, ptr) = (reg['B'] = dv(reg, op)                ; return ptr + 2)
cdv!(reg, op, ptr) = (reg['C'] = dv(reg, op)                ; return ptr + 2)
bxl!(reg, op, ptr) = (reg['B'] = reg['B'] ⊻ op              ; return ptr + 2)
bxc!(reg, op, ptr) = (reg['B'] = reg['B'] ⊻ reg['C']        ; return ptr + 2)
bst!(reg, op, ptr) = (reg['B'] = combmod8(reg, op)          ; return ptr + 2)
jnz!(reg, op, ptr) = (reg['A'] == 0 && return ptr + 2       ; return op + 1)  # 1-based indexing
out!(out, reg, op, ptr) = (push!(out, combmod8(reg, op))    ; return ptr + 2)

function run_program!(output, program, reg)
    empty!(output)
    ptr = 1
    while ptr ≤ lastindex(program)
        opcode = program[ptr]
        operand = program[ptr + 1]
        ptr = @match opcode begin
            0 => adv!(reg, operand, ptr)
            1 => bxl!(reg, operand, ptr)
            2 => bst!(reg, operand, ptr)
            3 => jnz!(reg, operand, ptr)
            4 => bxc!(reg, operand, ptr)
            5 => out!(output, reg, operand, ptr)
            6 => bdv!(reg, operand, ptr)
            7 => cdv!(reg, operand, ptr)
        end
    end
end


# --- PART 2
"""
Find the smallest initial value of register A such that the 3-bit computer
emits the exact instruction stream (`program`) as its output.

The algorithm exploits the radix-8 structure hidden in the puzzle:

- output byte 16 (last) changes whenever the least-significant 3 bits of A change  
- output byte 15 changes whenever the next 3 bits change  
- ...  
- output byte 1 (first) changes only when the most-significant 3 bits change  

We can then solve right-to-left, 3 bits at a time, and prune > 99 % of the
search space.

We use a min-heap that always yields the smallest candidate A still under
investigation. The heap entries are `(current_A, idx)` where 
  `current_A` – candidate value for register A  
  `idx`       – index of the next output byte we still have to match
                (1-based, counted from the left)

Inner loop
For each candidate we:
1. run the program once
2. compare the suffix `output[idx+1:end]` with `program[idx+1:end]`
3. on match:
   - if `idx == 1`  → entire stream matched → return (smallest A found)
   - else           → push `(candidate, idx-1)` to fix the next 3-bit slice
"""
function find_A_value!(output, program, reg, heap)
    n = length(program)
    empty!(heap)
    push!(heap, (8^(n-1), n))                   # start at highest radix: fix byte n first

    while !isempty(heap)
        A, idx = pop!(heap)                     # smallest A that already matches [idx:end]
        step   = 8^(idx-1)                      # 3-bit step size for this byte position
        stop   = A + 8^idx + step               # upper bound (inclusive)

        for candidate in A:step:stop
            empty!(output)                      
            reg['A'] = candidate
            reg['B'] = 0
            reg['C'] = 0
            run_program!(output, program, reg)

            # compare suffix: only the bytes we care about
            if (@view output[idx:end]) == (@view program[idx:end])
                idx == 1 && return candidate    # full match → smallest A found
                push!(heap, (candidate, idx-1)) # fix next byte (smaller radix)
            end
        end
    end
    error("no solution")
end

# --- MAIN
function main()
    reg, program = parse_input(joinpath(@__DIR__, "input.txt"))
    @show reg program

    output = Int[]

    # --- RUN
    println("Answer part 1 :")
    run_program!(output, program, reg)
    @show output

    println("Answer part 2 :")
    heap   = BinaryMinHeap{Tuple{Int,Int}}()
    k = find_A_value!(output, program, reg, heap)
    @show k

    # --- BENCHMARKING
    println("Benchmarking part 1: ")
    @btime run_program!($output, $program, $reg)
    println("Benchmarking part 2: ")
    @btime find_A_value!($output, $program, $reg, $heap)
end

main()