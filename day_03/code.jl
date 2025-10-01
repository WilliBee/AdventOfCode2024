using BenchmarkTools

# --- PART 1 

# Straightforward, short
const MUL_PATTERN = r"mul\((\d{1,3}),(\d{1,3})\)"

function regex_sum(s)
    tot = 0
    for g in eachmatch(MUL_PATTERN, s)
        tot += parse(Int, g[1]) * parse(Int, g[2])
    end
    return tot
end

# Linear search without regex to avoid allocation
function sum_lin_search(input::String)
    total = 0
    i = 1
    len = length(input)
    
    # Helper function to parse a 1-3 digit number starting at position i
    # Returns (number, new_position, success)
    @inline function parse_number(start_pos::Int)
        num = 0
        digits = 0
        pos = start_pos
        
        @inbounds while pos <= len && digits < 3 && isdigit(input[pos])
            num = num * 10 + (input[pos] - '0')
            pos += 1
            digits += 1
        end
        
        return (num, pos, digits > 0)
    end
   
    @inbounds while i <= len
        # Look for "mul(" pattern
        if i + 3 <= len && input[i] == 'm' && input[i+1] == 'u' && input[i+2] == 'l' && input[i+3] == '('
            i += 4  # Skip "mul("
            
            # Parse first number
            num1, i, success1 = parse_number(i)
            
            if success1 && i <= len && input[i] == ','
                i += 1  # Skip comma
                
                # Parse second number
                num2, i, success2 = parse_number(i)
                
                if success2 && i <= len && input[i] == ')'
                    total += num1 * num2
                    i += 1  # Skip closing parenthesis
                    continue
                end
            end
        else
            i += 1
        end
    end
    
    return total
end

# --- PART 2

# Straightforward, short but slow
const MUL_PATTERN_FLAGS = r"mul\((\d{1,3}),(\d{1,3})\)|do\(\)|don\'t\(\)"

function regex_sum_flags(s)
    tot = 0
    do_flag = true
    for g in eachmatch(MUL_PATTERN_FLAGS, s)
        if g.match == "don't()"
            do_flag = false
            continue
        elseif g.match == "do()"
            do_flag = true
            continue
        end
        if do_flag
            tot += parse(Int, g[1]) * parse(Int, g[2])
        end
    end
    return tot
end

# Linear search, faster
function sum_lin_search_flags(input::String)
    total = 0
    i = 1
    len = length(input)
    do_flag = true
    
    # Helper function to parse a 1-3 digit number starting at position i
    # Returns (number, new_position, success)
    @inline function parse_number(start_pos::Int)
        num = 0
        digits = 0
        pos = start_pos
        
        @inbounds while pos <= len && digits < 3 && isdigit(input[pos])
            num = num * 10 + (input[pos] - '0')
            pos += 1
            digits += 1
        end
        
        return (num, pos, digits > 0)
    end
    
    @inbounds while i <= len
        # Look for "don't()" pattern
        if i + 6 <= len && input[i] == 'd' && input[i+1] == 'o' && input[i+2] == 'n' && input[i+3] == '\'' &&
            input[i+4] == 't' && input[i+5] == '(' && input[i+6] == ')'
            do_flag = false
            i += 7 # Skip "don't()"
        end
        
        # Look for "do()" pattern
        if i + 3 <= len && input[i] == 'd' && input[i+1] == 'o' && input[i+2] == '(' && input[i+3] == ')'
            do_flag = true
            i += 4 # Skip "don't()"
        end
    
        # Look for "mul(" pattern
        if do_flag && i + 3 <= len && input[i] == 'm' && input[i+1] == 'u' && input[i+2] == 'l' && input[i+3] == '('
            i += 4  # Skip "mul("
            
            # Parse first number
            num1, i, success1 = parse_number(i)
            
            if success1 && i <= len && input[i] == ','
                i += 1  # Skip comma
                
                # Parse second number
                num2, i, success2 = parse_number(i)
                
                if success2 && i <= len && input[i] == ')'
                    total += num1 * num2
                    i += 1  # Skip closing parenthesis
                    continue
                end
            end
        else
            i += 1
        end
    end
    
    return total
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    s = read(filename, String)

    # --- RUN
    answer_1 = regex_sum(s)
    println("Answer part 1 (regex) : $answer_1")
    answer_1 = sum_lin_search(s)
    println("Answer part 1 (lin search) : $answer_1")
    answer_2 = regex_sum_flags(s)
    println("Answer part 2 (regex) : $answer_2")
    answer_2 = sum_lin_search_flags(s)
    println("Answer part 2 (lin search) : $answer_2")

    # --- BENCHMARKING
    println("Benchmarking part 1 (regex): ")
    @btime regex_sum($s)
    println("Benchmarking part 1 (lin search): ")
    @btime sum_lin_search($s)
    println("Benchmarking part 2 (regex) : ")
    @btime regex_sum_flags($s)
    println("Benchmarking part 2 (lin search): ")
    @btime sum_lin_search_flags($s)
end

main()