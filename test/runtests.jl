using Test
using RateLimiter

""" Execute a function multiple times with a limiter and return the number of seconds required to complete. """
function time_exec(limiter, cost, n)

    f() = 3

    return @elapsed for _ in 1:n
        v = @rate_limit limiter cost f()
        @assert v == 3
    end
end


#######################################################################        


dt = time_exec(NoLimitRateLimiter(), 1, 1000)
println("NoLimit: dt(1)=$dt")
@assert dt < 0.001

dt = time_exec(NoLimitRateLimiter(), 2, 1000)
println("NoLimit: dt(2)=$dt")
@assert dt < 0.001


#######################################################################        


tokens_per_second = 100
max_tokens = 100
initial_tokens = 0
sleep_seconds = 1e-3

dt = time_exec(TokenBucketRateLimiter(tokens_per_second, max_tokens, initial_tokens, sleep_seconds), 1, 1000)
println("TokenBucket: dt(1)=$dt")
@assert dt > 9.5

dt = time_exec(TokenBucketRateLimiter(tokens_per_second, max_tokens, initial_tokens, sleep_seconds), 2, 1000)
println("TokenBucket: dt(2)=$dt")
@assert dt > 19.5