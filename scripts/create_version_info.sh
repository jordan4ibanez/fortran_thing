#!/bin/bash

# this is just ridiculous.

ARGUMENT="$@"
FOUND=false
VERSION_STRING=""
RAW_VERSION_IDENTIFIER=""
MAJOR=0
MINOR=0
PATCH=0
OUTPUT_STRING=""
IS_RELEASE=false
STRING_PARAMETER=""


while IFS= read -r LINE; do
  if [[ $LINE  == "version = "* ]]; then
    VERSION_STRING=$LINE
    FOUND=true
    break
  fi
done < fpm.toml


if ! $FOUND ; then
  echo ERROR: Could not find version. Please not remove the version identifier in the TOML.
  exit 125
fi


#* BEGIN 0.0.0 EXTRACTION.


# remove [version = ]
RAW_VERSION_IDENTIFIER=${VERSION_STRING#"version = "}

# remove leading "
RAW_VERSION_IDENTIFIER=${RAW_VERSION_IDENTIFIER#'"'}

# remove trailing "
RAW_VERSION_IDENTIFIER=${RAW_VERSION_IDENTIFIER%'"'}


#* BEGIN MAJOR, MINOR, PATCH EXTRACTION.


# Get MAJOR region.
MAJOR=${RAW_VERSION_IDENTIFIER%%.*}

# Remove MAJOR region.
RAW_VERSION_IDENTIFIER=${RAW_VERSION_IDENTIFIER#*.}


# Get MINOR region.
MINOR=${RAW_VERSION_IDENTIFIER%%.*}

# Remove MINOR region.
RAW_VERSION_IDENTIFIER=${RAW_VERSION_IDENTIFIER#*.}

# PATCH is whatever is left.
PATCH=$RAW_VERSION_IDENTIFIER


#* CHECK IF RELEASE.

if [[ $ARGUMENT == "RELEASE"* ]]; then
  IS_RELEASE=true
  STRING_PARAMETER='character(len = 15, kind = c_char), parameter :: FORMINE_VERSION_STRING = "'$MAJOR'.'$MINOR'.'$PATCH' - Release"'
else
  STRING_PARAMETER='character(len = 13, kind = c_char), parameter :: FORMINE_VERSION_STRING = "'$MAJOR'.'$MINOR'.'$PATCH' - Debug"'
fi

cat > "./src/version_info/version_info_raw_data.f90" <<- END
module raw_data_version_info
  use, intrinsic :: iso_c_binding
  implicit none

  !! DO NOT EDIT THIS FILE MANUALLY !!
  !! THIS FILE IS PRODUCED BY MAKE  !!

  integer(c_int), parameter :: FORMINE_VERSION_MAJOR = $MAJOR
  integer(c_int), parameter :: FORMINE_VERSION_MINOR = $MINOR
  integer(c_int), parameter :: FORMINE_VERSION_PATCH = $PATCH
  logical(c_bool), parameter :: FORMINE_IS_RELEASE = .$IS_RELEASE.
  $STRING_PARAMETER
end module raw_data_version_info
END





