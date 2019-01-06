#' @title Staged parallelism for the drake R package
#' @description With staged parallelism,
#'   `drake` partitions the dependency graph into stages of
#'   conditionally independent targets and processes each
#'   stage with semi-transient parallel workers.
#'   This functionality is already deprecated,
#'   and it will be removed at some point later on.
#' @export
#' @param config a `drake_config()` object
#' @examples
#' # See <https://github.com/wlandau/drake.future.lapply.staged/blob/master/README.md> # nolint
#' # for examples.
backend_future_lapply_staged <- function(config) {
  warning(
    "Staged parallelism for drake is deprecated ",
    "and will be removed eventually.",
    call. = FALSE
  )
  drake:::assert_pkg("future")
  drake:::assert_pkg("future.apply")
  fls_prepare(config = config)
  schedule <- drake:::pretrim_schedule(config)
  while (length(igraph::V(schedule)$name)) {
    targets <- drake:::leaf_nodes(schedule)
    future.apply::future_lapply(
      X = targets,
      FUN = fls_build,
      cache_path = config$cache_path
    )
    schedule <- igraph::delete_vertices(schedule, v = targets)
  }
  fls_conclude(config)
  invisible()
}


fls_prepare <- function(config) {
  if (!file.exists(config$cache_path)) {
    dir.create(config$cache_path)
  }
  store_drake_config(config)
  save(
    list = setdiff(ls(globalenv(), all.names = TRUE), config$plan$target),
    envir = globalenv(),
    file = globalenv_file(config$cache_path)
  )
  for (item in c("envir", "schedule")) {
    config$cache$set(key = item, value = config[[item]], namespace = "config")
  }
  invisible()
}

fls_build <- function(target, cache_path) {
  config <- recover_drake_config(cache_path = cache_path)
  eval(
    parse(text = "base::require(drake.future.lapply.staged, quietly = TRUE)")
  )
  drake:::do_prework(config = config, verbose_packages = FALSE)
  meta <- drake:::drake_meta(target = target, config = config)
  if (!drake:::should_build_target(target, meta, config)) {
    drake:::console_skip(target = target, config = config)
    return(invisible())
  }
  drake:::announce_build(target = target, meta = meta, config = config)
  drake:::manage_memory(targets = target, config = config)
  build <- drake:::build_target(target = target, meta = meta, config = config)
  drake:::conclude_build(build = build, config = config)
  invisible()
}

fls_conclude <- function(config) {
  dir <- cache_path(config$cache)
  file <- globalenv_file(dir)
  unlink(file, force = TRUE)
}

recover_drake_config <- function(cache_path) {
  cache <- drake:::this_cache(cache_path, verbose = FALSE)
  config <- read_drake_config(cache = cache)
  dir <- drake:::cache_path(cache = cache)
  file <- globalenv_file(dir)
  load(file = file, envir = globalenv())
  config
}

globalenv_file <- function(cache_path) {
  file.path(cache_path, "globalenv.RData")
}

store_drake_config <- function(config) {
  config$cache$flush_cache() # Less data to save this way.
  save_these <- setdiff(names(config), "envir")  # envir could get massive.
  lapply(
    save_these,
    function(item) {
      config$cache$set(
        key = item,
        value = config[[item]],
        namespace = "config"
      )
    }
  )
  invisible()
}

read_drake_config <- function(cache) {
  keys <- cache$list(namespace = "config")
  out <- lapply(
    X = keys,
    FUN = function(item) {
      cache$get(key = item, namespace = "config", use_cache = FALSE)
    }
  )
  names(out) <- keys
  out$cache <- cache
  out
}
