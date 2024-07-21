!** This module kind of works like a state machine.
module mesh
  use string
  implicit none

  private

  public :: create_mesh

contains

  subroutine create_mesh
    use shader
    use opengl
    use string
    use terminal
    implicit none
    ! Notes:
    ! 1. break this up into functions.
    ! 2. make a type for a mesh.
    ! 3. make this handle mesh things.
    ! 4. improve, somehow.

    integer :: vao
    integer :: vbo_position
    integer :: vbo_color

    print"(A)",colorize_rgb("[Mesh] WARNING: SHADER MODULE NEEDS A STATE MACHINE!", 255,128,0)

    ! Into vertex array object.

    vao = gl_gen_vertex_arrays()

    print"(A)","vao: ["//int_to_string(vao)//"]"

    call gl_bind_vertex_array(vao)

    ! Into position vertex buffer object.

    vbo_position = upload_positions([ &
      0.0, 0.0, 0.0, &
      10.0, 0.0, 0.0, &
      10.0, 0.0, 10.0 &
      ])

    vbo_color = upload_colors([ &
      1.0, 0.0, 0.0, &
      0.0, 1.0, 0.0, &
      0.0, 0.0, 1.0 &
      ])

    ! Now unbind vertex array object.
    call gl_bind_vertex_array(0)

  end subroutine create_mesh


  integer function upload_positions(position_array) result(vbo_position)
    use, intrinsic :: iso_c_binding
    use opengl
    use shader
    implicit none

    real(c_float), dimension(:), intent(in) :: position_array


    ! Create the VBO context.
    vbo_position = gl_gen_buffers()

    print"(A)","vbo position: ["//int_to_string(vbo_position)//"]"

    ! Walk into the VBO context.
    call gl_bind_buffer(GL_ARRAY_BUFFER, vbo_position)

    ! Pass this data into the OpenGL state machine.
    call gl_buffer_float_array(position_array)

    ! Width = 3 because this is a vec3
    ! false because this is not normalized
    ! 0 stride
    call gl_vertex_attrib_pointer(shader_get_attribute("main", "position"), 3, GL_FLOAT, .false., 0)

    ! Enable this new data.
    call gl_enable_vertex_attrib_array(shader_get_attribute("main", "position"))

    ! Now unbind.
    call gl_bind_buffer(GL_ARRAY_BUFFER, 0)

  end function upload_positions


  integer function upload_colors(color_array) result(vbo_position)
    use, intrinsic :: iso_c_binding
    use opengl
    use shader
    implicit none

    real(c_float), dimension(:), intent(in) :: color_array

    ! Create the VBO context.
    vbo_position = gl_gen_buffers()

    print"(A)","vbo color: ["//int_to_string(vbo_position)//"]"

    ! Walk into the VBO context.
    call gl_bind_buffer(GL_ARRAY_BUFFER, vbo_position)

    ! Pass this data into the OpenGL state machine.
    call gl_buffer_float_array(color_array)

    ! Width = 3 because this is a vec3
    ! false because this is not normalized
    ! 0 stride
    call gl_vertex_attrib_pointer(shader_get_attribute("main", "color"), 3, GL_FLOAT, .false., 0)

    ! Enable this new data.
    call gl_enable_vertex_attrib_array(shader_get_attribute("main", "color"))

    ! Now unbind.
    call gl_bind_buffer(GL_ARRAY_BUFFER, 0)

  end function upload_colors


end module mesh
