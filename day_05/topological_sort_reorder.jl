# ---------- Topological-sort based reorder ----------
function reorder(update, rules)
    # Build a dict value -> index for the update (needed for bit-vectors)
    idx = Dict(x => i for (i, x) in enumerate(update))

    # Sub-graph of the update: edges as indices
    n = length(update)
    adj = [Int[] for _ = 1:n]        # adjacency list
    indeg = zeros(Int, n)

    for (a, b) in rules
        (haskey(idx, a) && haskey(idx, b)) || continue
        u, v = idx[a], idx[b]
        push!(adj[u], v)
        indeg[v] += 1
    end

    # Kahn's algorithm
    q = Int[i for i = 1:n if indeg[i] == 0]
    out = similar(update)             # pre-allocated result
    k = 1
    while !isempty(q)
        u = popfirst!(q)
        out[k] = update[u]
        k += 1
        for v in adj[u]
            indeg[v] -= 1
            indeg[v] == 0 && push!(q, v)
        end
    end
    k == n + 1 || error("cycle in rules")   # shouldn’t happen for valid input
    return out
end
