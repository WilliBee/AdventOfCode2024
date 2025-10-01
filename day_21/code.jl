using Memoize
using BenchmarkTools

const NUM_PAD = Dict(
    '7' => (1, 1), '8' => (1, 2), '9' => (1, 3), 
    '4' => (2, 1), '5' => (2, 2), '6' => (2, 3), 
    '1' => (3, 1), '2' => (3, 2), '3' => (3, 3), 
                   '0' => (4, 2), 'A' => (4, 3), 
)
const DIR_PAD = Dict(
                   '^' => (1, 2), 'A' => (1, 3), 
    '<' => (2, 1), 'v' => (2, 2), '>' => (2, 3),
)
const NUM_GAP = (4, 1)
const DIR_GAP = (1, 1)

@inline repeat_char(sign, d) = repeat(sign, max(0, d))

build_moves(pad, gap) = Dict(
    (from, to) => let dx = x2 - x1, dy = y2 - y1, seq
        seq = mapreduce(repeat_char, *, ('<', 'v', '^', '>'), (-dy, dx, -dx, dy))
        seq = gap ∈ ((x1, y2), (x2, y1)) ? reverse(seq) : seq
        seq * 'A'
    end
    for (from, (x1, y1)) in pad, (to, (x2, y2)) in pad
)
const NUM_MOVES = build_moves(NUM_PAD, NUM_GAP)
const DIR_MOVES = build_moves(DIR_PAD, DIR_GAP)

@memoize function len(seq, depth, is_numeric=false)
    depth == 0 && return length(seq)
    table = is_numeric ? NUM_MOVES : DIR_MOVES
    prev = 'A'
    total = 0
    for next in seq
        total += len(table[(prev, next)], depth - 1)
        prev = next
    end
    total
end

complexity(codes, bots) = sum(len(c, bots + 1, true) * parse(Int, chop(c)) for c in codes)

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    seqs = readlines(filename)

    # --- RUN
    println("Answer part 1: ")
    @show complexity(seqs, 2)
    println("Answer part 2: ")
    @show complexity(seqs, 25)

    # --- BENCHMARKING
    println("Benchmarking Dict creation: ")
    @btime build_moves($NUM_PAD, $NUM_GAP)
    @btime build_moves($DIR_PAD, $DIR_GAP)
    println("Benchmarking Part 1 (hot loop + core loop): ")
    s = seqs[1]
    @btime len($s, 2, true)
    @btime complexity($seqs, 2)
    println("Benchmarking Part 2 (hot loop + core loop): ")
    @btime len($s, 25, true)
    @btime complexity($seqs, 25)
end

main()