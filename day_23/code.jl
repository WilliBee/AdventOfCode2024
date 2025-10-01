using Graphs
using StaticArrays
using BenchmarkTools

function build_graph(pairs)
    g = Graph(length(pairs))
    nodes = reduce(vcat, pairs) |> unique
    for (n, m) in pairs
        add_edge!(g, findfirst(==(n), nodes), findfirst(==(m), nodes))
    end
    g, nodes
end

# --- PART 1
function get_triangles!(clubs, nbrs, g, nodes)
    empty!(clubs)
    for v in vertices(g)
        # Get neighbors with index > v to avoid duplicates
        empty!(nbrs)
        for u in neighbors(g, v) 
            u > v && push!(nbrs, u)
        end

        m = length(nbrs)
        for i in 1:m, j in (i+1):m
            u = nbrs[i]
            w = nbrs[j]
            nodes[v][1] == 't' || nodes[u][1] == 't' ||  nodes[w][1] == 't' || continue
            has_edge(g, u, w) && push!(clubs, SVector(v, u, w))
        end
    end
    clubs
end

# --- PART 2
function get_maximal_clique(g, nodes)
    mc = maximal_cliques(g)
    nodes[mc[argmax(length.(mc))]]
end

# --- MAIN
function main()
    filename = joinpath(@__DIR__, "input.txt")
    pairs = [String.(split(line, '-')) for line in readlines(filename)]

    # --- RUN
    g, nodes = build_graph(pairs)

    clubs = Vector{SVector{3, eltype(g)}}()
    nbrs = Vector{eltype(g)}()
    get_triangles!(clubs, nbrs, g, nodes)

    println("Answer part 1: ")
    @show clubs |> length

    println("Answer part 2: ")
    @show join(sort(get_maximal_clique(g, nodes)), ',')

    # --- BENCHMARKING
    println("Benchmarking graph creation: ")
    @btime build_graph($pairs)

    println("Benchmarking Part 1: ")
    @btime get_triangles!($clubs, $nbrs, $g, $nodes)

    println("Benchmarking Part 2: ")
    @btime get_maximal_clique($g, $nodes)
end

main()