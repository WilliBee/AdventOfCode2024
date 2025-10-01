using BenchmarkTools

const DIRS = ((1,0),(-1,0),(0,1),(0,-1))            # 4-neighbours
const CORNER_PATS_DIAG = (                          # Diagonal corner masks
    (( 1, 1),), ((-1, 1),), (( 1,-1),), ((-1,-1),)
)
const CORNER_PATS_L = (                             # L-shaped corner masks
    (( 1, 0),( 0, 1)), (( 1, 0),( 0,-1)),
    ((-1, 0),( 0, 1)), ((-1, 0),( 0,-1)),
)
@inline check_bounds(pos, R, C) = (1 ≤ pos[1] ≤ R) && (1 ≤ pos[2] ≤ C)
 
function solve!(world::Matrix{Char}, visited::BitMatrix, queue::Vector{Tuple{Int,Int}})
    R, C = size(world)
    part1 = part2 = 0
    visited .= false

    @inbounds for j in 1:C, i in 1:R
        visited[i,j] && continue
        plant = world[i,j]
        area = 0 
        peri = 0
        corners = 0
        first = 1
        last = 0
        # manual push to queue
        last += 1; @inbounds queue[last] = (i,j)
        visited[i,j] = true

        while first ≤ last
            x, y = @inbounds queue[first]; first += 1
            area += 1
            # perimeter
            for (dx,dy) in DIRS
                nx, ny = x+dx, y+dy
                out = !check_bounds((nx, ny), R, C)
                if (out || world[nx,ny]≠plant)
                    peri += 1
                elseif !visited[nx,ny]
                    visited[nx,ny] = true
                    last += 1; @inbounds queue[last] = (nx,ny)
                end
            end
            # corners ≡ sides
            for pat in CORNER_PATS_DIAG
                dx, dy = pat[1]
                if check_bounds((x+dx, y+dy), R, C) && world[x+dx,y+dy]≠plant &&
                    world[x+dx,y]==plant && world[x,y+dy]==plant
                corners += 1
                end
            end
            for pat in CORNER_PATS_L
                if !(check_bounds((x+pat[1][1], y+pat[1][2]), R, C) && world[x+pat[1][1],y+pat[1][2]]==plant) &&
                    !(check_bounds((x+pat[2][1], y+pat[2][2]), R, C) && world[x+pat[2][1],y+pat[2][2]]==plant)
                corners += 1
                end
            end
        end
        part1 += area * peri
        part2 += area * corners
    end
    part1, part2
end

function solve(world)
    visited = falses(size(world))
    queue = Vector{Tuple{Int,Int}}(undef, length(world))
    solve!(world, visited, queue)
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")

    # --- RUN
    world = stack(collect.(readlines(filename)), dims=1)
    visited = falses(size(world))
    queue = Vector{Tuple{Int,Int}}(undef, length(world))
    p1, p2 = solve!(world, visited, queue)
    println("Part 1: ", p1)
    println("Part 2: ", p2)

    # --- BENCHMARKING
    println("Benchmarking core loop : ")
    @btime solve!($world, $visited, $queue)

    println("Benchmarking whole loop : ")
    @btime solve($world)
end

main()