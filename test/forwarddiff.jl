using LsqFit
using ForwardDiff

# don't use float16, it leads to Infs/NaNs
PREC_TYPES = [PrecisionCarrier{Float32}, PrecisionCarrier{Float64}]

# example from https://juliadiff.org/ForwardDiff.jl/stable/
f(x::Vector) = sin(x[1]) + prod(x[2:end])
g(y::Real) = [sin(y), cos(y), tan(y)]

@testset "ForwardDiff example ($P)" for P in PREC_TYPES
    x = P.(vcat(pi / 4, 2:4))
    grad = ForwardDiff.gradient(f, x)

    @test eltype(grad) == P

    hess = ForwardDiff.hessian(f, x)

    @test eltype(grad) == P

    deri = ForwardDiff.derivative(g, precify(pi / 4))

    @test eltype(grad) == P

    jac = ForwardDiff.jacobian(x) do x
        [sin(x[1]), prod(x[2:end])]
    end

    @test eltype(jac) == P
end

model(t, p) = p[1] * exp.(-p[2] * t)

@testset "LsqFit example ($P)" for P in PREC_TYPES
    tdata = P.(collect(0:0.5:20))
    ydata = P.(model(tdata, [1.0 2.0]) + 0.01 * randn(length(tdata)))
    p0 = P.([0.5, 0.5])

    fit = curve_fit(model, tdata, ydata, p0)

    @test eltype(fit.param) == P
    @test eltype(fit.jacobian) == P
    @test eltype(fit.resid) == P
    @test fit.converged
end

@testset "Raw Dual Numbers ($P)" for P in PREC_TYPES
    d = ForwardDiff.Dual(eltype(P)(1.0))
    p = P(1.0)

    @test typeof(d * p) <: ForwardDiff.Dual{Nothing, P}
    @test typeof(p / d) <: ForwardDiff.Dual{Nothing, P}
    @test typeof(d + p) <: ForwardDiff.Dual{Nothing, P}
    @test typeof(p - d) <: ForwardDiff.Dual{Nothing, P}
end
