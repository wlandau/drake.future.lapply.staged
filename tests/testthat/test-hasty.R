context("hasty")

test_that("hasty parallelism", {
  dir <- tempfile()
  dir.create(dir)
  withr::with_dir(dir, {
    load_mtcars_example()
    my_plan$command[my_plan$target == "report"] <-
      "utils::write.csv(coef_regression2_large, file = file_out(\"coef.csv\"))"
    options(clustermq.scheduler = "multicore")
    config <- drake_config(my_plan, parallelism = backend_hasty)
    for (jobs in 1:2) {
      config$hasty_build <- default_hasty_build
      if (jobs > 1) {
        skip_on_os("windows")
        skip_if_not_installed("clustermq")
        if ("package:clustermq" %in% search()) {
          detach("package:clustermq", unload = TRUE) # nolint
        }
      }
      config$jobs <- jobs
      # default build function
      expect_false(file.exists("coef.csv"))
      expect_warning(make(config = config), regexp = "USE AT YOUR OWN RISK")
      expect_true(file.exists("coef.csv"))
      expect_equal(length(intersect(my_plan$target, cached())), 0)
      unlink("coef.csv")
      expect_false(file.exists("coef.csv"))
      # remote_hasty_build()
      o <- remote_hasty_build(
        target = "small",
        deps = list(simulate = simulate),
        config = config
      )
      expect_true(is.data.frame(o$value))
      # custom build function
      expect_false(file.exists("small"))
      config$hasty_build <- function(target, config) {
        file.create(target)
      }
      expect_warning(
        make(config = config),
        regexp = "USE AT YOUR OWN RISK"
      )
      expect_true(file.exists("small"))
      unlink("small")
      expect_false(file.exists("small"))
      expect_equal(length(intersect(my_plan$target, cached())), 0)
      expect_false(file.exists("coef.csv"))
    }
    if ("package:clustermq" %in% search()) {
      detach("package:clustermq", unload = TRUE) # nolint
    }
  })
})
