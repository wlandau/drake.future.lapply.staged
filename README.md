
[![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/emersion/stability-badges#experimental) [![Travis build status](https://travis-ci.org/wlandau/drake.hasty.svg?branch=master)](https://travis-ci.org/wlandau/drake.hasty)

<!-- README.md is generated from README.Rmd. Please edit that file -->
Hasty mode for the drake R package
==================================

Hasty mode is accelerated execution with all of `drake`'s storage and reproducibility guarantees stripped away. For experimentation only. Use at your own risk.

Drawbacks
---------

1.  **DRAKE NO LONGER PROVIDES EVIDENCE THAT YOUR WORKFLOW IS TRUSTWORTHY OR REPRODUCIBLE. [THE CORE SCIENTIFIC CLAIMS](https://github.com/ropensci/drake#reproducibility-with-confidence) ARE NO LONGER VALID.**
2.  There is no cache, so
    1.  You need to write code to store your own targets (in your targets' commands or `config$hasty_build()`), and
    2.  `knitr`/`rmarkdown` reports with calls to `loadd()`/`readd()` will no longer work properly as pieces of the pipeline.

Advantages
----------

1.  Hasty mode is a sandbox. By supplying a `hasty_build` function to your `drake_config()` object, you can experiment with different ways to process targets.
2.  There is no overhead from storing and checking targets, so hasty mode runs much faster than `drake`'s standard modes.
3.  You still have scheduling and dependency management. `drake` still builds the correct targets in the correct order, waiting for dependencies to finish before advancing downstream.

Installation
------------

``` r
library(remotes)
install_github("wlandau/drake.hasty")
```

Usage
-----

We begin with a `drake` project.

``` r
library(drake.hasty)
plan <- drake_plan(x = rnorm(100), y = mean(x), z = median(x))

plan
#> # A tibble: 3 x 2
#>   target command   
#>   <chr>  <chr>     
#> 1 x      rnorm(100)
#> 2 y      mean(x)   
#> 3 z      median(x)
```

Create a `drake_config()` object from your workflow.

``` r
config <- drake_config(plan, parallelism = backend_hasty)
```

You can increase speed even more with some lesser-known `drake_config()` options.

``` r
config <- drake_config(
  plan,
  parallelism = backend_hasty,
  cache = storr::storr_environment(),
  skip_imports = TRUE,
  session_info = FALSE,
  skip_safety_checks = TRUE
)
```

Next, supply a function to build individual targets. Feel free to borrow from `default_hasty_build()`.

``` r
config$hasty_build <- default_hasty_build

config$hasty_build
#> function (target, config) 
#> {
#>     tidy_expr <- eval(expr = config$layout[[target]]$command_build, 
#>         envir = config$eval)
#>     eval(expr = tidy_expr, envir = config$eval)
#> }
#> <bytecode: 0x564424c4ef08>
#> <environment: namespace:drake.hasty>
```

Finally, run the project. For the fastest execution, set `skip_imports` to `TRUE`

``` r
make(config = config)
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://ropenscilabs.github.io/drake-manual/hpc.html#hasty-mode
#> target x
#> target y
#> target z
#> Skipped the imports. If some imports are not already cached, targets could be out of date.
```

There is no caching or checking in hasty mode, so your targets are never up to date.

``` r
make(config = config)
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://ropenscilabs.github.io/drake-manual/hpc.html#hasty-mode
#> target x
#> target y
#> target z
#> Skipped the imports. If some imports are not already cached, targets could be out of date.
```

If you have `clustermq` installed, you can use parallel computing.

``` r
# Use 2 persistent workers.
config$jobs <- 2

# See https://github.com/mschubert/clustermq for more options.
options(clustermq.scheduler = "multicore")

make(config = config)
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://ropenscilabs.github.io/drake-manual/hpc.html#hasty-mode
#> Submitting 2 worker jobs (ID: 7210) ...
#> target x
#> target y
#> target z
#> Master: [0.2s 19.8% CPU]; Worker: [avg 6.5% CPU, max 284.8 Mb]
#> Skipped the imports. If some imports are not already cached, targets could be out of date.
```
