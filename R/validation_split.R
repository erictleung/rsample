#' Create a Validation Set
#'
#' `validation_split()` takes a single random sample (without replacement) of
#'  the original data set to be used for analysis. All other data points are
#'  added to the assessment set (to be used as the validation set).
#'  `validation_time_split()` does the same, but takes the _first_ `prop` samples
#'  for training, instead of a random selection.
#'  `group_validation_split()` creates splits of the data based
#'  on some grouping variable, so that all data in a "group" is assigned to
#'  the same split.
#'
#'  Note that the input `data` to `validation_split()`, `validation_time_split()`,
#'  and `group_validation_split()` should _not_ contain the testing data. To
#'  create a three-way split directly of the entire data set, use [validation_set()].
#'
#' @template strata_details
#' @inheritParams vfold_cv
#' @inheritParams make_strata
#' @param prop The proportion of data to be retained for modeling/analysis.
#' @export
#' @return An tibble with classes `validation_split`, `rset`, `tbl_df`, `tbl`,
#'  and `data.frame`. The results include a column for the data split objects
#'  and a column called `id` that has a character string with the resample
#'  identifier.
#'
#' @seealso [initial_validation_split()], [validation_set()]
#'
#' @examplesIf rlang::is_installed("modeldata")
#' cars_split <- initial_split(mtcars)
#' cars_not_testing <- training(cars_split)
#' validation_split(cars_not_testing, prop = .9)
#' group_validation_split(cars_not_testing, cyl)
#'
#' data(drinks, package = "modeldata")
#' validation_time_split(drinks[1:200,])
#'
#' # Alternative
#' cars_split_3 <- initial_validation_split(mtcars)
#' validation_set(cars_split_3)
#' @export
validation_split <- function(data, prop = 3 / 4,
                             strata = NULL, breaks = 4, pool = 0.1, ...) {
  if (!missing(strata)) {
    strata <- tidyselect::vars_select(names(data), !!enquo(strata))
    if (length(strata) == 0) {
      strata <- NULL
    }
  }

  strata_check(strata, data)

  split_objs <-
    mc_splits(
      data = data,
      prop = prop,
      times = 1,
      strata = strata,
      breaks = breaks,
      pool = pool
    )

  ## We remove the holdout indices since it will save space and we can
  ## derive them later when they are needed.

  split_objs$splits <- map(split_objs$splits, rm_out)
  class(split_objs$splits[[1]]) <- c("val_split", "rsplit")

  if (!is.null(strata)) names(strata) <- NULL
  val_att <- list(
    prop = prop,
    strata = strata,
    breaks = breaks,
    pool = pool
  )

  new_rset(
    splits = split_objs$splits,
    ids = "validation",
    attrib = val_att,
    subclass = c("validation_split", "rset")
  )
}

#' @rdname validation_split
#' @inheritParams vfold_cv
#' @inheritParams initial_time_split
#' @export
validation_time_split <- function(data, prop = 3 / 4, lag = 0, ...) {
  if (!is.numeric(prop) | prop >= 1 | prop <= 0) {
    rlang::abort("`prop` must be a number on (0, 1).")
  }

  if (!is.numeric(lag) | !(lag %% 1 == 0)) {
    rlang::abort("`lag` must be a whole number.")
  }

  n_train <- floor(nrow(data) * prop)

  if (lag > n_train) {
    rlang::abort("`lag` must be less than or equal to the number of training observations.")
  }

  split <- rsplit(data, 1:n_train, (n_train + 1 - lag):nrow(data))
  class(split) <- c("val_time_split", "val_split", "rsplit")
  splits <- list(split)

  val_att <- list(prop = prop, strata = FALSE)

  new_rset(
    splits = splits,
    ids = "validation",
    attrib = val_att,
    subclass = c("validation_time_split", "validation_split", "rset")
  )
}

#' @rdname validation_split
#' @inheritParams group_initial_split
#' @export
group_validation_split <- function(data, group, prop = 3 / 4, ..., strata = NULL, pool = 0.1) {

  rlang::check_dots_empty()

  group <- validate_group({{ group }}, data)

  if (!missing(strata)) {
    strata <- check_grouped_strata({{ group }}, {{ strata }}, pool, data)
  }

  split_objs <-
    group_mc_splits(
      data = data,
      group = {{ group }},
      prop = prop,
      times = 1,
      strata = {{ strata }},
      pool = pool
    )

  ## We remove the holdout indices since it will save space and we can
  ## derive them later when they are needed.

  split_objs$splits <- map(split_objs$splits, rm_out)
  class(split_objs$splits[[1]]) <- c("group_val_split", "val_split", "rsplit")

  # This is needed for printing -- strata cannot be missing
  if (is.null(strata)) strata <- FALSE
  val_att <- list(
    prop = prop,
    group = group,
    strata = strata,
    pool = pool
  )

  new_rset(
    splits = split_objs$splits,
    ids = "validation",
    attrib = val_att,
    subclass = c("group_validation_split", "validation_split", "group_rset", "rset")
  )
}

