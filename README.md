![Test](https://github.com/chipkent/RateLimiter.jl/actions/workflows/test.yml/badge.svg)
![Register](https://github.com/chipkent/RateLimiter.jl/actions/workflows/register.yml/badge.svg)
![Document](https://github.com/chipkent/RateLimiter.jl/actions/workflows/document.yml/badge.svg)
![Compat Helper](https://github.com/chipkent/RateLimiter.jl/actions/workflows/compathelper.yml/badge.svg)
![Tagbot](https://github.com/chipkent/RateLimiter.jl/actions/workflows/tagbot.yml/badge.svg)

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

## Documentation

See [https://chipkent.github.io/RateLimiter.jl/dev/](https://chipkent.github.io/RateLimiter.jl/dev/).

Pull requests will publish documentation to <code>https://chipkent.github.io/RateLimiter.jl/previews/PR##</code>.