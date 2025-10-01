using DataStructures
using BenchmarkTools

# --- PART 1
function checksum(data, buff_left, buff_right)
    # In this code, use buffers to calculate the checksum of data in the form
    #   2333133121414131402
    # This data should be rearranged first in the form
    #   A = 00...111...2...333.44.5555.6666.777.888899
    # Then empty spaces ('.') are filled with the digits from the right
    #   B = 0099811188827773336446555566..............
    # Then the checksum is calculated using the above rearranged digits and their
    # new position
    # checksum = 0 * 0 + 1 * 0 + 2 * 9 + 3 * 9 + 4 * 8 + ...
    #
    # Here we do not explicitely reconstitute the rearranged data. Instead we
    # use buffers to store the digits to be used in the final checksum.

    empty!(buff_left)
    empty!(buff_right)
    
    # Left and right cursors on original data
    il, offset = 1, length(data)
    
    # Cursor on rearranged data
    k = 0

    output = 0
    total_files_space = sum(el for (i, el) in enumerate(data) if isodd(i))

    while k < total_files_space

        if isempty(buff_left)
            if isodd(il)
                # dense block; fill buff_left with id on the left
                for _ in 1:data[il]
                    id = il ÷ 2
                    push!(buff_left, id)
                end
            else 
                # empty block; fill it with data from buffer_right
                for _ in 1:data[il]
                    if isempty(buff_right)
                        # fill buff_right with id on the right
                        for _ in 1:data[offset]
                            id = offset ÷ 2
                            push!(buff_right, id)
                        end
                        # next time, jump directly to next non-empty block on the right
                        offset -= 2
                    end
                    # fill buff_left with buff_right
                    push!(buff_left, popfirst!(buff_right))
                end
            end
            il += 1
        end
        
        if data[il] > 0 # if not a 0-block 
            x = popfirst!(buff_left)
            output += k * x
            k += 1
        else
            il += 1
        end
    end
    output
end

# --- PART 2

# Helper functions for testing using SortedSet and CircularBuffer
# From tests, using CircularBuffer is 3x faster (0 allocations in loop)
_push!(ss::SortedSet, el) = push!(ss, el)
_push!(ss::SortedSet, el, ::CircularBuffer) = push!(ss, el)

function _push!(cb::CircularBuffer, el)
    isfull(cb) && error("Buffer is full, increase size")
    push!(cb, el)
end

# push element in sorted CircularBuffer c using buffer b 
function _push!(c::CircularBuffer, el, b::CircularBuffer)
    while true
        isempty(c) && break
        k = first(c)
        if k < el
            push!(b, popfirst!(c))
        else
            break
        end
    end
    
    pushfirst!(c, el)
    
    while !(isempty(b))
        isfull(c) && error("Buffer is full, increase size") 
        pushfirst!(c, pop!(b))
    end
end

function checksum2(data, spaces, insert_buffer)
    # Empty data strcutures, init buffer
    foreach(empty!, spaces)
    empty!(insert_buffer)

    # Track position of empty spaces in uncompacted representation 
    offset = 0
    @inbounds for i in eachindex(data)
        if iseven(i)
            el = data[i]
            el == 0 && continue
            _push!(spaces[el], offset)
        end
        offset += data[i]
    end

    output = 0
    
    # Scan data from the end using index in compact representation
    @inbounds for i in lastindex(data):-1:1
        id = i ÷ 2      # Chunk ID
        len = data[i]   # Chunck length
        offset -= len   # Current index in uncompacted representation
        
        # Skip empty space entries
        iseven(i) && continue

        # Find smallest position of empty space fitting current chunk
        best_size = 0
        best_pos = offset
        for size in len:9
            if !(isempty(spaces[size]))
                pos = first(spaces[size])
                if  pos < best_pos
                    best_pos = pos
                    best_size = size
                end
            end
        end
        
        if best_size > 0
            popfirst!(spaces[best_size])
            
            # Found space larger than needed, keep track of leftover
            if best_size > len
                leftover = best_size - len
                _push!(spaces[leftover],  best_pos + len, insert_buffer)
            end
        else
            # if no space found
            best_pos = offset
        end
        
        # Add id * (best_pos + (best_pos + 1) + ... + (best_pos + len - 1))
        # and simplify using arithmetic-series sum
        output += id * (len * best_pos + len * (len - 1) ÷ 2)
    end
    output
end

# --- BENCHMARKING HELPERS
function part1(filename)
    data = parse.(Int, collect(readchomp(filename)))
    buff_left = CircularBuffer{Int}(10)
    buff_right = CircularBuffer{Int}(10)     
    checksum(data, buff_left, buff_right)
end

function part2_ss(filename)
    data = parse.(Int, collect(readchomp(filename)))
    spaces_set = [SortedSet{eltype(data)}() for _ in 0:9]
    null_buff = CircularBuffer{eltype(data)}(1)
    checksum2(data, spaces_set, null_buff)
end

function part2_cb(filename)
    data = parse.(Int, collect(readchomp(filename))) 
    n = length(data) ÷ 18
    spaces_buff = [CircularBuffer{eltype(data)}(n) for _ in 1:9]
    insert_buff = CircularBuffer{eltype(data)}(n)
    checksum2(data, spaces_buff, insert_buff)
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    data = parse.(Int, collect(readchomp(filename)))

    # --- RUN 
    println("Answer part 1 :")
    buff_left = CircularBuffer{Int}(10)
    buff_right = CircularBuffer{Int}(10)     
    @show checksum(data, buff_left, buff_right)

    println("Answer part 2 (SortedSet) : ")
    spaces_set = [SortedSet{eltype(data)}() for _ in 0:9]
    null_buff = CircularBuffer{eltype(data)}(1)
    @show checksum2(data, spaces_set, null_buff)

    println("Answer part 2 (CircularBuffer) : ")
    # This parameter does not seem to matter at all
    # n = length(data) ÷ 2 should be more than enough
    n = length(data) ÷ 18
    spaces_buff = [CircularBuffer{eltype(data)}(n) for _ in 1:9]
    insert_buff = CircularBuffer{eltype(data)}(n)
    @show checksum2(data, spaces_buff, insert_buff)
    
    # --- BENCHMARKING
    println("Benchmarking core loop part 1 : ")
    @btime checksum($data, $buff_left, $buff_right) 
    println("Benchmarking core loop part 2 (SortedSet) : ")
    @btime checksum2($data, $spaces_set, $null_buff)
    println("Benchmarking core loop part 2 (CircularBuffer) : ")
    @btime checksum2($data, $spaces_buff, $insert_buff)
    println("Benchmarking whole loop part 1 : ")
    @btime part1($filename) 
    println("Benchmarking whole loop part 2 (SortedSet) : ")
    @btime part2_ss($filename)
    println("Benchmarking whole loop part 2 (CircularBuffer) : ")
    @btime part2_cb($filename)
end

main()