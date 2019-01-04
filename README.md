
[![stability-deprecated](https://img.shields.io/badge/stability-deprecated-red.svg)](https://github.com/emersion/stability-badges#deprecated) [![Travis build status](https://travis-ci.org/wlandau/drake.staged.svg?branch=master)](https://travis-ci.org/wlandau/drake.staged)

<!-- README.md is generated from README.Rmd. Please edit that file -->
Staged parallelism for the drake R package
==========================================

With staged parallelism, `drake` partitions the dependency graph into stages of conditionally independent targets and processes each stage with semi-transient parallel workers. This functionality is already deprecated, and it will be removed at some point later on.

Installation
------------

``` r
library(remotes)
install_github("ropensci/drake")
install_github("wlandau/drake.future.lapply.staged")
```

Usage
-----

We begin with a `drake` project.

``` r
library(drake.future.lapply.staged)
plan <- drake_plan(x = rnorm(100), y = mean(x), z = median(x))

plan
#> # A tibble: 3 x 2
#>   target command   
#>   <chr>  <chr>     
#> 1 x      rnorm(100)
#> 2 y      mean(x)   
#> 3 z      median(x)
```

First, create a `future` plan. See the [`future` README](https://github.com/HenrikBengtsson/future/blob/master/README.md) and [`future.batchtools` README](https://github.com/HenrikBengtsson/future.batchtools/blob/master/README.md) for guidance, and consult tables [here](https://github.com/HenrikBengtsson/future/blob/master/README.md#controlling-how-futures-are-resolved) and [here](https://github.com/HenrikBengtsson/future.batchtools/blob/master/README.md#choosing-batchtools-backend) for options for your plan.

``` r
library(future)
plan(multiprocess)
```

Next, run your `drake` project.

``` r
library(drake.future.lapply.staged)
make(plan, parallelism = backend_future_lapply_staged, jobs = 2)
#> Warning: `drake` can indeed accept a custom scheduler function for the
#> `parallelism` argument of `make()` but this is only for the sake of
#> experimentation and graceful deprecation. Your own custom schedulers may
#> cause surprising errors. Use at your own risk.
#> Warning: Staged parallelism for drake is deprecated and will be removed
#> eventually.
```
