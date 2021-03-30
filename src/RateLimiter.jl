module RateLimiter

using Dates

export AbstractRateLimiter, wait!, @rate_limit, NoLimitRateLimiter, TokenBucketRateLimiter

#TODO: should the Manifest be committed?
#TODO: add exports
#TODO: document
#TODO: unit test

abstract type AbstractRateLimiter end

wait!(limiter::AbstractRateLimiter, cost::Float64) = error("Function is not defined for AbstractRateLimiter: type=$(typeof(limiter)) function=wait!")

# #TODO: replace with an @rate_limit macro?
# function execute(limiter::AbstractRateLimiter, cost::Float64, f::Function)
#     wait!(limiter, cost)
#     return f()
# end

macro rate_limit(limiter, cost, expr)
    return esc(quote
        wait!($limiter, $cost)
        $expr
    end)
end


#######################################################################        


struct NoLimitRateLimiter <: AbstractRateLimiter end

wait!(limiter::NoLimitRateLimiter, cost::Float64) = return


#######################################################################        


mutable struct TokenBucketRateLimiter <: AbstractRateLimiter
    tokens_per_second::Float64
    max_tokens::Float64
    sleep_seconds::Float64
    lock::ReentrantLock

    last_update::DateTime
    tokens::Float64

    #TODO: argument ordering
    function TokenBucketRateLimiter(tokens_per_second, max_tokens, initial_tokens, sleep_seconds) 
        tokens_per_second <= 0 && error("tokens_per_second must be positive: tokens_per_second=$tokens_per_second")
        max_tokens <= 0 && error("max_tokens must be positive: max_tokens=$max_tokens")
        sleep_seconds < 0 && error("sleep_seconds must be at least zero: sleep_seconds=$sleep_seconds")
        return new(tokens_per_second, max_tokens, sleep_seconds, ReentrantLock(), now(), initial_tokens)
    end
end


function wait!(limiter::TokenBucketRateLimiter, cost::Float64)
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
