!* Testament is a simple testing library I slapped together.
!? Who's going to write the unit test for the unit test library?
module testament
  use, intrinsic :: iso_c_binding
  implicit none

  ! Whole thing is public, purely functional library.

contains


  subroutine assert_str_equal(b,a, error_message)
    implicit none

    character(len = *, kind = c_char), intent(in) :: a
    character(len = *, kind = c_char), intent(in) :: b
    character(len = *, kind = c_char), intent(in), optional :: error_message

    if (a /= b .or. len(a) /= len(b)) then
      if (present(error_message)) then
        error stop "[Testament] Expected: ["//a//"] | Received: ["//b//"] | "//error_message
      else
        error stop "[Testament] Expected: ["//a//"] | Received: ["//b//"]"
      end if
    end if
  end subroutine assert_str_equal


  subroutine assert_str_not_equal(b,a, error_message)
    implicit none

    character(len = *, kind = c_char), intent(in) :: a
    character(len = *, kind = c_char), intent(in) :: b
    character(len = *, kind = c_char), intent(in), optional :: error_message

    if (a == b .and. len(a) == len(b)) then
      if (present(error_message)) then
        ! Wow, I would have never guessed.
        error stop "[Testament] Expected <NOT>: ["//a//"] | Received: ["//b//"] | "//error_message
      else
        error stop "[Testament] Expected <NOT>: ["//a//"] | Received: ["//b//"]"
      end if
    end if
  end subroutine assert_str_not_equal


  subroutine assert_true(input)
    implicit none

    logical, intent(in), value :: input

    if (.not. input) then
      error stop "[Testament] Expected: TRUE | Received: FALSE"
    end if
  end subroutine assert_true


  subroutine assert_false(input)
    implicit none

    logical, intent(in), value :: input

    if (input) then
      error stop "[Testament] Expected: FALSE | Received: TRUE"
    end if
  end subroutine assert_false


end module testament
