#' Helper target for file copying
#' 
#' Built on top of [tarchetypes::tar_files_raw], this
#' utility can take two vectors of file paths, for as simple
#' as one file to another to batch copying.
#' 
#' @param name A symbol to be used as the target name
#' @param from A character vector of original file paths
#' @param to A character vector of destination file paths
#' @param overwrite If `TRUE`, copies will overwrite older existing files
#' @param ... Arguments passed to [tarchetypes::tar_files_raw]
#' @return A copy of `to` for targets to track
tar_files_copy <- function(name, from, to, overwrite = TRUE, ...) {
  tar_name <- as.character(substitute(name))
  from_sym <- substitute(from)
  to_sym <- substitute(to)

  tarchetypes::tar_files_raw(
    tar_name,
    bquote(copy_to(.(from_sym), .(to_sym), overwrite = .(overwrite))),
    ...
  )
}

copy_to <- function(from, to, overwrite) {
  fs::file_copy(
    from,
    to,
    overwrite = overwrite
  )

  to
}