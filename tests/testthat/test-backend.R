context("backend")

test_that("future-based staged parallelism", {
  for (i in seq_len(2)) {
    dir <- tempfile()
    dir.create(dir)
    withr::with_dir(dir, {
      if (i > 1L) {
        e <- globalenv()
      } else {
        e <- new.env(parent = globalenv())
      }
      future::plan(future::sequential)
      load_mtcars_example(envir = e)
      my_plan <- e$my_plan
      expect_warning(
        make(
          my_plan,
          envir = e,
          parallelism = backend_future_lapply_staged,
          jobs = 1,
          verbose = FALSE,
          session_info = FALSE,
          lock_envir = TRUE
        ),
        regexp = "Staged parallelism for drake is deprecated"
      )
      config <- drake_config(
        my_plan,
        envir = e,
        parallelism = backend_future_lapply_staged,
        jobs = 1,
        verbose = FALSE,
        session_info = FALSE,
        lock_envir = TRUE
      )
      expect_equal(
        outdated(config),
        character(0)
      )
      my_plan$command[2] <- paste0("identity(", my_plan$command[2], ")")
      expect_warning(
        make(
          my_plan,
          envir = e,
          parallelism = backend_future_lapply_staged,
          jobs = 1,
          verbose = FALSE,
          session_info = FALSE,
          lock_envir = TRUE
        ),
        regexp = "Staged parallelism for drake is deprecated"
      )
      expect_equal(drake:::justbuilt(config), "small")
    })
  }
})

test_that("fls_prepare() writes cache folder if nonexistent", {
  dir <- tempfile()
  dir.create(dir)
  withr::with_dir(dir, {
    config <- drake::drake_config(drake_plan(a = 1))
    config$cache_path <- "nope"
    fls_prepare(config)
    expect_true(file.exists("nope"))
  })
})
