@doc doc"""
Wrapper function for calculating confidence intervals from a bootstrap sampling.
""" ->
function ci(x::BootstrapSample; level::FloatingPoint = 0.95, method::Symbol = :basic)

    if method == :basic
        ci_basic(x, level)
    elseif method == :perc
        ci_perc(x, level)
    elseif method == :normal
        ci_normal(x, level)
    elseif method == :bca
        ci_bca(x, level)
    else
        error("Method '$(method)' is not implemented")
    end
        
end


@doc doc"""
Calculate a basic confidence interval with confidence `level` from a bootstrap sampling.
""" ->
function ci_basic(x::BootstrapSample, level::FloatingPoint = 0.95)
    t0 = x.t0
    t1 = x.t1
    alpha = ([level, -level] + 1)/2
    lower, upper = quantile(t1, alpha)
    lower = 2 * t0 - lower
    upper = 2 * t0 - upper
    res = BootstrapCI(x.t0, lower, upper, level, :basic)
    return res
end


@doc doc"""
Calculate a percentile confidence interval with confidence `level` from a bootstrap sampling.
""" ->
function ci_perc(x::BootstrapSample, level::FloatingPoint = 0.95)
    t1 = x.t1
    alpha = ([-level, level] + 1)/2
    lower, upper = quantile(t1, alpha)
    res = BootstrapCI(x.t0, lower, upper, level, :perc)
    return res
end


@doc doc"""
Calculate a normal confidence interval with confidence `level` from a bootstrap sampling.
""" ->
function ci_normal(x::BootstrapSample, level::FloatingPoint = 0.95)
    ## what are we missing here?
    t0 = estimate(x)
    b = bias(x) ##bias = mean(t) - t0
    s = se(x)
    z = quantile(Normal(), (1+level)/2)
    merr = s * z
    lower = t0 - b - merr
    upper = t0 - b + merr
    res = BootstrapCI(t0, lower, upper, level, :normal)
    return res
end


@doc doc"""
Calculate a bias-corrected and accelerated (BCa) confidence interval with confidence `level` from a bootstrap sampling.
""" ->
function ci_bca(x::BootstrapSample, level::FloatingPoint = 0.95)
    t0 = x.t0
    t1 = x.t1
    n = length(x.t1)
    alpha = ([-level, level] + 1)/2 ## optim
    z0 = quantile(Normal(), mean(t1 .< t0))
    jkt = jack_knife_estimate(x.x, x.fun)
    resid = (n-1) .* (t0 - jkt)
    a = sum(resid.^3) / (6.*(sum(resid.^2)).^(1.5))
    qn = quantile(Normal(), alpha)
    z1 = z0 + qn
    zalpha = cdf(Normal(), z0 + (z1) ./ (1-a*(z1)))
    lower, upper = quantile(t1, zalpha) ## optim
    res = BootstrapCI(t0, lower, upper, level, :bca)
    return res
end
