function reorder(built, remain, update, rules)
    n = length(update)
    copyto!(remain, update)
    built_len  = 0
    remain_len = n

    final_len, _ = add_node!(built, remain, built_len, remain_len, rules)
    return built[1:final_len]            # cheap view, no allocation
end

function add_node!(built, remain, built_len, remain_len, rules)
    
    remain_len == 0 && return built_len, remain_len

    for i in 1:remain_len
        candidate = remain[i]

        if built_len == 0 || (built[built_len], candidate) ∈ rules
            # place candidate
            built_len += 1
            built[built_len] = candidate

            # remove it from the remain pool
            for j in i:(remain_len-1)
                remain[j] = remain[j+1]
            end
            remain_len = remain_len - 1

            built_len, remain_len = add_node!(built, remain, built_len, remain_len, rules)

            # early exit on success
            remain_len == 0 && break

            # undo placement (back-track)
            for j in (remain_len-1):-1:i
                remain[j+1] = remain[j]
            end
            remain[i] = built[built_len]
            remain_len += 1
            built_len -= 1
        end
    end
    return built_len, remain_len
end
