% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hdf5-functions.R
\name{h5Move}
\alias{h5Move}
\title{Move link in an HDF5 file}
\usage{
h5Move(file, from.name, to.name, overwrite = FALSE, verbose = TRUE, ...)
}
\arguments{
\item{file}{An HDF5 file.}

\item{from.name}{Name of the source link.}

\item{to.name}{Name of the destination link.}

\item{overwrite}{When \code{to.name} already exists, whether or not to 
overwrite it.}

\item{verbose}{Print progress.}

\item{...}{Arguments passed to \code{H5File$link_move_from()}}
}
\value{
This is an operation function and no return. Any failure should raise an 
error.
}
\description{
Move one HDF5 link to another position within the same file.
}
\examples{
file <- system.file("extdata", "pbmc_small.h5ad", package = "hdf5r.Extra")
to.file <- tempfile(fileext = ".h5")
file.copy(file, to.file)

obs <- h5Read(to.file, "obs")
h5Move(to.file, "obs", "obs2")
obs2 <- h5Read(to.file, "obs2")
stopifnot(identical(obs, obs2))

# Move an object to an existing link
h5Move(to.file, "obs2", "var")  # Warning
h5Move(to.file, "obs2", "var", overwrite = TRUE)

# Move a non-existing object will raise an error
try(h5Move(to.file, "obs", "obs3"))

}
\seealso{
\code{\link[hdf5r]{H5File}}
}
