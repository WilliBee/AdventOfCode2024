function reorder(update, rules)
    built = SVector{0, eltype(update)}()
    remaining = SVector(update...)
    result, _ = add_node(built, remaining, rules)
    return result
end


function add_node(built, remaining, rules)

    for i in eachindex(remaining)
        candidate = remaining[i]
        
        if isempty(built) || (built[end], candidate) ∈ rules
            # place candidate
            built = push(built, candidate)
            remaining = deleteat(remaining, i)
            
            built, remaining = add_node(built, remaining, rules)
            
            # correct reordering found, early finish
            isempty(remaining) && break

            # undo placement (back-track)
            remaining = insert(remaining, i, built[end])
            built = pop(built)
        end
    end
    
    return built, remaining
end
