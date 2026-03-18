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


function run_diffusion(x)

end


  self.diffusion = GaussianDiffusion2(
    betas=betas, model_mean_type=model_mean_type, model_var_type=model_var_type, loss_type=loss_type)
    self.num_classes = num_classes

    return unet.model(
      x, t=t, y=nothing, name="model", ch=128, ch_mult=(1, 2, 2, 2), num_res_blocks=2, attn_resolutions=(16,),
      out_ch=C, num_classes=self.num_classes, dropout=dropout
    )

  def train_fn(self, x, y):
    B, H, W, C = x.shape
    t = tf.random_uniform([B], 0, self.diffusion.num_timesteps, dtype=tf.int32)
    losses = self.diffusion.training_losses(
      denoise_fn=functools.partial(self._denoise, y=y, dropout=self.dropout), x_start=x, t=t)
    return tf.reduce_mean(losses)

  def samples_fn(self, dummy_noise, y):
    return self.diffusion.p_sample_loop(
        denoise_fn=functools.partial(self._denoise, y=y, dropout=0),
        shape=dummy_noise.shape.as_list(),
        noise_fn=tf.random_normal
      )

  def progressive_samples_fn(self, dummy_noise, y):
    samples, progressive_samples = self.diffusion.p_sample_loop_progressive(
      denoise_fn=functools.partial(self._denoise, y=y, dropout=0),
      shape=dummy_noise.shape.as_list(),
      noise_fn=tf.random_normal
    )
    return {"samples": samples, "progressive_samples": progressive_samples}

  def bpd_fn(self, x, y):
    total_bpd_b, terms_bpd_bt, prior_bpd_b, mse_bt = self.diffusion.calc_bpd_loop(
      denoise_fn=functools.partial(self._denoise, y=y, dropout=0),
      x_start=x
    )
    return {
      "total_bpd": total_bpd_b,
      "terms_bpd": terms_bpd_bt,
      "prior_bpd": prior_bpd_b,
      "mse": mse_bt
    }


def simple_eval(model_dir, tpu_name, bucket_name_prefix, mode, load_ckpt, total_bs=256, tfds_data_dir="tensorflow_datasets"):
  region = utils.get_gcp_region()
  tfds_data_dir = "gs://{}-{}/{}".format(bucket_name_prefix, region, tfds_data_dir)
  kwargs = tpu_utils.load_train_kwargs(model_dir)
  print("loaded kwargs:", kwargs)
  ds = datasets.get_dataset(kwargs["dataset"], tfds_data_dir=tfds_data_dir)
  worker = simple_eval_worker.SimpleEvalWorker(
    tpu_name=tpu_name, model_constructor=functools.partial(_load_model, kwargs=kwargs, ds=ds),
    total_bs=total_bs, dataset=ds)
  worker.run(mode=mode, logdir=model_dir, load_ckpt=load_ckpt)


def evaluation(  # evaluation loop for use during training
    model_dir, tpu_name, bucket_name_prefix, once=False, dump_samples_only=False, total_bs=256,
    tfds_data_dir="tensorflow_datasets", load_ckpt=None
):
  region = utils.get_gcp_region()
  tfds_data_dir = "gs://{}-{}/{}".format(bucket_name_prefix, region, tfds_data_dir)
  kwargs = tpu_utils.load_train_kwargs(model_dir)
  print("loaded kwargs:", kwargs)
  ds = datasets.get_dataset(kwargs["dataset"], tfds_data_dir=tfds_data_dir)
  worker = tpu_utils.EvalWorker(
    tpu_name=tpu_name,
    model_constructor=functools.partial(_load_model, kwargs=kwargs, ds=ds),
    total_bs=total_bs, inception_bs=total_bs, num_inception_samples=50000,
    dataset=ds,
  )
  worker.run(
    logdir=model_dir, once=once, skip_non_ema_pass=True, dump_samples_only=dump_samples_only, load_ckpt=load_ckpt)


def train(
    exp_name, tpu_name, bucket_name_prefix, model_name="unet2d16b2", dataset="cifar10",
    optimizer="adam", total_bs=128, grad_clip=1., lr=2e-4, warmup=5000,
    num_diffusion_timesteps=1000, beta_start=0.0001, beta_end=0.02, beta_schedule="linear",
    model_mean_type="eps", model_var_type="fixedlarge", loss_type="mse",
    dropout=0.1, randflip=1,
    tfds_data_dir="tensorflow_datasets", log_dir="logs", keep_checkpoint_max=2
):
  region = utils.get_gcp_region()
  tfds_data_dir = "gs://{}-{}/{}".format(bucket_name_prefix, region, tfds_data_dir)
  log_dir = "gs://{}-{}/{}".format(bucket_name_prefix, region, log_dir)
  kwargs = dict(locals())
  ds = datasets.get_dataset(dataset, tfds_data_dir=tfds_data_dir)
  tpu_utils.run_training(
    date_str="9999-99-99",
    exp_name="{exp_name}_{dataset}_{model_name}_{optimizer}_bs{total_bs}_lr{lr}w{warmup}_beta{beta_start}-{beta_end}-{beta_schedule}_t{num_diffusion_timesteps}_{model_mean_type}-{model_var_type}-{loss_type}_dropout{dropout}_randflip{randflip}".format(
      **kwargs),
    model_constructor=lambda: Model(
      model_name=model_name,
      betas=get_beta_schedule(
        beta_schedule, beta_start=beta_start, beta_end=beta_end, num_diffusion_timesteps=num_diffusion_timesteps
      ),
      model_mean_type=model_mean_type,
      model_var_type=model_var_type,
      loss_type=loss_type,
      num_classes=ds.num_classes,
      dropout=dropout,
      randflip=randflip
    ),
    optimizer=optimizer, total_bs=total_bs, lr=lr, warmup=warmup, grad_clip=grad_clip,
    train_input_fn=ds.train_input_fn,
    tpu=tpu_name, log_dir=log_dir, dump_kwargs=kwargs, iterations_per_loop=2000, keep_checkpoint_max=keep_checkpoint_max
  )



# z_samples_learned_rng = Random.MersenneTwister(0xfeddddef)
# z_samples_learned = piecewise_linear_normalizer_x_to_z.(x_samples)

# bin_range = extrema(x_samples)
# num_bins = 20
# x_grid = range(bin_range[1], bin_range[2], 500)
# z_grid = piecewise_linear_normalizer_x_to_z.(x_grid)
# pdf_z_grid = Distributions.pdf.(dist_target, z_grid)

# f = Makie.Figure()
# f[1, 1] = Makie.Axis(f)
# Makie.vlines!(f[1, 1], x_bins; color=:gray)
# Makie.lines!(f[1, 1], x_grid, z_grid)
# # Makie.lines!(f[1, 1], z_grid, z_to_x_true.(z_grid))
# display(f)

# f = Makie.Figure()
# f[1, 1] = Makie.Axis(f)
# Makie.vlines!(f[1, 1], x_bins; color=:gray)
# Makie.lines!(f[1, 1], x_grid, piecewise_linear_normalizer_z_to_dxdz.(z_grid))
# display(f)

# f = Makie.Figure()
# Makie.hist(f[1, 1], z_samples_learned; bins = num_bins, normalization=:pdf)
# Makie.lines!(f[1, 1], z_grid, pdf_z_grid; color=:black)

# bins = random_bins(z_samples_learned_rng, num_bins)
# Makie.hist(f[2, 1], z_samples_learned; bins = bins, normalization=:pdf)
# Makie.lines!(f[2, 1], z_grid, pdf_z_grid; color=:black)

# bins = random_bins(z_samples_learned_rng, num_bins)
# Makie.hist(f[1, 2], z_samples_learned; bins = bins, normalization=:pdf)
# Makie.lines!(f[1, 2], z_grid, pdf_z_grid; color=:black)

# bins = random_bins(z_samples_learned_rng, num_bins)
# Makie.hist(f[2, 2], z_samples_learned; bins = bins, normalization=:pdf)
# Makie.lines!(f[2, 2], z_grid, pdf_z_grid; color=:black)
# display(f)

# f = Makie.Figure()
# f[1, 1] = Makie.Axis(f)
# Makie.lines!(f[1, 1], x_grid, piecewise_linear_normalizer_x_to_dzdx.(x_grid))

# Makie.vlines!(f[1, 1], 0:wavelength:bin_range[2]; color=:gray)
# Makie.vlines!(f[1, 1], 0:-wavelength:bin_range[1]; color=:gray)
# Makie.lines!(f[1, 1], x_grid, x_to_dz_dx_true.(x_grid))
# display(f)


# f = Makie.Figure()
# f[1, 1] = Makie.Axis(f)
# Makie.lines!(f[1, 1], x_grid, z_grid)

# Makie.vlines!(f[1, 1], 0:wavelength:bin_range[2]; color=:gray)
# Makie.vlines!(f[1, 1], 0:-wavelength:bin_range[1]; color=:gray)
# Makie.lines!(f[1, 1], x_grid, x_to_z_true.(x_grid))
# display(f)
