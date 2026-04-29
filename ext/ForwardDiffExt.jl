module ForwardDiffExt

using PrecisionCarriers
using ForwardDiff

using PrecisionCarriers: P, PrecisionCarrier
using ForwardDiff: Dual, Partials

# need to overload all binary arithmetic functions and comparators

macro _binary_dual_function(operator)
    return Meta.parse("
    begin
        function Base.:$(operator)(p1::Dual{T, <:P}, p2::P; kw...) where T
            (p1_x, p1_b) = _duals(p1)
            res = _dual_prec($(operator)(p1_x, p2.x; kw...), $(operator)(p1_b, p2.big; kw...))
            return res
        end
        function Base.:$(operator)(p1::P, p2::Dual{T, <:P}; kw...) where T
            (p2_x, p2_b) = _duals(p2)
            res = _dual_prec($(operator)(p1.x, p2_x; kw...), $(operator)(p1.big, p2_b; kw...))
            return res
        end
        function Base.:$(operator)(p1::Dual{T}, p2::P; kw...) where T
            res = _dual_prec($(operator)(p1, p2.x; kw...), $(operator)(p1, p2.big; kw...))
            return res
        end
        function Base.:$(operator)(p1::P, p2::Dual{T}; kw...) where T
            res = _dual_prec($(operator)(p1.x, p2; kw...), $(operator)(p1.big, p2; kw...))
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

# get 2 dual numbers (Real and Big) from precision carrier
function _duals(d::Dual{T}) where {T}
    dual = d.value
    partials = d.partials
    return (
        Dual{T}(dual.x, getfield.(partials.values, :x)),
        Dual{T}(dual.big, getfield.(partials.values, :big)),
    )
end

# get one dual number of P from x dual and big dual number
function _dual_prec(x::Dual{T, VR}, big::Dual{T, VB}) where {T, VR, VB}
    return Dual{T}(
        P(x.value, big.value),
        Partials(P.(x.partials.values, big.partials.values))
    )
end

function _dual_prec(x::Dual{T, VR, 0}, big::Dual{T, VB, 0}) where {T, VR, VB}
    return Dual{T, P{VR}, 0}(
        P(x.value, big.value),
        Partials{0, P{VR}}(())
    )
end

# overload constructor
function PrecisionCarriers.P(v1::Dual{Nothing}, v2::Dual{Nothing})
    return Dual(
        PrecisionCarrier(v1.value, v2.value),
        Partials{0, PrecisionCarrier{typeof(v1.value)}}(())
    )
end

function PrecisionCarriers.P(v1::Dual{}, v2::Dual{})
    return Dual(
        PrecisionCarrier(v1.value, v2.value),
        Partials(PrecisionCarrier.(v1.partials.values, v2.partials.values))
    )
end

end
