import StaticArrays: SVector

function verified_prediction_lags(lags)
    ηs = sort(lags[lags .!= 0])

    if length(ηs) % 2 != 0
        throw(ArgumentError("Need an even number of lags (as many negative as positive prediction lags)"))
    end

    ηs_neg = ηs[ηs .< 0]
    ηs_pos = ηs[ηs .> 0]

    if length(ηs_neg) != length(ηs_pos) 
        throw(ArgumentError("There must be as many negative as positive prediction lags. Got $ηs_neg and $ηs_pos"))
    end

    ηs_neg_sort = sort(abs.(ηs_neg))
    ηs_pos_sort = sort(ηs_pos)
    if !(all(ηs_neg_sort .== ηs_pos_sort))
        throw(ArgumentError("Negative amd positive prediction lags must be symmetric. Got $ηs_neg and $ηs_pos"))
    end 

    return ηs
end

function verified_prediction_lags(lag::Int)
    # If only one η is provided (either positive or negative), just make a prediction 
    # for that lag.
    ηs = [-abs(lag), abs(lag)]
end

"""
    PredictiveAsymmetryTest(predictive_test::CausalityTest)

The parameters for a predictive asymmetry causality test [1]. For a 
normalised version, see [`NormalisedPredictiveAsymmetryTest`](@ref).
    
## Mandatory keywords

- **`predictive_test`**: An instance of a predictive causality test that explicitly 
    uses prediction lags (e.g. [`VisitationFrequencyTest`](@ref) or 
    [`TransferOperatorGridTest`](@ref)). 

## About the prediction lags

The prediction lags in the predictive causality test must consist of `n` negative 
integers and `n` positive integers that are symmetric around zero. 

In other words, negative lags  must exactly match the positive lags but with opposite 
sign. The zero lag can be included, but will be ignored, so it is possible to give 
ranges too.

## Examples

```julia 
bin = RectangularBinning(5) # divide each axis into 5 equal-length intervals
ηs = [-10:-1; 1:10] # exclude the zero lag (it is irrelevant for the asymmetry)

test_visitfreq = VisitationFrequencyTest(ηs = ηs)
test_transferoperator = TransferOperatorGridTest(ηs = ηs)

# Note that `predictive_test` is a *mandatory* keyword.
PredictiveAsymmetryTest(predictive_test = test_visitfreq)
PredictiveAsymmetryTest(predictive_test = test_transferoperator)
```

## References 

1. Diego, David, Kristian Agasøster Haaga, Jo Brendryen, and Bjarte Hannisdal. 
    A simple test for causal asymmetry in complex systems. In prep.
"""
Base.@kwdef mutable struct PredictiveAsymmetryTest{TEST, N} <: AbstractPredictiveAsymmetryTest where TEST
    predictive_test::TEST

    function PredictiveAsymmetryTest(test::T) where {T <: TransferEntropyCausalityTest}
        # Check that prediction lags are okay
        verified_prediction_lags(test.ηs)
        N = length(test.ηs[test.ηs .> 0])
        return new{T, N}(test)
    end
end

function causalbalance(lags, tes)
    posinds = findall(lags .> 0)
    neginds = findall(lags .< 0)
    sum(tes[posinds]) - sum(tes[neginds])  
end

function update_ηs(test::VisitationFrequencyTest)

    VisitationFrequencyTest(
        k = test.k, l = test.l, m = test.m, n = test.n, 
        τ = test.τ,
        binning_summary_statistic = test.binning_summary_statistic,
        binning = test.binning,
        ηs = verified_prediction_lags(test.ηs))
end

function update_ηs(test::TransferOperatorGridTest)
    
    TransferOperatorGridTest(
        k = test.k, l = test.l, m = test.m, n = test.n, 
        τ = test.τ,
        binning_summary_statistic = test.binning_summary_statistic,
        binning = test.binning,
        ηs = verified_prediction_lags(test.ηs))
end

function update_ηs(test::NearestNeighbourMITest{N}) where N

    NearestNeighbourMITest(
        k = test.k, l = test.l, m = test.m, n = test.n, 
        τ = test.τ,
        ηs = verified_prediction_lags(test.ηs))
end

function return_predictive_asymmetry(ηs, As, N)
    #T = typeof(As[1])
    #SVector{N, T}(As)
    As
end

return_predictive_asymmetry(η::Int, As, N) = As[1]


"""
    predictive_asymmetry(source, target, test::PredictiveAsymmetryTest{T, N}) where {T <: TransferEntropyCausalityTest, N}

Compute the predictive asymmetry from `source` to `target` using the provided predictive test `p`.
The test can be a [`VisitationFrequencyTest`](@ref), [`TransferOperatorGridTest`](@ref) or 
[`NearestNeighbourMITest`](@ref) and has to be defined for prediction lags symmetrically 
around zero.

## Example 

We'll use the [`nonlinear3d`](@ref) system, which consists of three variables 
and is unidirectionally coupled ``x \\to y \\to z``.

```julia
# Example data
sys = nonlinear3d()
npts = 300
orbit = trajectory(sys, npts, Ttr = 300);
x, y, z = columns(orbit);

# Test setup
η_max = 10
ηs = [-η_max:-1; 1:η_max]
bin = RectangularBinning(floor(Int, npts^(1/4)))
test = VisitationFrequencyTest(ηs = ηs, binning = bin)
pa_test = PredictiveAsymmetryTest(test)

# Analysis
pas_xy = causality(x, y, pa_test)
pas_yx = causality(y, x, pa_test)
pas_yz = causality(y, z, pa_test)
pas_zy = causality(z, y, pa_test)

[pas_xy pas_yx pas_yz pas_zy]
```

If the test correctly picked up the correct directionality, then the values of
of `asymmetries` corresponding to the causal interactions (1st and 3rd column)
should be mostly positive, and those corresponding to non-causal interactions 
should be mostly negative.
"""
function predictive_asymmetry(source, target, 
        p::PredictiveAsymmetryTest{T, N}) where {T <: TransferEntropyCausalityTest, N}

    # Update the test parameters so that we have symmetric prediction lags
    test = update_ηs(p.predictive_test)
    
    # Predictions from source to target. 
    preds = causality(source, target, test)

    # The number of predictive asymmetries is half the number of prediction lags,
    # which is encoded in the type parameter `N`
    ηs = test.ηs
    As = zeros(Float64, N)

    for (i, η) in enumerate(ηs[ηs .> 0])
        lag_idxs = findfirst(ηs .== -η):findfirst(ηs .== η)
        As[i] = causalbalance(ηs[lag_idxs], preds[lag_idxs])
    end

    return return_predictive_asymmetry(p.predictive_test.ηs, As, N)
end

function predictive_asymmetry(source, target, cond,
    p::PredictiveAsymmetryTest{T, N}) where {T <: TransferEntropyCausalityTest, N}

    # Update the test parameters so that we have symmetric prediction lags
    test = update_ηs(p.predictive_test)

    # Predictions from source to target. 
    preds = causality(source, target, cond, test)

    # The number of predictive asymmetries is half the number of prediction lags,
    # which is encoded in the type parameter `N`
    ηs = test.ηs
    As = zeros(Float64, N)

    for (i, η) in enumerate(ηs[ηs .> 0])
        lag_idxs = findfirst(ηs .== -η):findfirst(ηs .== η)
        As[i] = causalbalance(ηs[lag_idxs], preds[lag_idxs])
    end

    return return_predictive_asymmetry(p.predictive_test.ηs, As, N)
end

function causality(source::AbstractVector{T}, target::AbstractVector{T}, p::PredictiveAsymmetryTest{CT}) where {T<:Real, CT}
    predictive_asymmetry(source, target, p)
end

function causality(source::AbstractVector{T}, target::AbstractVector{T}, cond::AbstractVector{T}, 
        p::PredictiveAsymmetryTest{CT}) where {T<:Real, CT}
    predictive_asymmetry(source, target, cond, p)
end

# there is no need to define custom causality method for a uncertain data 
# as long as the predictive tests that it uses supports them

export 
    PredictiveAsymmetryTest, 
    predictive_asymmetry, 
    update_ηs, 
    verified_prediction_lags