
using Documenter, RateLimiter

makedocs(sitename="RateLimiter.jl", modules = [RateLimiter])

deploydocs(repo = "github.com/chipkent/RateLimiter.jl.git")
