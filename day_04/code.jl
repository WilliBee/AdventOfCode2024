using DelimitedFiles
using BenchmarkTools

# --- PART 1
function count_xmas(x)
    count = 0
    rows, cols = size(x)

    @inbounds for j in 1:cols, i in 1:rows
        if x[i, j] == 'X'
            for di in -1:1, dj in -1:1
            	# search for the remaining 'MAS' pattern in different directions
                if !(di == 0 && dj == 0)
                    count += check_pattern_mas(x, i + di, j + dj, di, dj, rows, cols)
                end
            end
        end
    end
    return count
end

@inline function check_pattern_mas(x, i, j, di, dj, rows, cols)
    i1, j1 = i + di, j + dj
    i2, j2 = i + 2*di, j + 2*dj
    @inbounds (1 <= i2 <= rows && 1 <= j2 <= cols) && (x[i, j] == 'M' && x[i1, j1] == 'A' && x[i2, j2] == 'S')
end

# --- PART 2
function count_x_mas(x)
    count = 0
    rows, cols = size(x)
    
    # Only check positions that can be the center of an X
    @inbounds for j in 2:cols-1, i in 2:rows-1
        if x[i, j] == 'A'
            # Check the four diagonal positions
            tl = x[i-1, j-1]  # top-left
            tr = x[i-1, j+1]  # top-right
            bl = x[i+1, j-1]  # bottom-left
            br = x[i+1, j+1]  # bottom-right
            
            # Check if both diagonals form valid MAS patterns
            if ((tl == 'M' && br == 'S') || (tl == 'S' && br == 'M')) &&
               ((tr == 'M' && bl == 'S') || (tr == 'S' && bl == 'M'))
                count += 1
            end
        end
    end
    return count
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")

    # read file as matrix of char
    data = hcat([collect(row) for row in readdlm(filename)]...)

    # --- RUN
    answer_1 = count_xmas(data)
    println("Answer part 1 : $answer_1")
    answer_2 = count_x_mas(data)
    println("Answer part 2 : $answer_2")

    # --- BENCHMARKING
    println("Benchmarking part 1 : ")
    @btime count_xmas($data)
    println("Benchmarking part 2 : ")
    @btime count_x_mas($data)
end

main()