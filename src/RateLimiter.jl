module RateLimiter

using Dates

export AbstractRateLimiter, @rate_limit, NoLimitRateLimiter, TokenBucketRateLimiter

#TODO: should the Manifest be committed?

""" Abstract base type for all rate limiters. """
abstract type AbstractRateLimiter end


"""
    !(limiter, cost::T) where {T <: Real} 

Wait until the method can be called again.  This method is thread safe.

# Arguments
- `limiter`: rate limiter
- `cost`: cost of executing the method.
"""
wait!(limiter::AbstractRateLimiter, cost::T) where {T <: Real} = error("Function is not defined for AbstractRateLimiter: type=$(typeof(limiter)) function=wait!")


"""
    @rate_limit(limiter, cost, expr)

A macro to limit the rate an expression can be called.

# Arguments
    - `limiter`: rate limiter
    - `cost`: cost of executing the method.
    - `expr`: expression to be evaluated    
"""
macro rate_limit(limiter, cost, expr)
    return esc(quote
        RateLimiter.wait!($limiter, $cost)
        $expr
    end)
end


#######################################################################        


"""
A rate limiter which does not limit the rate.
"""
struct NoLimitRateLimiter <: AbstractRateLimiter end


"""
    !(limiter, cost::T) where {T <: Real} 

Wait until the method can be called again.  This method is thread safe.

# Arguments
- `limiter`: rate limiter
- `cost`: cost of executing the method.
"""
wait!(limiter::NoLimitRateLimiter, cost::T) where {T <: Real} = return


#######################################################################        


"""
Token-Bucket rate limiter.  This limiter is used to control for constraints such as bandwidth and burstiness.

See:  https://en.wikipedia.org/wiki/Token_bucket#Algorithm
"""
mutable struct TokenBucketRateLimiter <: AbstractRateLimiter
    tokens_per_second::Float64
    max_tokens::Float64
    sleep_seconds::Float64
    lock::ReentrantLock

    last_update::DateTime
    tokens::Float64

    #TODO: argument ordering
    #TODO: remove sleep seconds
    """
    Token-Bucket rate limiter.  This limiter is used to control for constraints such as bandwidth and burstiness.
    
    See:  https://en.wikipedia.org/wiki/Token_bucket#Algorithm
 
    # Arguments
    - `tokens_per_second`: number of tokens added per second.
    - `max_tokens`: maximum number of tokens.
    - `initial_tokens`: initial number of tokens.
    - `sleep_seconds`: number of seconds to sleep before checking to see if execution is possible.
    """
    function TokenBucketRateLimiter(tokens_per_second, max_tokens, initial_tokens, sleep_seconds) 
        tokens_per_second <= 0 && error("tokens_per_second must be positive: tokens_per_second=$tokens_per_second")
        max_tokens <= 0 && error("max_tokens must be positive: max_tokens=$max_tokens")
        sleep_seconds < 0 && error("sleep_seconds must be at least zero: sleep_seconds=$sleep_seconds")
        return new(tokens_per_second, max_tokens, sleep_seconds, ReentrantLock(), now(), initial_tokens)
    end
end


"""
    !(limiter, cost::T) where {T <: Real} 

Wait until the method can be called again.  This method is thread safe.

# Arguments
- `limiter`: rate limiter
- `cost`: cost of executing the method.
"""
function wait!(limiter::TokenBucketRateLimiter, cost::T) where {T <: Real}
    # error check
    cost < 0 && error("Cost must be greater than zero: cost=$cost")
    cost > limiter.max_tokens && error("Cost must be less than the max number of tokens: cost=$cost max_tokens=$(limiter.max_tokens)")

    lock(limiter.lock) do
        while true
            # fill
            t = now()
            limiter.tokens = min(limiter.max_tokens, limiter.tokens + Dates.toms(t-limiter.last_update) / Dates.toms(Second(1)) * limiter.tokens_per_second)
            limiter.last_update = t
    
            # take
            if limiter.tokens >= cost
                limiter.tokens -= cost
                return
            end
    
            # retry
            sleep(limiter.sleep_seconds)
        end
    end
end


#######################################################################        

end # module
