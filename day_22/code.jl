using DataStructures
using BenchmarkTools

# --- PART 1
@inline function next_secret!(s)
    for i in eachindex(s)
        s[i] ⊻= s[i] << 6   
        s[i] &= 2^24-1        # prune ≡ mask 2^24-1
        s[i] ⊻= s[i] >> 5
        s[i] &= 2^24-1
        s[i] ⊻= s[i] << 11
        s[i] &= 2^24-1
    end
end

function generate_secrets!(s, n)
    # Processing the secrets in batch is SIMD friendly
    for _ in 1:n
        next_secret!(s)
    end
    sum(s)
end

# --- PART 2
@inline @inbounds function pattern_key(deltas)
    # shift -9..9 → 0..18
    ii = deltas[1] + 9
    jj = deltas[2] + 9
    kk = deltas[3] + 9
    ll = deltas[4] + 9
    # base-19 packed integer
    ll + 19 * (kk + 19 * (jj + 19 * ii))
end

function harvest_patterns!(totals, sold, numkeys, deltas, old, secrets, n)
    for step in 1:n
        old .= secrets
        next_secret!(secrets)

        @inbounds for i in eachindex(deltas)
            price = secrets[i] % 10
            prev  = old[i] % 10
            push!(deltas[i], price - prev)
        end
            
        step < 4 && continue

        # Pre-fill the pattern indices to allow for inbounds optim
        numkeys .= pattern_key.(deltas)
        @inbounds for i in eachindex(deltas) 
            sold[numkeys[i], i] && continue
            sold[numkeys[i], i] = true
            totals[numkeys[i]] += secrets[i] % 10
        end
    end
end

function init_buffers(secrets)
    T = eltype(secrets)
    N = length(secrets)
    N_patterns = 19^4
    
    # CircularBuffers containing the 4 most recent price differences
    deltas = [CircularBuffer{T}(4) for _ in 1:N]
    # Buffer to hold the old secret values
    o = similar(secrets)
    # BitMatrix indicating if monkey n sold its bananas for pattern i
    sold = falses(N_patterns, N)
    # Vector recording sum of all bananas sold for a particular pattern
    totals = zeros(T, N_patterns)
    # Buffer holding the 4-digits pattern → base-19 integer transform for each monnkey
    pattern_keys = zeros(T, N)

    totals, sold, pattern_keys, deltas, o
end

function max_bananas(secrets, n)
    totals, sold, numkeys, deltas, o = init_buffers(secrets)
    harvest_patterns!(totals, sold, numkeys, deltas, o, secrets, n)
    maximum(totals)
end

# --- BENCHMARKING HELPERS
function bench_p1!(s, secrets, n) 
    s .= secrets
    generate_secrets!(s, n)
end

function bench_p2!(totals, sold, numkeys, deltas, o, s, n, secrets) 
    s .= secrets
    harvest_patterns!(totals, sold, numkeys, deltas, o, s, n)
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    secrets = parse.(Int32, readlines(filename))        # Use Int32 for 4 × 32-bit SIMD lanes 

    # --- RUN
    println("Answer part 1: ")
    @show generate_secrets!(copy(secrets), 2000)
    println("Answer part 2: ")
    @show max_bananas(copy(secrets), 2000)

    # --- BENCHMARKING
    println("Benchmarking inner loop: ")
    s = copy(secrets)
    @btime next_secret!($s)

    println("Benchmarking part 1: ")
    s = similar(secrets)
    @btime bench_p1!($s, $secrets, 2000)

    println("Benchmarking part 2 (init buffers): ")
    @btime init_buffers($secrets)

    println("Benchmarking part 2 (hot loop): ")
    totals, sold, numkeys, deltas, o = init_buffers(secrets)
    s = similar(secrets)
    @btime bench_p2!($totals, $sold, $numkeys, $deltas, $o, $s, 2000, $secrets) 
end

main()