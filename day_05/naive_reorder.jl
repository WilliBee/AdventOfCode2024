function reorder(update, rules)
    _, built = add_node([], update, rules, true)
    return built
end

function add_node(built, remaining, rules, cont)
  
    if isempty(remaining)
        return false, built
    end

    for i in eachindex(remaining)
        if cont && (isempty(built) || (built[end], remaining[i]) ∈ rules)
            cont, built = add_node(vcat(built,  remaining[i]), remaining[1:end .!= i], rules, cont)
        end
    end
    
    return cont, cont ? built[1:end-1] : built
end

