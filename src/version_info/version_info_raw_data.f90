module raw_data_version_info
  use, intrinsic :: iso_c_binding
  implicit none

  !! DO NOT EDIT THIS FILE MANUALLY !!
  !! THIS FILE IS PRODUCED BY MAKE  !!

  integer(c_int), parameter :: FORMINE_VERSION_MAJOR = 0
  integer(c_int), parameter :: FORMINE_VERSION_MINOR = 4
  integer(c_int), parameter :: FORMINE_VERSION_PATCH = 0
  logical(c_bool), parameter :: FORMINE_IS_RELEASE = .false.
  character(len = 13, kind = c_char), parameter :: FORMINE_VERSION_STRING = "0.4.0 - Debug"
end module raw_data_version_info
