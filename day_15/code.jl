using BenchmarkTools

# Function to display compact Matrix of Char
dispmap(map) = println(join(join.(eachrow(map)), '\n'))

const STEP = Dict(
    '^' => CartesianIndex(-1, 0),
    'v' => CartesianIndex(1, 0),
    '>' => CartesianIndex(0, 1),
    '<' => CartesianIndex(0, -1)
)
const SIDE = Dict(
    ']' => CartesianIndex(0, -1),
    '[' => CartesianIndex(0, 1)
)
const EXPANSION = Dict(
    '#' => ('#', '#'),
    'O' => ('[', ']'),
    '.' => ('.', '.'),
    '@' => ('@', '.')
)

function parse_problem(filename)
    lines   = readlines(filename)
    blank   = findfirst(isempty, lines)
    map_lines = lines[1:blank-1]
    moves_lines = lines[blank+1:end]

    H = length(map_lines)
    W = length(map_lines[1])
    map = Matrix{Char}(undef, H, W)
    mxp = Matrix{Char}(undef, H, W*2)   # Expanded map

    for (r,ln) in enumerate(map_lines), (c,ch) in enumerate(ln)
        map[r,c] = ch
        mxp[r, (2*(c-1) + 1):(2*c)] .= EXPANSION[ch]
    end

    moves = collect(Iterators.flatten(moves_lines))
    map, mxp, moves
end

# -- PART 1

struct Buffers{T}
    map::Matrix{T}
end

function move!(buffers::Buffers, robot, step)
    map = buffers.map
    next = robot + step
    map[next] == '#' && return robot    # Wall : do nothing

    while map[next] == 'O'              # Search until first non-box cell
        next += step
    end

    map[next] == '#' && return robot    # Wall behind boxes : do nothing

    map[next] = 'O'                     # Move box into free cell
    map[robot] = '.'                    # Empty robot's position
    robot += step
    map[robot] = '@'                    # Move robot
    robot
end


# --- PART 2

const MoveInstructions = NamedTuple{(:origin, :step), Tuple{CartesianIndex{2}, CartesianIndex{2}}}

struct BuffersExpanded{T}
    map::Matrix{T}
    tomove::Vector{MoveInstructions}
    visited::Vector{CartesianIndex{2}}
end

function move!(buffers::BuffersExpanded, robot, step; firstNode=false)
    map = buffers.map
    tomove = buffers.tomove
    visited = buffers.visited
    
    # Terminal conditions
    robot ∈ visited && return true
    push!(visited, robot)

    if firstNode
        empty!(tomove)
        # Recursively find adjacent boxes and move them if possible
        if move!(buffers, robot + step, step)
            push!(tomove, (robot, step))
            while !isempty(tomove)
                origin, step = popfirst!(tomove)
                map[origin + step] = map[origin]
                map[origin] = '.'
            end
            robot += step
        end
        empty!(visited)
        return robot
    end

    # Terminal conditions
    map[robot] == '#' && return false
    map[robot] == '.' && return true
    
    # Explore tiles on the sides or pair of tiles above and below the two box characters [] 
    # until terminal condition is reached. Save tiles to move if search succesful.
    if step ∈ (STEP['<'], STEP['>'])
        if move!(buffers, robot + step, step)
            push!(tomove, (robot, step))
            return true
        else 
            return false
        end
    elseif step ∈ (STEP['^'], STEP['v'])
        side = SIDE[map[robot]]                             # Position of other side of box
        push!(visited, robot + side)                        # Mark other side as explored
        if move!(buffers, robot + step, step) && move!(buffers, robot + side + step, step)
            push!(tomove, (robot, step))
            push!(tomove, (robot + side, step))
            return true
        else
            return false
        end
    end
end

# --- PART 1 & 2
@inline move_first!(b::Buffers, r, s) = move!(b, r, s)
@inline move_first!(b::BuffersExpanded, r, s) = move!(b, r, s, firstNode=true)

@inline box_char(::BuffersExpanded) = '['
@inline box_char(::Buffers) = 'O'

function simulate!(buffers, map, moves, robot=findfirst(==('@'), map))
    buffers.map .= map
    for move in moves
        robot = move_first!(buffers, robot, STEP[move])
    end
    sum(
        buffers.map[i] == box_char(buffers) ? 100 * (i.I[1] - 1) + (i.I[2] - 1) : 0
        for i in CartesianIndices(buffers.map)
    )
end

# --- MAIN
function main()
    map, map_expanded, moves = parse_problem(joinpath(@__DIR__, "input.txt"))

    # --- RUN
    println("Answer part 1 :")
    buffer = Buffers(similar(map))
    @show simulate!(buffer, map, moves)

    println("Answer part 2 :")
    buffers = BuffersExpanded(
        similar(map_expanded), 
        MoveInstructions[], 
        CartesianIndex{2}[])
    @show simulate!(buffers, map_expanded, moves)

    # --- BENCHMARKING
    println("Benchmarking part 1: ")
    robot = findfirst(==('@'), map)
    @btime simulate!($buffer, $map, $moves, $robot)

    println("Benchmarking part 2: ")
    robot = findfirst(==('@'), map_expanded)
    @btime simulate!($buffers, $map_expanded, $moves, $robot)
end

main()