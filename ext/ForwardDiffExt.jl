module ForwardDiffExt

using PrecisionCarriers
using ForwardDiff

using PrecisionCarriers: P
using ForwardDiff: Dual

# need to overload all binary arithmetic functions and comparators

macro _binary_dual_function(operator)
    return Meta.parse("
    begin
        function Base.:$(operator)(p1::Dual, p2::P; kw...)
            res = P($(operator)(p1, p2.x; kw...), $(operator)(p1, p2.big; kw...))
            return res
        end
        function Base.:$(operator)(p1::P, p2::Dual; kw...)
            res =  P($(operator)(p1.x, p2; kw...), $(operator)(p1.big, p2; kw...))
            return res
        end
    end
    ")
end

macro _binary_dual_comparison(operator)
    return Meta.parse("
    begin
        Base.:($(operator))(p1::Dual, p2::P; kw...) = $(operator)(p1, p2.x; kw...)
        Base.:($(operator))(p1::P, p2::Dual; kw...) = $(operator)(p1.x, p2; kw...)
    end
    ")
end

@_binary_dual_function +
@_binary_dual_function -
@_binary_dual_function *
@_binary_dual_function /
@_binary_dual_function \
@_binary_dual_function ^
@_binary_dual_function mod
@_binary_dual_function rem
@_binary_dual_function min
@_binary_dual_function max
@_binary_dual_function hypot
@_binary_dual_function log
@_binary_dual_function ldexp
@_binary_dual_function flipsign
@_binary_dual_function copysign

@_binary_dual_comparison ==
@_binary_dual_comparison !=
@_binary_dual_comparison <
@_binary_dual_comparison <=
@_binary_dual_comparison >
@_binary_dual_comparison >=
@_binary_dual_comparison isapprox

end
