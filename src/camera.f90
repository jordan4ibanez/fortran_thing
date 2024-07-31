module camera
  use :: matrix_4f
  use :: vector_3f
  use :: vector_3d
  use :: math_helpers, only: into_f32
  use, intrinsic :: iso_c_binding, only: c_float, c_double
  implicit none

  private

  public :: camera_update
  public :: camera_set_position
  public :: camera_set_position_vec3d


  real(c_float), parameter :: MIN_FOV = 50.0
  real(c_float), parameter :: MAX_FOV = 120.0

  real(c_float) :: fov_degrees = 72.0

  !? On the stack, for now. Uses 64 bytes. I don't feel like listing the rest of the sizes.
  type(mat4f) :: camera_matrix

  !? Position is not translation, translation is the inverse of position!
  type(vec3d) :: camera_position
  type(vec3d) :: camera_rotation
  ! Camera is always at scale 1, 1, 1.

  !? Object related components.
  type(mat4f) :: object_matrix

contains


  subroutine camera_set_position(x, y, z)
    implicit none

    real(c_double), intent(in), value :: x, y, z

    camera_position%x = x
    camera_position%y = y
    camera_position%z = z
  end subroutine camera_set_position


  subroutine camera_set_position_vec3d(new_position)
    implicit none

    type(vec3d), intent(in) :: new_position

    camera_position = new_position
  end subroutine camera_set_position_vec3d


  subroutine camera_update()
    use :: glfw, only: glfw_get_aspect_ratio
    use :: delta
    use :: math_helpers, only: to_radians_f32

    implicit none

    !* So the trick is, the camera actually never moves, but the world moves around it.
    !* This maintains as much precision as possible where you can see it.

    call camera_matrix%identity()

    call camera_matrix%perspective(to_radians_f32(fov_degrees), glfw_get_aspect_ratio(), 0.01, 100.0)

    call camera_matrix%rotate_x(camera_rotation%x_f32())
    call camera_matrix%rotate_y(camera_rotation%y_f32())
    call camera_matrix%rotate_z(camera_rotation%z_f32())

    call upload_camera_matrix_into_shader()
  end subroutine camera_update


  subroutine upload_camera_matrix_into_shader()
    use :: opengl
    use :: shader
    implicit none

    call gl_uniform_mat4f(shader_get_uniform("main", "camera_matrix"), camera_matrix)
  end subroutine upload_camera_matrix_into_shader


end module camera
