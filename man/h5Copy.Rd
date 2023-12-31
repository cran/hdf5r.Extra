% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hdf5-functions.R
\name{h5Copy}
\alias{h5Copy}
\title{Copy an HDF5 link}
\usage{
h5Copy(
  from.file,
  from.name,
  to.file,
  to.name,
  overwrite = FALSE,
  verbose = TRUE,
  ...
)
}
\arguments{
\item{from.file}{The source HDF5 file.}

\item{from.name}{The source link name.}

\item{to.file}{The target HDF5 file.}

\item{to.name}{The destination HDF5 link name.}

\item{overwrite}{Whether or not to overwrite the existing link.}

\item{verbose}{Print progress.}

\item{...}{Arguments passed to \code{H5File$obj_copy_from()}}
}
\value{
This is an operation function and no return. Any failure should raise an 
error.
}
\description{
Copy an HDF5 link from one file to another file.
}
\note{
\itemize{
\item Copying can still work even if the \code{to.file} is actually identical 
to the \code{from.file}.
\item Attributes of \code{from.name} will be kept, while those of its parent 
H5Groups will not.
}
}
\examples{
file <- system.file("extdata", "pbmc_small.h5ad", package = "hdf5r.Extra")
to.file <- tempfile(fileext = ".h5")

# Copy a link to a new file
h5Copy(file, "obs", to.file, "obs")
obs <- h5Read(file, "obs")
obs2 <- h5Read(to.file, "obs")
stopifnot(identical(obs, obs2))

# The parent link (H5Group) will be created automatically
h5Copy(file, "obsm/tsne", to.file, "obsm/tsne")
obsm <- h5Read(to.file, "obsm")

# Copy the whole file
x <- h5Read(file)
h5Copy(file, "/", to.file, "/", overwrite = TRUE)
x2 <- h5Read(to.file)
stopifnot(identical(x, x2))

}
\seealso{
\code{\link[hdf5r]{H5File}}
}
