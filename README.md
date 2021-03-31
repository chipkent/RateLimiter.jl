# RateLimiter.jl
Julia package for limiting the rate at which expressions are evaluated.  This can be
useful for rate limiting access to network resources (e.g. websites).  All methods are
thread safe.

This example uses the Token-Bucket algorithm to limit how quickly the functions can be called.

```julia
using RateLimiter

tokens_per_second = 2
max_tokens = 100
initial_tokens = 0

limiter = TokenBucketRateLimiter(tokens_per_second, max_tokens, initial_tokens)

function f_cheap()
    println("cheap")
    return 1
end

function f_costly()
    println("costly")
    return 2
end

result = 0

for i in 1:10
    result += @rate_limit limiter 1 f_cheap()
    result += @rate_limit limiter 10 f_costly()
end

println("RESULT: $result")
```
