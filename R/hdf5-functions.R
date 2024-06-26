
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Functions ####################################################################
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

## HDF5 link name ==============================================================

#' Format an absolute path name for HDF5 link
#' 
#' @param name String representing an expected name of HDF5 link.
#' 
#' @details
#' If \code{name} contains any of "", \code{NA} or \code{NULL}, will simply 
#' return \code{"/"}.
#' 
#' @return An update \code{name} starting with '/'.
#' 
#' @examples
#' h5AbsLinkName("ggg")
#' h5AbsLinkName("ggg/ddd")
#' h5AbsLinkName(NA)
#' h5AbsLinkName("")
#' h5AbsLinkName(NULL)
#' 
#' @importFrom easy.utils isValidCharacters
#' 
#' @export
h5AbsLinkName <- function(name) {
  name <- name[1]
  if (!any(isValidCharacters(x = name))) {
    name <- ""
  }
  root <- substring(text = name, first = 1, last = 1)
  if (!identical(x = root, y = "/")) {
    name <- paste0("/", name)
  }
  name <- gsub(pattern = "\\/+", replacement = "\\/", x = name)
  return(name)
}

## HDF5 datatype ===============================================================

#' Guess an HDF5 Datatype
#'
#' Wrapper around \code{\link[hdf5r:guess_nelem]{hdf5r::guess_dtype}}, allowing 
#' for the customization of string types such as utf-8 rather than defaulting to 
#' variable-length ASCII-encoded strings.
#'
#' @param x The object for which to guess the HDF5 datatype
#' @param stype 'utf8' or 'ascii7'
#' @param ... Arguments passed to \code{hdf5r::guess_dtype}
#' 
#' @return An object of class \code{\link[hdf5r]{H5T}}
#'
#' @seealso \code{\link[hdf5r:guess_nelem]{guess_dtype}}
#' 
#' @references 
#' \url{https://github.com/mojaveazure/seurat-disk/blob/163f1aade5bac38ed1e9e9c9
#' 12283a7e74781610/R/zzz.R}
#' 
#' @examples
#' h5GuessDtype(0)
#' h5GuessDtype("abc")
#' 
#' @importFrom hdf5r guess_dtype h5const H5T_STRING
#' @export
h5GuessDtype <- function(x, stype = c('utf8', 'ascii7'), ...) {
  stype <- match.arg(arg = stype)
  dtype <- guess_dtype(x = x, ...)
  if (!inherits(x = dtype, what = 'H5T_STRING')) {
    return(dtype)
  }
  return(switch(
    EXPR = stype,
    'utf8' = H5T_STRING$new(size = Inf)$set_cset(cset = h5const$H5T_CSET_UTF8),
    'ascii7' = H5T_STRING$new(size = 7L)
  ))
}

## Open an HDF5 file ===========================================================

#' Automatically retry opening HDF5 file
#' 
#' Helper function to open an HDF5 file. When the opening fails, will retry it 
#' until reach a timeout.
#' 
#' @param filename An HDF5 file to open
#' @param mode How to open it: 
#' \itemize{
#' \item \code{a} creates a new file or opens an existing one for read/write. 
#' \item \code{r} opens an existing file for reading
#' \item \code{r+} opens an existing file for read/write. 
#' \item \code{w} creates a file, truncating any existing ones.
#' \item \code{w-} and \code{x} are synonyms, creating a file and failing if it 
#' already exists.
#' }
#' @param timeout Positive integer. The timeout for retrying.
#' @param interval Positive integer. The interval seconds of retrying.
#' @param ... Arguments passed to \code{H5File$new()}
#' 
#' @details
#' \code{timeout} and \code{interval} must be positive. Otherwise no retrying, 
#' which is default setting.
#' 
#' @return 
#' When \code{file} is opened successfully, an \code{\link[hdf5r]{H5File}} will 
#' be returned. Otherwise, will keep retrying. When a timeout is reached, will 
#' raise an error and terminate the current R session.
#' 
#' @seealso \code{\link[hdf5r]{H5File}} for \code{mode}
#' 
#' @examples
#' file <- system.file("extdata", "pbmc_small.h5ad", package = "hdf5r.Extra")
#' h5fh <- h5TryOpen(file, mode = "r")
#' h5fh
#' h5fh$close_all()
#' 
#' @importFrom hdf5r H5File
#' @export
h5TryOpen <- function(
    filename, 
    mode = c("a", "r", "r+", "w", "w-", "x"),
    timeout = getOption(x = "h5TryOpen.timeout", default = 0),
    interval = getOption(x = "h5TryOpen.interval", default = 0),
    ...
) {
  mode <- match.arg(arg = mode)
  do.retry <- timeout > 0 && interval > 0
  if (mode %in% c("r", "r+")) {
    filename <- file_path_as_absolute(x = filename)
  }
  return(tryCatch(
    expr = H5File$new(filename = filename, mode = mode, ...),
    error = function(e) {
      message("Open file '", filename, "' failed: \n")
      if (!do.retry) {
        stop(e)
      }
      message("Keep retrying per minute with 'timeout' set to ", timeout, " s")
      time <- 0
      while(time < timeout) {
        Sys.sleep(time = interval)
        h5fh <- tryCatch(
          expr = H5File$new(filename = filename, mode = mode, ...),
          error = function(e) NULL
        )
        if (inherits(x = h5fh, what = "H5File")) {
          return(h5fh)
        }
        time <- time + interval
      }
      stop("Reach a timeout after ", time, " s. Cannot open '", filename, "'")
    }
  ))
}

## h5Class =====================================================================

#' Get the class of an HDF5 link
#' 
#' Functions to get or check the class of an HDF5 link.
#' 
#' @param file An existing HDF5 file
#' @param name Name of a link in \code{file}
#' 
#' @name h5Class
NULL

#' @returns 
#' \code{h5Class} returns a character specifying the class of the query HDF5 
#' link (typically H5D, H5Group or H5File).
#' 
#' @examples
#' file <- system.file("extdata", "pbmc_small.h5ad", package = "hdf5r.Extra")
#' h5Class(file, "X")
#' h5Class(file, "obs")
#' is.H5D(file, "X")
#' is.H5Group(file, "obs")
#' 
#' @export
#' @rdname h5Class
h5Class <- function(file, name) {
  h5obj <- h5Open(x = file, name = name, mode = "r")
  on.exit(expr = h5obj$close())
  cls <- class(x = h5obj)
  return(cls[1])
}

#' @returns 
#' \code{is.H5D} and \code{is.H5Group} return a logical value.
#' 
#' @importFrom hdf5r H5D
#' @export
#' @rdname h5Class
is.H5D <- function(file, name) {
  return(.h5_is_a(file = file, name = name, what = "H5D"))
}

#' @importFrom hdf5r H5Group
#' @export
#' @rdname h5Class
is.H5Group <- function(file, name) {
  return(.h5_is_a(file = file, name = name, what = "H5Group"))
}

## Move and copy HDF5 links ====================================================

#' Copy an HDF5 link
#' 
#' Copy an HDF5 link from one file to another file.
#'
#' @param from.file The source HDF5 file.
#' @param from.name The source link name.
#' @param to.file The target HDF5 file.
#' @param to.name The destination HDF5 link name.
#' @param overwrite Whether or not to overwrite the existing link.
#' @param verbose Print progress.
#' @param ... Arguments passed to \code{H5File$obj_copy_from()}
#' 
#' @seealso \code{\link[hdf5r]{H5File}}
#' 
#' @note
#' \itemize{
#' \item Copying can still work even if the \code{to.file} is actually identical 
#' to the \code{from.file}.
#' \item Attributes of \code{from.name} will be kept, while those of its parent 
#' H5Groups will not.
#' }
#' 
#' @returns 
#' This is an operation function and no return. Any failure should raise an 
#' error.
#' 
#' @examples
#' file <- system.file("extdata", "pbmc_small.h5ad", package = "hdf5r.Extra")
#' to.file <- tempfile(fileext = ".h5")
#' 
#' # Copy a link to a new file
#' h5Copy(file, "obs", to.file, "obs")
#' obs <- h5Read(file, "obs")
#' obs2 <- h5Read(to.file, "obs")
#' stopifnot(identical(obs, obs2))
#' 
#' # The parent link (H5Group) will be created automatically
#' h5Copy(file, "obsm/tsne", to.file, "obsm/tsne")
#' obsm <- h5Read(to.file, "obsm")
#' 
#' # Copy the whole file
#' x <- h5Read(file)
#' h5Copy(file, "/", to.file, "/", overwrite = TRUE)
#' x2 <- h5Read(to.file)
#' stopifnot(identical(x, x2))
#' 
#' @export
h5Copy <- function(
    from.file,
    from.name,
    to.file,
    to.name,
    overwrite = FALSE,
    verbose = TRUE,
    ...
) {
  from.file <- file_path_as_absolute(x = from.file)
  from.name <- h5AbsLinkName(name = from.name)
  to.file <- normalizePath(path = to.file, mustWork = FALSE)
  to.name <- h5AbsLinkName(name = to.name)
  verboseMsg(
    "h5Copy: ",
    "\n  Source file: ", from.file,
    "\n  Destination file: ", to.file,
    "\n  Source name: ", from.name,
    "\n  Destination name: ", to.name
  )
  if (identical(x = from.file, y = to.file)) {
    return(.h5copy_same_file(
      h5.file = from.file, 
      from.name = from.name, 
      to.name = to.name, 
      overwrite = overwrite, 
      verbose = verbose,
      ...
    ))
  }
  return(.h5copy_different_file(
    from.file = from.file,
    from.name = from.name,
    to.file = to.file,
    to.name = to.name,
    overwrite = overwrite,
    verbose = verbose,
    ...
  ))
}

#' Move link in an HDF5 file
#' 
#' Move one HDF5 link to another position within the same file.
#' 
#' @param file An HDF5 file.
#' @param from.name Name of the source link.
#' @param to.name Name of the destination link.
#' @param overwrite When \code{to.name} already exists, whether or not to 
#' overwrite it.
#' @param verbose Print progress.
#' @param ... Arguments passed to \code{H5File$link_move_from()}
#' 
#' @seealso \code{\link[hdf5r]{H5File}}
#' 
#' @returns 
#' This is an operation function and no return. Any failure should raise an 
#' error.
#' 
#' @examples
#' file <- system.file("extdata", "pbmc_small.h5ad", package = "hdf5r.Extra")
#' to.file <- tempfile(fileext = ".h5")
#' file.copy(file, to.file)
#' 
#' obs <- h5Read(to.file, "obs")
#' h5Move(to.file, "obs", "obs2")
#' obs2 <- h5Read(to.file, "obs2")
#' stopifnot(identical(obs, obs2))
#' 
#' # Move an object to an existing link
#' h5Move(to.file, "obs2", "var")  # Warning
#' h5Move(to.file, "obs2", "var", overwrite = TRUE)
#' 
#' # Move a non-existing object will raise an error
#' try(h5Move(to.file, "obs", "obs3"))
#' 
#' @export
h5Move <- function(
    file,
    from.name,
    to.name,
    overwrite = FALSE,
    verbose = TRUE,
    ...
) {
  from.name <- h5AbsLinkName(name = from.name)
  to.name <- h5AbsLinkName(name = to.name)
  verboseMsg(
    "h5Move: ",
    "\n  File: ", file,
    "\n  Source name: ", from.name,
    "\n  Destination name: ", to.name
  )
  if (identical(x = from.name, y = to.name)) {
    warning(
      "The source name and the destination name are identical.",
      immediate. = TRUE
    )
    return(invisible(x = NULL))
  }
  h5fh <- h5TryOpen(filename = file, mode = "r+")
  on.exit(expr = h5fh$close())
  if (!h5Exists(x = h5fh, name = from.name)) {
    stop("Cannot move a non-existing object: ", from.name)
  }
  if (h5Exists(x = h5fh, name = to.name)) {
    if (!overwrite) {
      warning(
        "Destination object already exists. ",
        "Set 'overwrite = TRUE' to remove it.",
        immediate. = TRUE
      )
      return(invisible(x = NULL))
    }
    if (verbose) {
      message("Destination object already exists, removing it.")
    }
    h5fh$link_delete(name = to.name)
  }
  h5CreateGroup(
    x = h5fh, 
    name = dirname(path = to.name), 
    show.warnings = FALSE
  )
  h5fh$link_move_from(
    src_loc = h5fh, 
    src_name = from.name, 
    dst_name = to.name, 
    ...
  )
  return(invisible(x = NULL))
}

#' Back up contents from one HDF5 file to another
#' 
#' Function to back up HDF5 file, with optionally excluding specific links.
#' 
#' @param from.file The source HDF5 file.
#' @param to.file The target HDF5 file. Cannot be the same file as 
#' \code{from.file}. If \code{NULL}, will generate an R temp file.
#' @param exclude Names of HDF5 links not to be backed up.
#' @param overwrite When the \code{to.file} already exists, whether or not to 
#' overwrite it.
#' @param verbose Print progress.
#' @param ... Arguments passed to \code{H5File$obj_copy_from()}
#' 
#' @details
#' When any HDF5 link is to be excluded, it will copy the rest of links from
#' \code{from.file} using \code{\link{h5Copy}}. Otherwise, it will simply copy 
#' the \code{from.file} to the \code{to.file} via \code{\link{file.copy}} 
#' 
#' @return Path of the \code{to.file}
#' 
#' @examples
#' file <- system.file("extdata", "pbmc_small.h5ad", package = "hdf5r.Extra")
#' to.file <- tempfile(fileext = ".h5")
#' 
#' h5Backup(file, to.file, exclude = "X")
#' 
#' x <- h5Read(file)
#' x2 <- h5Read(to.file)
#' x$X <- NULL # Remove 'X'
#' stopifnot(identical(x, x2)) # Now these two should be identical
#' 
#' @export
h5Backup <- function(
    from.file, 
    to.file = NULL, 
    exclude = NULL, 
    overwrite = FALSE,
    verbose = TRUE,
    ...
) {
  to.file <- to.file %||% paste0(tempfile(), ".h5")
  to.file <- normalizePath(path = to.file, mustWork = FALSE)
  from.file <- file_path_as_absolute(x = from.file)
  verboseMsg(
    "h5Backup: ",
    "\n  Source file: ", from.file,
    "\n  Destination file: ", to.file,
    "\n  Excluded objects: ", paste(exclude, collapse = ", ")
  )
  if (identical(x = from.file, y = to.file)) {
    stop("\n  The source file and the target file are identical.")
  }
  if (!overwrite && file.exists(to.file)) {
    stop("The destination file exists, please set 'overwrite = TRUE'")
  }
  h5fh <- h5TryOpen(filename = from.file, mode = "r")
  all_links <- h5List(
    x = h5fh, 
    full.names = TRUE, 
    simplify = FALSE, 
    detailed = FALSE, 
    recursive = TRUE
  )
  keep_links <- all_links$name
  if (length(x = exclude) > 0) {
    keep_links <- .exclude_h5_links(all_links = keep_links, exclude = exclude)
  }
  if (identical(x = keep_links, y = all_links$name)) {
    h5fh$close()
    file.copy(from = from.file, to = to.file, overwrite = TRUE)
    return(to.file)
  }
  on.exit(expr = h5fh$close())
  all_links <- all_links[all_links$name %in% keep_links, , drop = FALSE]
  
  to.h5fh <- h5TryOpen(filename = to.file, mode = "w")
  on.exit(expr = to.h5fh$close(), add = TRUE)
  for (i in seq_along(along.with = all_links$name)) {
    verboseMsg("Backup '", all_links[i, "name"], "'")
    # all_links[i, "obj_type"] is actually `factor_ext`
    if (as.character(x = all_links[i, "obj_type"]) %in% "H5I_GROUP") {
      h5CreateGroup(
        x = to.h5fh, 
        name = all_links[i, "name"], 
        show.warnings = FALSE
      )
    } else {
      h5CreateGroup(
        x = to.h5fh, 
        name = dirname(path = all_links[i, "name"]), 
        show.warnings = FALSE
      )
      to.h5fh$obj_copy_from(
        src_loc = h5fh, 
        src_name = all_links[i, "name"], 
        dst_name = all_links[i, "name"], 
        ...
      )
    }
    .h5attr_copy_all(
      from.h5fh = h5fh,
      from.name = all_links[i, "name"],
      to.h5fh = to.h5fh,
      to.name = all_links[i, "name"],
      overwrite = TRUE
    )
  }
  .h5attr_copy_all(
    from.h5fh = h5fh,
    from.name = "/",
    to.h5fh = to.h5fh,
    to.name = "/",
    overwrite = TRUE
  )
  return(to.file)
}

#' Overwrite an existing HDF5 link
#' 
#' @param file An existing HDF5 file
#' @param name Name of HDF5 link to be overwritten. 
#' @param overwrite Whether or not to overwrite \code{name}. 
#' 
#' @return Path to \code{file} which is ready to be written.
#' 
#' @details
#' \itemize{
#' \item When \code{file} doesn't exist, will create it.
#' \item When the old link \code{name} doesn't exist, will simply return 
#' \code{file}. 
#' \item When \code{name} exists and \code{overwrite} is \code{TRUE}, will copy 
#' the rest of HDF5 links to an updated \code{file} with \code{\link{h5Backup}}. 
#' If \code{name} is "/", will create a new \code{file} and overwrite the old one.
#' \item When \code{name} exists and \code{overwrite} is \code{FALSE}, will 
#' raise an error.
#' }
#' 
#' @examples
#' file <- system.file("extdata", "pbmc_small.h5ad", package = "hdf5r.Extra")
#' tmp.file <- tempfile(fileext = ".h5")
#' file.copy(file, tmp.file)
#' 
#' obs <- h5Read(tmp.file, "obs")
#' 
#' h5Overwrite(tmp.file, "layers", TRUE)
#' stopifnot(!h5Exists(tmp.file, "layers"))
#' 
#' # You can still read other links.
#' obs2 <- h5Read(tmp.file, "obs")
#' stopifnot(identical(obs, obs2))
#' 
#' @export
h5Overwrite <- function(file, name, overwrite) {
  name <- h5AbsLinkName(name = name)
  if (!file.exists(file)) {
    h5CreateFile(x = file)
    return(normalizePath(path = file))
  }
  file <- normalizePath(path = file)
  if (name == "/" & overwrite) {
    warning(
      "Overwrite '/' will truncate anything in the orignial file:\n  ", file,
      immediate. = TRUE
    )
    h5fh <- h5TryOpen(filename = file, mode = "w")
    on.exit(expr = h5fh$close())
    return(file)
  }
  if (!h5Exists(x = file, name = name)) {
    return(file)
  }
  if (!overwrite) {
    stop(
      "\nFound object that already exists: ",
      "\n  File: ", file, 
      "\n  Object: ", name,
      "\nSet 'overwrite = TRUE' to remove it."
    )
  }
  tmp.file <- tempfile(tmpdir = dirname(path = file), fileext = ".h5")
  message(
    "Overwriting existing H5 object:",
    "\n  File: ", file,
    "\n  Object: ", name
  )
  file.rename(from = file, to = tmp.file)
  tryCatch(
    expr = {
      h5Backup(
        from.file = tmp.file, 
        to.file = file, 
        exclude = name, 
        overwrite = TRUE,
        verbose = FALSE
      )
      unlink(x = tmp.file)
    },
    error = function(e) {
      file.rename(from = tmp.file, to = file)
      stop(e)
    }
  )
  return(file)
}
