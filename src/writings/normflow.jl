import Pkg
Pkg.activate("example1d_env")
Pkg.add(["CairoMakie", "Makie", "LinearAlgebra", "Statistics", "Random", "Distributions"])
Pkg.resolve()
Pkg.instantiate()

import Random, CairoMakie, Makie, LinearAlgebra, Statistics, Distributions


N = 1000
x_samples_rng = Random.MersenneTwister(0xfeddddef)
dist_true = Distributions.Normal()
x_samples = Random.rand(x_samples_rng, dist_true, N)

bin_range = extrema(x_samples)
num_bins = 10
x_grid = range(bin_range[1], bin_range[2], 100)
pdf_true = Distributions.pdf.(dist_true, x_grid)
display(x_grid)

function random_bins(rng, num_bins; offset=0.1)
  # The ratio between the smallest and largest bin is at most 1 + 1/offset
  bins = Random.rand(rng, num_bins + 1) .+ offset
  bins[2:end] .*= (bin_range[2] - bin_range[1])/sum(bins[2:end])
  bins[1] = bin_range[1]
  bins .= cumsum(bins)
  # display(bins)
  return bins
end
f = Makie.Figure()
Makie.hist(f[1, 1], x_samples; bins = num_bins, normalization=:pdf)
Makie.lines!(f[1, 1], x_grid, pdf_true; color=:black)

bins = random_bins(x_samples_rng, num_bins)
Makie.hist(f[2, 1], x_samples; bins = bins, normalization=:pdf)
Makie.vlines!(f[2, 1], bins; color=:red)
Makie.lines!(f[2, 1], x_grid, pdf_true; color=:black)

bins = random_bins(x_samples_rng, num_bins)
Makie.hist(f[1, 2], x_samples; bins = bins, normalization=:pdf)
Makie.vlines!(f[1, 2], bins; color=:red)
Makie.lines!(f[1, 2], x_grid, pdf_true; color=:black)

bins = random_bins(x_samples_rng, num_bins)
Makie.hist(f[2, 2], x_samples; bins = bins, normalization=:pdf)
Makie.vlines!(f[2, 2], bins; color=:red)
Makie.lines!(f[2, 2], x_grid, pdf_true; color=:black)
display(f)

N = 200000
x_samples_rng = Random.MersenneTwister(0xfeddddef)
dist_target = Distributions.Normal()
z_samples = Random.rand(x_samples_rng, dist_target, N)

wavelength = 1
x_to_z_true(x) = -0.5 * sin(x * pi * 2 / wavelength + pi) / pi / 2 * wavelength + x
x_to_dz_dx_true(x) = -0.5 * cos(x * pi * 2 / wavelength + pi) + 1
function z_to_x_true(z)
  # z = R(x)
  # For inversion:
  #   F(x, z) = R(x) - z
  #   Solve for F(x, z) == 0
  #   x_{k+1} = x_k - dF/dx^{-1} F(z, x_k)
  #   x_{k+1} = x_k - dR/dx^{-1} (R(x_k) - z)
  x = deepcopy(z)
  r = x_to_z_true(x) - z
  i = 0
  while i < 100 && maximum(abs(r)) > 1e-10
    x -= r / x_to_dz_dx_true(x)
    r = x_to_z_true(x) - z
    i += 1
  end
  if i >= 100
    error("This took too long for input $z. Residual norm is $(abs(r))")
  end
  return x
end
function z_to_dx_dz_true(z)
  # x = R(z)
  # For inversion:
  #   F(x, z) = R(z) - x
  #   Solve for F(x, z) == 0
  # For gradient:
  #   dFdz * dzdx + dFdx == 0
  #   dzdx = - dFdz^{-1} dFdx
  x = z_to_x_true(z)
  dxdz = 1 ./ x_to_dz_dx_true(x)
  return dxdz
end
x_samples = z_to_x_true.(z_samples)

bin_range = extrema(x_samples)
num_bins = 20
x_grid = range(bin_range[1], bin_range[2], 500)
z_grid = x_to_z_true.(x_grid)
pdf_x_grid = Distributions.pdf.(dist_target, z_grid) ./ z_to_dx_dz_true.(z_grid)

f = Makie.Figure()
f[1, 1] = Makie.Axis(f)
Makie.vlines!(f[1, 1], 0:wavelength:bin_range[2]; color=:gray)
Makie.vlines!(f[1, 1], bin_range[1]:wavelength:0; color=:gray)
Makie.lines!(f[1, 1], x_grid, z_grid)
# Makie.lines!(f[1, 1], z_grid, z_to_x_true.(z_grid))
display(f)

f = Makie.Figure()
f[1, 1] = Makie.Axis(f)
Makie.vlines!(f[1, 1], 0:wavelength:bin_range[2]; color=:gray)
Makie.vlines!(f[1, 1], 0:-wavelength:bin_range[1]; color=:gray)
Makie.lines!(f[1, 1], x_grid, z_to_dx_dz_true.(z_grid))
display(f)

function random_bins(rng, num_bins; offset=0.1)
  # The ratio between the smallest and largest bin is at most 1 + 1/offset
  bins = Random.rand(rng, num_bins + 1) .+ offset
  bins[2:end] .*= (bin_range[2] - bin_range[1])/sum(bins[2:end])
  bins[1] = bin_range[1]
  bins .= cumsum(bins)
  return bins
end
f = Makie.Figure()
Makie.hist(f[1, 1], x_samples; bins = num_bins, normalization=:pdf)
Makie.lines!(f[1, 1], x_grid, pdf_x_grid; color=:black)

bins = random_bins(x_samples_rng, num_bins)
Makie.hist(f[2, 1], x_samples; bins = bins, normalization=:pdf)
Makie.lines!(f[2, 1], x_grid, pdf_x_grid; color=:black)

bins = random_bins(x_samples_rng, num_bins)
Makie.hist(f[1, 2], x_samples; bins = bins, normalization=:pdf)
Makie.lines!(f[1, 2], x_grid, pdf_x_grid; color=:black)

bins = random_bins(x_samples_rng, num_bins)
Makie.hist(f[2, 2], x_samples; bins = bins, normalization=:pdf)
Makie.lines!(f[2, 2], x_grid, pdf_x_grid; color=:black)
display(f)

num_bins = 40
x_samples_sorted = sort(x_samples)
num_points_per_bin, extra_points_per_bin = divrem(length(x_samples_sorted), num_bins)
x_bin_idxs = fill(num_points_per_bin, num_bins+1)
x_bin_idxs[1] = 1
x_bin_idxs[end-extra_points_per_bin+1:end] .+= 1
x_bin_idxs[end] -= 1
x_bin_idxs = cumsum(x_bin_idxs)
x_bins = x_samples_sorted[x_bin_idxs]
x_bins[2:end-1] .= (x_samples_sorted[x_bin_idxs[2:end-1]] .+ x_samples_sorted[x_bin_idxs[2:end-1] .- 1]) / 2

dist_target = Distributions.Normal()
z_bins = Statistics.quantile.(dist_target, x_bin_idxs ./ (length(x_samples_sorted)+2))

function piecewise_linear_normalizer(value, source_bins, target_bins)
  # Compute index for right side of bin.
  bin_idx = searchsorted(source_bins, value).start

  # Compute index for left side of bin.
  if bin_idx == 1
    other_bin_idx = 2
  elseif bin_idx == length(source_bins) + 1
    bin_idx = length(source_bins)
    other_bin_idx = bin_idx - 1
  else
    other_bin_idx = bin_idx - 1
  end

  # Apply linear mapping.
  s0 = source_bins[other_bin_idx]
  s1 = source_bins[bin_idx]
  t0 = target_bins[other_bin_idx]
  t1 = target_bins[bin_idx]
  dtds = (t1 - t0) / (s1 - s0)
  t = dtds * (value - s0) + t0
  return t, dtds
end
function piecewise_linear_normalizer_x_to_z(x)
  return piecewise_linear_normalizer(x, x_bins, z_bins)[1]
end
function piecewise_linear_normalizer_z_to_x(z)
  return piecewise_linear_normalizer(z, z_bins, x_bins)[1]
end
function piecewise_linear_normalizer_x_to_dzdx(x)
  return piecewise_linear_normalizer(x, x_bins, z_bins)[2]
end
function piecewise_linear_normalizer_z_to_dxdz(z)
  return piecewise_linear_normalizer(z, z_bins, x_bins)[2]
end


z_samples_learned_rng = Random.MersenneTwister(0xfeddddef)
z_samples_learned = piecewise_linear_normalizer_x_to_z.(x_samples)

bin_range = extrema(x_samples)
num_bins = 20
x_grid = range(bin_range[1], bin_range[2], 500)
z_grid = piecewise_linear_normalizer_x_to_z.(x_grid)
pdf_z_grid = Distributions.pdf.(dist_target, z_grid)

f = Makie.Figure()
f[1, 1] = Makie.Axis(f)
Makie.vlines!(f[1, 1], x_bins; color=:gray)
Makie.lines!(f[1, 1], x_grid, z_grid)
# Makie.lines!(f[1, 1], z_grid, z_to_x_true.(z_grid))
display(f)

f = Makie.Figure()
f[1, 1] = Makie.Axis(f)
Makie.vlines!(f[1, 1], x_bins; color=:gray)
Makie.lines!(f[1, 1], x_grid, piecewise_linear_normalizer_z_to_dxdz.(z_grid))
display(f)

f = Makie.Figure()
Makie.hist(f[1, 1], z_samples_learned; bins = num_bins, normalization=:pdf)
Makie.lines!(f[1, 1], z_grid, pdf_z_grid; color=:black)

bins = random_bins(z_samples_learned_rng, num_bins)
Makie.hist(f[2, 1], z_samples_learned; bins = bins, normalization=:pdf)
Makie.lines!(f[2, 1], z_grid, pdf_z_grid; color=:black)

bins = random_bins(z_samples_learned_rng, num_bins)
Makie.hist(f[1, 2], z_samples_learned; bins = bins, normalization=:pdf)
Makie.lines!(f[1, 2], z_grid, pdf_z_grid; color=:black)

bins = random_bins(z_samples_learned_rng, num_bins)
Makie.hist(f[2, 2], z_samples_learned; bins = bins, normalization=:pdf)
Makie.lines!(f[2, 2], z_grid, pdf_z_grid; color=:black)
display(f)

f = Makie.Figure()
f[1, 1] = Makie.Axis(f)
Makie.lines!(f[1, 1], x_grid, piecewise_linear_normalizer_x_to_dzdx.(x_grid))

Makie.vlines!(f[1, 1], 0:wavelength:bin_range[2]; color=:gray)
Makie.vlines!(f[1, 1], 0:-wavelength:bin_range[1]; color=:gray)
Makie.lines!(f[1, 1], x_grid, x_to_dz_dx_true.(x_grid))
display(f)


f = Makie.Figure()
f[1, 1] = Makie.Axis(f)
Makie.lines!(f[1, 1], x_grid, z_grid)

Makie.vlines!(f[1, 1], 0:wavelength:bin_range[2]; color=:gray)
Makie.vlines!(f[1, 1], 0:-wavelength:bin_range[1]; color=:gray)
Makie.lines!(f[1, 1], x_grid, x_to_z_true.(x_grid))
display(f)
