module test_stb_image_suite
  use :: stb_image
  use, intrinsic :: iso_c_binding
  implicit none


contains


  subroutine test_it()
    implicit none

    integer(1), dimension(:), allocatable :: test_data

    allocate(test_data(2 * 2 * 4))

    ! Make a square with RGBW.

    ! [1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14, 15, 16]

    test_data(1) = -1
    test_data(4) = -1

    test_data(6) = -1
    test_data(8) = -1

    test_data(11) = -1
    test_data(12) = -1

    test_data(13:16) = -1


    if (stbi_write_png("./test/textures/test_stb.png", 2, 2, test_data) == 0) then
      error stop "test failure D:"
    end if
  end subroutine test_it

end module test_stb_image_suite

program test_stb_image
  use :: test_stb_image_suite
  implicit none

  call test_it()

end program test_stb_image