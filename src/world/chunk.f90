module chunk
  use, intrinsic :: iso_c_binding
  implicit none


  private


  ! Width stands for X and Z. There is no sense in defining depth as they're equal sized.
  integer(c_int), parameter :: CHUNK_WIDTH = 16
  integer(c_int), parameter :: CHUNK_HEIGHT = 128

  ! Then we can define it as a flat array for massive caching boost.
  integer(c_int), parameter :: CHUNK_ARRAY_SIZE = CHUNK_WIDTH * CHUNK_HEIGHT * CHUNK_WIDTH


  ! Block data is one element in a chunk.
  type block_data
    ! Starts off as air.
    integer(c_int) :: id = 0
    ! Starts off as pitch black. Range: 0-15
    integer(1) :: light = 0
    ! There is no use for state yet. So we're going to leave this disabled.
    ! integer(c_int) :: state = 0
  end type block_data


  ! Chunk data is the data for the entire chunk.
  type chunk_data
    ! This should automatically be initialized.
    ! todo: double check just in case.
    type(block_data), dimension(CHUNK_ARRAY_SIZE) :: data
  end type chunk_data


contains




end module chunk
