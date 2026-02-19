#= function to retrieve Kf as function of layered geometry with variable Kf =#
using LinearAlgebra

function update_Kf(     x               :: Vector{Float64},
                        y               :: Vector{Float64},
                        h               :: Matrix{Float64},
                        kf              :: Matrix{Float64},
                        n_layers        :: Int,
                        h_layers        :: Vector{Float64},
                        kf_layers       :: Vector{Float64},
                        tilt_x_alpha    :: Float64,
                        random          :: Matrix{Float64};
                        up = 0)

    nx = size(kf)[1]
    ny = size(kf)[2]

    origin_x = 0.0

    for i =1:nx
        xp = x[i] - origin_x
        for j = 1:ny

            for k = 1:n_layers-1

                if h[i,j] >= h_layers[k] - xp*tan(deg2rad(tilt_x_alpha))
                    kf[i,j] = kf_layers[k]
                end

            end

        end
    end
    if up == 1
        kf .+= random .* kf
    end

    return kf
end
