#' Sampling for the Apparent Error Rate
#'
#' When building a model on a data set and re-predicting the same data, the
#'   performance estimate from those predictions is often called the
#'   "apparent" performance of the model. This estimate can be wildly
#'   optimistic. "Apparent sampling" here means that the analysis and
#'   assessment samples are the same. These resamples are sometimes used in
#'   the analysis of bootstrap samples and should otherwise be
#'   avoided like old sushi.
#'
#' @inheritParams vfold_cv
#' @return  A tibble with a single row and classes `apparent`,
#'   `rset`, `tbl_df`, `tbl`, and `data.frame`. The
#'   results include a column for the data split objects and one column
#'   called `id` that has a character string with the resample identifier.
#' @examples
#' apparent(mtcars)
#' @export
apparent <- function(data, ...) {
  splits <- rsplit(data, in_id = 1:nrow(data), out_id = 1:nrow(data))
  # splits <- rm_out(splits)
  class(splits) <- c("rsplit", "apparent_split")
  split_objs <- tibble::tibble(splits = list(splits), id = "Apparent")

  new_rset(
    splits = split_objs$splits,
    ids = split_objs$id,
    attrib = NULL,
    subclass = c("apparent", "rset")
  )
}
