module matrix_4f
  use, intrinsic :: iso_c_binding, only: c_float
  implicit none

  private

  !*
  !* As you can see, mat4f differs greatly from vec3f because it's
  !* only purpose is to do matrix math and shove that math into an
  !* OpenGL uniform.
  !*
  !* You can also probably see this differs greatly from regular fortran matrix
  !* math because it's using a flat array as a backing structure.
  !*
  !* This contains methods translated from JOML (Java) into Fortran.
  !*
  !* Please see joml.license for (MIT) licensing information.
  !*
  !* Why did I do this? I like JOML. That's about it!
  !*

  public :: mat4f

  !? This is an identifier to translate from JOML to Fortran. 00 based vs 1 linear based
  !? 1  2  3  4
  !? 5  6  7  8
  !? 9  10 11 12
  !? 13 14 15 16

  !?-------------
  !? | m00 | 1  |
  !? | m01 | 2  |
  !? | m02 | 3  |
  !? | m03 | 4  |
  !?-------------
  !? | m10 | 5  |
  !? | m11 | 6  |
  !? | m12 | 7  |
  !? | m13 | 8  |
  !?-------------
  !? | m20 | 9  |
  !? | m21 | 10 |
  !? | m22 | 11 |
  !? | m23 | 12 |
  !?-------------
  !? | m30 | 13 |
  !? | m31 | 14 |
  !? | m32 | 15 |
  !? | m33 | 16 |
  !?-------------



  type mat4f
    real(c_float), dimension(16) :: data = [ &
      1.0, 0.0, 0.0, 0.0, &
      0.0, 1.0, 0.0, 0.0, &
      0.0, 0.0, 1.0, 0.0, &
      0.0, 0.0, 0.0, 1.0 &
      ]
  contains
    !* There is only assignment operator. Everything else is too dangerous to implement.
    generic :: assignment(=) => assign_mat4f
    procedure :: assign_mat4f

    !* General methods.
    procedure :: identity
    procedure :: perspective

    !* Spacial methods.
    procedure :: translate
    procedure :: translate_vec3f
    procedure :: rotate_x
    procedure :: rotate_y
    procedure :: rotate_z

    !! Internal, only.
    procedure, private :: get_translation_array
    procedure, private :: set_translation_array
  end type mat4f

  interface mat4f
    module procedure :: constructor_scalar_f32, constructor_raw_f32, constructor_array_f32
  end interface mat4f

contains


  !* Constructor.


  type(mat4f) function constructor_scalar_f32(i) result(new_mat4f)
    implicit none
    real(c_float), intent(in), value :: i

    new_mat4f%data(1:16) = i
  end function constructor_scalar_f32


  type(mat4f) function constructor_raw_f32(x1,y1,z1,w1,x2,y2,z2,w2,x3,y3,z3,w3,x4,y4,z4,w4) result(new_mat4f)
    implicit none

    real(c_float), intent(in), value :: x1,y1,z1,w1,x2,y2,z2,w2,x3,y3,z3,w3,x4,y4,z4,w4

    new_mat4f%data(1:16) = [x1,y1,z1,w1,x2,y2,z2,w2,x3,y3,z3,w3,x4,y4,z4,w4]
  end function constructor_raw_f32


  type(mat4f) function constructor_array_f32(matrix_array) result(new_mat4f)
    implicit none

    real(c_float), dimension(16), intent(in) :: matrix_array

    new_mat4f%data(1:16) = matrix_array(1:16)
  end function constructor_array_f32


  !* Assignment.


  subroutine assign_mat4f(this, other)
    implicit none

    class(mat4f), intent(inout) :: this
    type(mat4f), intent(in), value :: other

    this%data(1:16) = other%data(1:16)
  end subroutine assign_mat4f


  !* General methods.


  subroutine identity(this)
    implicit none

    class(mat4f), intent(inout) :: this

    this%data(1:16) = [ &
      1.0, 0.0, 0.0, 0.0, &
      0.0, 1.0, 0.0, 0.0, &
      0.0, 0.0, 1.0, 0.0, &
      0.0, 0.0, 0.0, 1.0 &
      ]
  end subroutine identity


  !* Translated from JOML.
  subroutine perspective(this, fov_y_radians, aspect_ratio, z_near, z_far)
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none

    class(mat4f), intent(inout) :: this
    ! Very poor accuracy, if you're copying this in the future, first of all: Hi, I hope you're doing well. Second of all: You should use c_double or real64.
    ! I'm just using this like this so I can upload it straight into the GPU. (I am very lazy)
    real(c_float), intent(in), value :: fov_y_radians, aspect_ratio, z_near, z_far
    real(c_float) :: height, epsil
    real(c_float), dimension(4) :: r
    logical :: far_infinite, near_infinite
    ! Cache.
    real(c_float), dimension(16) :: mat

    mat = this%data

    height = tan(fov_y_radians * 0.5)
    r(1) = 1.0 / (height * aspect_ratio)
    r(2) = 1.0 / height

    far_infinite = (z_far > 0.0) .and. (.not. ieee_is_finite(z_far))
    near_infinite = (z_near > 0.0) .and. (.not. ieee_is_finite(z_near))

    if (far_infinite) then
      epsil = 1000000.0
      r(3) = epsil - 1.0
      r(4) = (epsil - 2.0) * z_near
    else if (near_infinite) then
      epsil = 1000000.0
      r(3) = 1.0 - epsil
      r(4) = (2.0 - epsil) * z_far
    else
      r(3) = (z_far + z_near) / (z_near - z_far)
      r(4) = (z_far + z_far) * z_near / (z_near - z_far)
    end if

    this%data(1:16) = [&
      mat(1:4)  * r(1), &
      mat(5:8)  * r(2), &
      mat(9:12) * r(3) - mat(13:16), &
      mat(9:12) * r(4) &
      ]
  end subroutine perspective


  !* Spacial methods.


  !* Translated from JOML. Original name: "translateGeneric"
  subroutine translate(this, x, y, z)
    use :: math_helpers, only: fma_f32_array_4
    implicit none

    class(mat4f), intent(inout) :: this
    real(c_float), intent(in), value :: x, y, z
    ! Cache.
    real(c_float), dimension(16) :: mat

    mat = this%data

    this%data = [ &
      mat(1:12), &
    ! Note: This is one nested call lol.
      fma_f32_array_4(mat(1:4),  spread(x, 1, 4), &
      fma_f32_array_4(mat(5:8),  spread(y, 1, 4), &
      fma_f32_array_4(mat(9:12), spread(z, 1, 4), mat(13:16)))) & ! Looking a bit like lisp at this point.
      ]
  end subroutine translate


  !* Translated from JOML. Original name: "translateGeneric"
  subroutine translate_vec3f(this, xyz)
    use :: math_helpers, only: fma_f32_array_4
    use :: vector_3f
    implicit none

    class(mat4f), intent(inout) :: this
    type(vec3f), intent(in), value :: xyz
    ! Cache.
    real(c_float), dimension(16) :: mat

    mat = this%data

    this%data = [ &
      mat(1:12), &
    ! Note: This is one nested call lol.
      fma_f32_array_4(mat(1:4),  spread(xyz%get_x(), 1, 4), &
      fma_f32_array_4(mat(5:8),  spread(xyz%get_y(), 1, 4), &
      fma_f32_array_4(mat(9:12), spread(xyz%get_z(), 1, 4), mat(13:16)))) & ! Looking a bit like lisp at this point.
      ]
  end subroutine translate_vec3f


  !* Translated from JOML. This method was called "rotateXInternal"
  subroutine rotate_x(this, angle_radians)
    use :: math_helpers, only: cos_from_sin_f32, fma_f32, fma_f32_array_4
    implicit none

    class(mat4f), intent(inout) :: this
    real(c_float), intent(in), value :: angle_radians
    real(c_float), dimension(3) :: translation
    real(c_float) :: sine, cosine
    ! Cache.
    real(c_float), dimension(16) :: mat

    !* Implementation note:
    !* Unlike JOML we will assume that this matrix has already been translated.
    !* Worst case scenario: We are redundantly assigning 0.0 values.
    !* This keeps the implementation lean and simple.

    mat = this%data

    ! Save translation.
    translation = this%get_translation_array()

    sine = sin(angle_radians)

    cosine = cos_from_sin_f32(sine, angle_radians)

    this%data = [ &
      mat(1:4), &
      fma_f32_array_4(mat(5:8), spread(cosine, 1, 4), mat(9:12) * sine), &
      fma_f32_array_4(mat(5:8), spread(-sine,  1, 4), mat(9:12) * cosine), &
      mat(13:16) &
      ]

    ! Finally, restore the translation.
    call this%set_translation_array(translation)
  end subroutine rotate_x


  !* Translated from JOML. This method was originally called: "rotateYInternal"
  subroutine rotate_y(this, angle_radians)
    use :: math_helpers, only: cos_from_sin_f32, fma_f32, fma_f32_array_4
    implicit none

    class(mat4f), intent(inout) :: this
    real(c_float), intent(in), value :: angle_radians
    real(c_float), dimension(3) :: translation
    real(c_float) :: sine, cosine
    ! Cache.
    real(c_float), dimension(16) :: mat

    !* Implementation note:
    !* Unlike JOML we will assume that this matrix has already been translated.
    !* Worst case scenario: We are redundantly assigning 0.0 values.
    !* This keeps the implementation lean and simple.

    mat = this%data

    ! Save translation.
    translation = this%get_translation_array()

    sine = sin(angle_radians)

    cosine = cos_from_sin_f32(sine, angle_radians)

    this%data = [ &
      fma_f32_array_4(mat(1:4), spread(cosine, 1, 4), mat(9:12) * (-sine)), &
      mat(5:8), &
      fma_f32_array_4(mat(1:4), spread(sine, 1, 4), mat(9:12) * cosine), &
      mat(13:16) &
      ]

    ! Finally, restore the translation.
    call this%set_translation_array(translation)
  end subroutine rotate_y


  !* Translated from JOML. Original names: ["rotateZInternal", rotateTowardsXY"]
  subroutine rotate_z(this, angle_radians)
    use :: math_helpers, only: cos_from_sin_f32, fma_f32, fma_f32_array_4
    implicit none

    class(mat4f), intent(inout) :: this
    real(c_float), intent(in), value :: angle_radians
    real(c_float), dimension(3) :: translation
    real(c_float) :: sine, cosine
    ! Cache.
    real(c_float), dimension(16) :: mat

    !* Implementation note:
    !* Unlike JOML we will assume that this matrix has already been translated.
    !* Worst case scenario: We are redundantly assigning 0.0 values.
    !* This keeps the implementation lean and simple.

    mat = this%data

    ! Save translation.
    translation = this%get_translation_array()

    sine = sin(angle_radians)

    cosine = cos_from_sin_f32(sine, angle_radians)

    this%data = [ &
      fma_f32_array_4(mat(1:4), spread(cosine, 1, 4), mat(5:8) * sine), &
      fma_f32_array_4(mat(1:4), spread(-sine,  1, 4), mat(5:8) * cosine), &
      mat(9:16) &
      ]

    ! Finally, restore the translation.
    call this%set_translation_array(translation)
  end subroutine rotate_z


  !! INTERNAL ONLY


  !* Get the translation of a matrix. Never externally use this. Never expose this.
  function get_translation_array(this) result(xyz)
    implicit none

    class(mat4f), intent(inout) :: this
    real(c_float), dimension(3) :: xyz

    xyz = this%data(13:15)
  end function get_translation_array


  !* Translated from JOML. This was originally called: "setTranslation". Never externally use this. Never expose this.
  subroutine set_translation_array(this, xyz)
    implicit none

    class(mat4f), intent(inout) :: this
    real(c_float), dimension(3), intent(in) :: xyz

    this%data(13:15) = xyz(1:3)
  end subroutine set_translation_array


end module matrix_4f
