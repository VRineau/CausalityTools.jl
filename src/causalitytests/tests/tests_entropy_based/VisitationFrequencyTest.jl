
import StatsBase

"""
    VisitationFrequencyTest(k::Int = 1, l::Int = 1, m::Int = 1, n::Int = 1, 
        τ::Int = 1, estimator::VisitationFrequency = VisitationFrequency(b = 2), 
        binning_summary_statistic::Function = StatsBase.mean,
        binning::RectangularBinning, ηs)

The parameters for a transfer entropy test using the `VisitationFrequency` estimator.
This is the original transfer entropy estimator from [1], as implemented in [2].


## Mandatory keyword arguments

- **`binning::RectangularBinning`**: An instance of a [`RectangularBinning`](@ref) that dictates 
    how the delay embedding is discretized.

- **`ηs`**: The prediction lags (that go into the ``T_{f}`` component of the embedding).

## Optional keyword arguments

- **`k::Int`**: The dimension of the ``T_{f}`` component of the embedding. 

- **`l::Int`**: The dimension of the ``T_{pp}`` component of the embedding. 

- **`m::Int`**: The dimension of the ``S_{pp}`` component of the embedding. 

- **`n::Int`**: The dimension of the ``C_{pp}`` component of the embedding. 

- **`τ::Int`**: The embedding lag. Default is `τ = 1`.

- **`estimator::VisitationFrequency`**: A `VisitationFrequency` estimator instance.

- **`binning_summary_statistic::Function`**: A summary statistic to summarise the 
    transfer entropy values if multiple binnings are provided.

## Estimation of the invariant measure

With a ` VisitationFrequencyTest`, the invariant distribution from which transfer 
entropy is computed is estimated using simple counting (hence, visitation frequency). 
Counting is done over the partition elements of a [discretization](@ref discretization) 
of an appropriate [delay reconstruction](@ref custom_delay_reconstruction) of the time 
series to be analysed.

## About the delay reconstruction for transfer entropy analysis

Denote the time series for the source process ``S`` as ``S(t)``, and the time series for 
the target process ``T`` as ``T(t)``, and ``C_i(t)`` as the time series for any conditional 
processes ``C_i`` that also may influence ``T``. To compute (conditional) TE, we need a 
generalised embedding [3, 4] incorporating all of these processes.

For convenience, define the state vectors

```math
\\begin{align}
T_f^{(k)} &= \\{(T(t+\\eta_k), \\ldots, T(t+\\eta_2), T(t+\\eta_1))\\}, \\label{eq:Tf} \\\\
T_{pp}^{(l)} &= \\{ (T(t), T(t-\\tau_1), T(t-\\tau_2), \\ldots, T(t - \\tau_{l - 1})) \\\\
S_{pp}^{(m)} &= \\{(S(t), S(t-\\tau_1), S(t-\\tau_2), \\ldots, S(t-\\tau_{m - 1}))\\},\\\\
C_{pp}^{(n)} &= \\{ (C_1(t), C_1(t-\\tau_1), \\ldots,  C_2(t), C_2(t-\\tau_1) \\},
\\end{align}
```

where the state vectors ``T_f^{(k)}`` contain ``k`` future values of the target 
variable, ``T_{pp}^{(l)}`` contain ``l`` present and past values of the target 
variable, ``S_{pp}^{(m)}`` contain ``m`` present and past values of the source 
variable, ``C_{pp}^{(n)}`` contain a total of ``n`` present and past values of any 
conditional variable(s).  Combining all variables, we have the generalised embedding 

```math 
\\begin{align}
\\mathbb{E} = (T_f^{(k)}, T_{pp}^{(l)}, S_{pp}^{(m)}, C_{pp}^{(n)})
\\end{align}
```

with a total embedding dimension of ``k + l + m + n``. 
Here, ``\\tau`` indicates the [embedding](@ref custom_delay_reconstruction) lag 
(in the `VisitationFrequencyTest`, we set ``\\tau_1 = \\tau_2 = \\tau_3 = \\ldots``), and
``\\eta`` indicates the prediction lag (the lag of the influence the source 
has on the target). 


Hence, in the generalised embedding, only ``T_f`` depends on the prediction lag ``\\eta``, 
which is to be determined by the analyst. For transfer entropy analysis, ``\\eta`` is chosen 
to be some positive integer, while for 
[predictive asymmetry analysis](@ref predictive_asymmetry), 
symmetric negative and positive ``\\eta``s are used for computing ``\\mathbb{A}``.  

In terms of this generalised embedding, transfer entropy from a source variable ``S`` to a 
target variable ``T`` with conditioning on variable(s) ``C`` is thus defined as 

```math
\\begin{align}
TE_{S \\rightarrow T|C} = \\int_{\\mathbb{E}} P(T_f, T_{pp}, S_{pp}, C_{pp}) \\log_{2}{\\left( \\frac{P(T_f | T_{pp}, S_{pp}, C_{pp})}{P(T_f | T_{pp}, C_{pp})}\\right)}
\\end{align}
```

Without conditioning, we have 

```math
\\begin{align}
TE_{S \\rightarrow T} = \\int_{\\mathbb{E}} P(T_f, T_{pp}, S_{pp}) \\log_{2}{\\left(\\frac{P(T_f | T_{pp}, S_{pp})}{P(T_f | T_{pp})}\\right)}
\\end{align}
```

## Low-level estimator 

This test uses the `VisitationFrequency` estimator on the following low-level method 
under the hood. 

- [`transferentropy(::Any, ::TEVars, ::RectangularBinning, ::TransferEntropyEstimator)`](@ref)

In this estimator, the mapping between variables of the 
[generalised embedding](@ref custom_delay_reconstruction) and the marginals during 
transfer entropy computation is controlled using a [`TEVars`](@ref) 
instance. It is *highly* recommended that you check the documentation for this 
method, because it describes the transfer entropy estimation procedure in detail.

## Notes:

- Use `causality(source, target, params::VisitationFrequencyTest)` for regular 
    transfer entropy analysis. This method uses only the `k`, `l`, `m` and ignores `n` 
    when constructing the delay reconstruction. 

- Use `causality(source, target, cond, params::VisitationFrequencyTest)` for conditional 
    transfer entropy analysis. This method uses the `k`, `l`, `m` *and* `n` when constructing 
    the delay reconstruction.

## Example

```julia
# Prediction lags
ηs = 1:10
binning = RectangularBinning(10)

# Use defaults, binning and prediction lags are required. 
# Note that `binning` and `ηs` are *mandatory* keyword arguments.
VisitationFrequencyTest(binning = binning, ηs = ηs)

# The other keywords can also be adjusted
VisitationFrequencyTest(k = 1, l = 2, binning = binning, ηs = ηs)
```

## References 

1. Schreiber, Thomas. "Measuring information transfer." Physical review letters 85.2 (2000): 461. 
    [https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.85.461](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.85.461)

2. Diego, David, Kristian Agasøster Haaga, and Bjarte Hannisdal. "Transfer entropy computation 
    using the Perron-Frobenius operator." Physical Review E 99.4 (2019): 042212.
    [https://journals.aps.org/pre/abstract/10.1103/PhysRevE.99.042212](https://journals.aps.org/pre/abstract/10.1103/PhysRevE.99.042212)

3.  Sauer, Tim, James A. Yorke, and Martin Casdagli. "Embedology." Journal of statistical Physics 65.3-4 (1991): 579-616.

4.  Deyle, Ethan R., and George Sugihara. "Generalized theorems for nonlinear state space reconstruction." PLoS One 6.3 (2011): e18295.
"""
Base.@kwdef mutable struct VisitationFrequencyTest{N} <: TransferEntropyCausalityTest{N}
    
    """ The delay reconstruction parameter k (controls dimension of ``T_{f}`` component of embedding). """
    k::Int = 1

    """ The delay reconstruction parameter l (controls dimension of ``T_{pp}`` component of embedding). """
    l::Int = 1

    """ The delay reconstruction parameter m (controls dimension of ``S_{pp}`` component of embedding). """
    m::Int = 1

    """ The delay reconstruction parameter n (controls dimension of ``C_{pp}`` component of embedding). """
    n::Int = 1

    """ The delay reconstruction lag for the ``T_{pp}`` component of the embedding. """
    τ::Int = 1

    """ The transfer entropy estimator. """
    estimator::VisitationFrequency = VisitationFrequency(b = 2)

    """ 
    If there are several binnings provided, what is the statistic used to summarise the 
    transfer entropy values to a single value?
    """
    binning_summary_statistic::Function = StatsBase.mean

    """ The binning scheme. """
    binning::Union{RectangularBinning, Vector{RectangularBinning}}

    """ The prediction lags"""
    ηs::Union{Int, AbstractVector{Int}}

    function VisitationFrequencyTest(k::Int, l::Int, m::Int, n::Int, τ::Int, 
            estimator::VisitationFrequency, 
            binning_summary_statistic::Function, 
            binning::Union{RectangularBinning, Vector{RectangularBinning}}, 
            ηs)
            
        N = length(ηs) # length of return vector when used with `causality`
        return new{N}(k, l, m, n, τ, estimator, binning_summary_statistic, binning, ηs)
    end
end


function causality(source::AbstractVector{T}, target::AbstractVector{T}, p::VisitationFrequencyTest) where {T <: Real}
    [transferentropy(source, target, p.k, p.l, p.m, p.binning, η = η, τ = p.τ, 
        summary_statistic = p.binning_summary_statistic, 
            estimator = p.estimator) for η in p.ηs]
end

function causality(source::AbstractVector{T}, target::AbstractVector{T}, cond::AbstractVector{T}, p::VisitationFrequencyTest) where {T <: Real}
    [transferentropy(source, target, cond, p.k, p.l, p.m, p.n, p.binning, η = η, τ = p.τ, 
        summary_statistic = p.binning_summary_statistic, 
            estimator = p.estimator) for η in p.ηs]
end


export VisitationFrequencyTest