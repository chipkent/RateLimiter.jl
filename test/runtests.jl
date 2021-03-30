using Test
using RateLimiter

println(names(RateLimiter))
println("####")
println(names(RateLimiter; all=true))
println("####")

function time_exec(limiter, cost, n)

    f() = println("Running")

    # return @elapsed for _ in 1:n
    #     #TODO: assert return value
    #     @rate_limit limiter cost f()
    # end

    for _ in 1:n
        #TODO: assert return value
        @rate_limit limiter cost f()
    end

end

@assert time_exec(NoLimitRateLimiter(), 1, 1000) < 0.001