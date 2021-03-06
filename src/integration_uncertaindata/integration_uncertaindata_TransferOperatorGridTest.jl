import ..CausalityTests.TransferOperatorGridTest

################################################################
# Integration with UncertainData.jl
################################################################
function causality(source::Vector{<:UVT1}, target::Vector{<:UVT2}, p::TransferOperatorGridTest) where {
        UVT1<:AbstractUncertainValue, 
        UVT2<:AbstractUncertainValue}
    causality(resample.(source), resample.(target), p)
end

function causality(source, target::Vector{<:UVT}, p::TransferOperatorGridTest) where { 
        UVT<:AbstractUncertainValue}
    causality(source, resample.(target), p)
end

function causality(source::Vector{<:UVT}, target, p::TransferOperatorGridTest) where {
        UVT<:AbstractUncertainValue}
    causality(resample.(source), target, p)
end

function causality(source::UVT1, target::UVT2, p::TransferOperatorGridTest) where {
        UVT1<:AbstractUncertainValueDataset, 
        UVT2<:AbstractUncertainValueDataset}
    causality(resample.(source), resample.(target), p)
end

function causality(source, target::UVT, p::TransferOperatorGridTest) where { 
        UVT<:AbstractUncertainValueDataset}
    causality(source, resample.(target), p)
end

function causality(source::UVT, target, p::TransferOperatorGridTest) where {
        UVT<:AbstractUncertainValueDataset}
    causality(resample.(source), target, p)
end
