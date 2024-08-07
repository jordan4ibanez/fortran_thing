module font
  use, intrinsic :: iso_c_binding
  use :: fhash, only: fhash_tbl_t, key => fhash_key
  use :: vector_2d
  implicit none

  !* I am a solo developer. I only use 1 font.
  !* In the future, if there is a desire for more than one font,
  !* we will build upon this.

  private


  public :: font_create
  public :: font_generate_text
  public :: font_clear_database


  ! This is a container which holds the points on the texture that make the character appear correctly.
  type opengl_character
    ! We use this for constructing the quad to match the size of the texture mapping.
    integer(c_int) :: width_pixels = 0
    real(c_double) :: width_real = 0.0d0
    ! Counter clock-wise.
    type(vec2d) :: top_left
    type(vec2d) :: bottom_left
    type(vec2d) :: bottom_right
    type(vec2d) :: top_right
  end type opengl_character

  ! This is an abstraction over the raw array components to allow me to actually
  ! read what I'm doing during the subroutine that checks how wide characters are.
  type rgba
    integer(c_int) :: r = 0
    integer(c_int) :: g = 0
    integer(c_int) :: b = 0
    integer(c_int) :: a = 0
  end type rgba


  ! The size of each character in pixels.
  integer :: character_width = 0
  integer :: character_height = 0

  ! Spacing between each character in pixels.
  integer :: spacing = 0

  ! Slots are the total size of a character, including the border, in pixels.
  integer :: slot_width = 0
  integer :: slot_height = 0

  ! How many characters X and Y in total.
  integer :: slots_horizontal = 0
  integer :: slots_vertical = 0

  integer :: font_texture_width = 0
  integer :: font_texture_height = 0

  type(fhash_tbl_t) :: character_database

contains


  !* Generate a text mesh.
  subroutine font_generate_text(mesh_name, font_size, text, r,g,b, center, size)
    use :: mesh
    use :: string, only: string_get_non_space_characters
    use :: vector_2f
    implicit none

    character(len = *), intent(in) :: mesh_name, text
    real(c_float), intent(in), value :: font_size
    real(c_float), intent(in), optional :: r,g,b
    logical, intent(in), optional :: center
    type(vec2f), intent(inout), optional :: size
    logical :: should_center
    real(c_float) :: red, green, blue
    real(c_float), dimension(:), allocatable :: positions, texture_coordinates, colors
    integer(c_int), dimension(:), allocatable :: indices
    integer :: text_length, allocation_length, i, buffer_index, current_positions_offset, current_texture_coordinates_offset, current_colors_offset, current_indices_offset, current_indices_index
    character :: current_character
    type(opengl_character), pointer :: character_data_pointer
    logical :: exists
    real(c_float) :: current_scroll_right, actual_character_width, centering_offset
    integer, parameter :: points = 4
    real(c_float), parameter :: space_width = 0.4
    integer, parameter :: dimensions = 2
    integer, parameter :: stride = dimensions * points

    if (.not. present(r)) then
      red = 0.0
    else
      red = r
    end if

    if (.not. present(g)) then
      green = 0.0
    else
      green = g
    end if

    if (.not. present(b)) then
      blue = 0.0
    else
      blue = b
    end if

    if (.not. present(center)) then
      should_center = .false.
    else
      should_center = center
    end if

    current_scroll_right = 0.0

    text_length = len(text)
    allocation_length = string_get_non_space_characters(text)

    ! todo: change this to 2 positions!
    ! 4 quads per character. 3 positions per point. This can probably be optimized, somehow.
    allocate(positions(allocation_length * stride))
    ! todo: use offset intead of 4 * 2
    allocate(texture_coordinates(allocation_length * 8))
    allocate(colors(allocation_length * 12))
    allocate(indices(allocation_length * 6))

    ! With spaces, this desynchronizes. We must stop it from trying to reach outside the buffer.
    buffer_index = 0

    do i = 1,text_length

      current_character = text(i:i)

      if (current_character == " ") then
        current_scroll_right = current_scroll_right + (font_size * space_width)
        cycle
      end if

      buffer_index = buffer_index + 1

      character_data_pointer => get_character(current_character, exists)

      ! For now, we're just going to skip characters that don't exist.
      ! todo: use a special character that is a square box or something as a replacement.
      if (exists) then

        ! Positions.
        current_positions_offset = ((buffer_index - 1) * stride) + 1
        actual_character_width = real(character_data_pointer%width_real, kind = c_float) * font_size

        positions(current_positions_offset    ) = current_scroll_right
        positions(current_positions_offset + 1) = font_size

        positions(current_positions_offset + 2) = current_scroll_right
        positions(current_positions_offset + 3) = 0.0

        positions(current_positions_offset + 4) = current_scroll_right + actual_character_width
        positions(current_positions_offset + 5) = 0.0

        positions(current_positions_offset + 6) = current_scroll_right + actual_character_width
        positions(current_positions_offset + 7) = font_size

        current_scroll_right = current_scroll_right + actual_character_width + (font_size * 0.1)

        ! Texture coordinates.

        current_texture_coordinates_offset = ((buffer_index - 1) * 8) + 1
        texture_coordinates(current_texture_coordinates_offset    ) = character_data_pointer%top_left%x_f32()
        texture_coordinates(current_texture_coordinates_offset + 1) = character_data_pointer%top_left%y_f32()
        texture_coordinates(current_texture_coordinates_offset + 2) = character_data_pointer%bottom_left%x_f32()
        texture_coordinates(current_texture_coordinates_offset + 3) = character_data_pointer%bottom_left%y_f32()
        texture_coordinates(current_texture_coordinates_offset + 4) = character_data_pointer%bottom_right%x_f32()
        texture_coordinates(current_texture_coordinates_offset + 5) = character_data_pointer%bottom_right%y_f32()
        texture_coordinates(current_texture_coordinates_offset + 6) = character_data_pointer%top_right%x_f32()
        texture_coordinates(current_texture_coordinates_offset + 7) = character_data_pointer%top_right%y_f32()

        ! Colors.
        current_colors_offset = ((buffer_index - 1) * 12) + 1
        colors(current_colors_offset    ) = red
        colors(current_colors_offset + 1) = green
        colors(current_colors_offset + 2) = blue

        colors(current_colors_offset + 3) = red
        colors(current_colors_offset + 4) = green
        colors(current_colors_offset + 5) = blue

        colors(current_colors_offset + 6) = red
        colors(current_colors_offset + 7) = green
        colors(current_colors_offset + 8) = blue

        colors(current_colors_offset + 9) = red
        colors(current_colors_offset + 10) = green
        colors(current_colors_offset + 11) = blue

        ! Indices.
        current_indices_offset = ((buffer_index - 1) * 6) + 1
        current_indices_index = (buffer_index - 1) * 4

        indices(current_indices_offset    ) = 0 + current_indices_index
        indices(current_indices_offset + 1) = 1 + current_indices_index
        indices(current_indices_offset + 2) = 2 + current_indices_index
        indices(current_indices_offset + 3) = 2 + current_indices_index
        indices(current_indices_offset + 4) = 3 + current_indices_index
        indices(current_indices_offset + 5) = 0 + current_indices_index
      end if
    end do

    if (present(size)) then
      size%x = (current_scroll_right - (font_size * 0.1))
      size%y = font_size
    end if

    if (should_center) then
      do i = 1,allocation_length
        current_positions_offset = ((i - 1) * stride) + 1

        centering_offset = (current_scroll_right - (font_size * 0.1)) * 0.5

        positions(current_positions_offset    ) = positions(current_positions_offset    ) - centering_offset
        positions(current_positions_offset + 2) = positions(current_positions_offset + 2) - centering_offset
        positions(current_positions_offset + 4) = positions(current_positions_offset + 4) - centering_offset
        positions(current_positions_offset + 6) = positions(current_positions_offset + 6) - centering_offset
      end do
    end if

    call mesh_create_2d(mesh_name, positions, texture_coordinates, colors, indices)
  end subroutine font_generate_text


  !* Get a character's OpenGL data.
  function get_character(char, exists) result(gl_char_information_pointer)
    use :: terminal
    implicit none

    character, intent(in) :: char
    logical, intent(inout) :: exists
    type(opengl_character), pointer :: gl_char_information_pointer
    class(*), pointer :: generic_pointer
    integer :: status

    exists = .false.

    call character_database%get_raw_ptr(key(char), generic_pointer, stat = status)

    ! We will have a special handler to use a generic character for characters that aren't registered.
    if (status /= 0) then
      return
    end if

    select type(generic_pointer)
     type is (opengl_character)
      exists = .true.
      gl_char_information_pointer => generic_pointer
     class default
      error stop colorize_rgb("[Font] Error: Character ["//char//"] has the wrong type.", 255, 0, 0)
    end select
  end function get_character


  !* Create a font from a png and a config using one file path.
  !* It will be assumed that the only difference between the texture and the
  !* config file will be the file extension.
  subroutine font_create(font_texture_file_path)
    use :: stb_image
    use :: string
    use :: files
    use :: texture
    implicit none

    character(len = *, kind = c_char), intent(in) :: font_texture_file_path
    integer :: x, y, channels, desired_channels
    character(len = :, kind = c_char), allocatable :: c_file_path
    character(len = :), allocatable :: font_data_file_name
    character(len = :), allocatable :: font_config_file_path
    integer(1), dimension(:), allocatable :: raw_image_data
    type(fhash_tbl_t) :: character_database_integral

    ! print*,"    REMEMBER TO USE A SPARE SLOT FOR UNDEFINED CHARACTERS"

    !* We will assume that the only difference in png and the cfg is the file extension.

    font_data_file_name = get_file_name_from_string(font_texture_file_path)
    font_config_file_path = string_remove_file_extension(font_texture_file_path)//".cfg"

    ! This is quite a large and complex subroutine. It's getting all the data from the .cfg file.
    call process_font_configuration(font_config_file_path, character_database_integral)

    ! Now load up the font.
    c_file_path = into_c_string(font_texture_file_path)

    ! We always want 4 channels.
    desired_channels = 4

    raw_image_data = stbi_load(c_file_path, x, y, channels, desired_channels)

    ! Let's check if the configuration file is correct.
    if (x /= font_texture_width) then
      error stop "[Font] Error: Font sizing in configuration file is wrong on X axis. Expected: ["//int_to_string(font_texture_width)//"] | received: ["//int_to_string(x)//"]"
    else if (y /= font_texture_height) then
      error stop "[Font] Error: Font sizing in configuration file is wrong on Y axis. Expected: ["//int_to_string(font_texture_height)//"] | received: ["//int_to_string(y)//"]"
    end if

    ! Now, we will bake in the OpenGL texture coordinates into the double floating point database.
    call calculate_opengl_texture_coordinates(raw_image_data, character_database_integral)

    ! Then we can finally upload it into the texture database.
    call texture_create_from_memory("font", raw_image_data, x, y)
  end subroutine font_create


  !* Very simple configuration file processing.
  subroutine process_font_configuration(font_config_file_path, character_database_integral)
    use :: string
    use :: files
    use :: vector_2i
    implicit none

    character(len = *, kind = c_char), intent(in) :: font_config_file_path
    type(fhash_tbl_t), intent(inout) :: character_database_integral
    type(file_reader) :: reader
    integer :: i, temp_buffer_length, comma_index, x_index, y_index
    character(len = :), allocatable :: temp_buffer
    character :: current_character
    character(len = :), allocatable :: x_str, y_str


    call reader%read_lines(font_config_file_path)

    ! If it doesn't exist, we need a font to render text so stop.
    if (.not. reader%exists) then
      error stop "[Font] Error: Cannot read the font config in file path ["//font_config_file_path//"]"
    end if

    do i = 1,reader%line_count
      temp_buffer = reader%lines(i)%get()

      ! This is a real sloppy way to do this but who cares?
      temp_buffer_length = len(temp_buffer)

      if (temp_buffer_length <= 0) then
        cycle
      end if

      ! We want to avoid a buffer overflow.
      if (temp_buffer_length >= 19 .and. temp_buffer(1:19) == "SLOTS_HORIZONTAL = ") then
        ! Cut the buffer and read it into the integer.
        temp_buffer = temp_buffer(19:len(temp_buffer))
        read(temp_buffer, '(i4)') slots_horizontal
        if (slots_horizontal <= 0) then
          error stop "[Font] Error: Impossible SLOTS_HORIZONTAL value on line ["//int_to_string(i)//"] of font config ["//font_config_file_path//"]"
        end if

      else if (temp_buffer_length >= 17 .and. temp_buffer(1:17) == "SLOTS_VERTICAL = ") then
        ! Cut the buffer and read it into the integer.
        temp_buffer = temp_buffer(17:len(temp_buffer))
        read(temp_buffer, '(i4)') slots_vertical
        if (slots_vertical <= 0) then
          error stop "[Font] Error: Impossible SLOTS_VERTICAL value on line ["//int_to_string(i)//"] of font config ["//font_config_file_path//"]"
        end if

      else if (temp_buffer_length >= 10 .and. temp_buffer(1:10) == "SPACING = ") then
        ! Cut the buffer and read it into the integer.
        temp_buffer = temp_buffer(10:len(temp_buffer))
        read(temp_buffer, '(i4)') spacing
        if (spacing <= 0) then
          error stop "[Font] Error: Impossible SPACING value on line ["//int_to_string(i)//"] of font config ["//font_config_file_path//"]"
        end if

      else if (temp_buffer_length >= 13 .and. temp_buffer(1:13) == "CHAR_WIDTH = ") then
        ! Cut the buffer and read it into the integer.
        temp_buffer = temp_buffer(13:len(temp_buffer))
        read(temp_buffer, '(i4)') character_width
        if (character_width <= 0) then
          error stop "[Font] Error: Impossible CHAR_WIDTH value on line ["//int_to_string(i)//"] of font config ["//font_config_file_path//"]"
        end if

      else if (temp_buffer_length >= 14 .and. temp_buffer(1:14) == "CHAR_HEIGHT = ") then
        ! Cut the buffer and read it into the integer.
        temp_buffer = temp_buffer(14:len(temp_buffer))
        read(temp_buffer, '(i4)') character_height
        if (character_height <= 0) then
          error stop "[Font] Error: Impossible CHAR_HEIGHT value on line ["//int_to_string(i)//"] of font config ["//font_config_file_path//"]"
        end if

      else if (temp_buffer_length >= 7) then
        ! This is a real rigid way to do this.
        ! This is basically, it has to be formatted like:
        ! [A = ]
        ! Minus the brackets.
        if (temp_buffer(1:1) /= " " .and. temp_buffer(2:4) == " = ") then
          ! print*,temp_buffer
          current_character = temp_buffer(1:1)
          ! print*,current_character

          ! Now we're going to cut the temp buffer.
          temp_buffer = temp_buffer(5:len(temp_buffer))

          ! Now we're going to chop up the X and Y out of the line.
          comma_index = index(temp_buffer, ",")

          ! There is a formatting error.
          if (comma_index <= 0) then
            error stop "[Font] Error: There is a missing comma on line ["//int_to_string(i)//"] of font config ["//font_config_file_path//"]"
          end if

          ! Get the X into an integer.
          x_str = temp_buffer(1:comma_index - 1)
          read(x_str, '(i4)') x_index
          if (x_index <= 0) then
            error stop "[Font] Error: Impossible X value on line ["//int_to_string(i)//"] of font config ["//font_config_file_path//"]"
          end if

          ! Get the Y into an integer.
          y_str = temp_buffer(comma_index + 1:len(temp_buffer))
          read(y_str, '(i4)') y_index
          if (y_index <= 0) then
            error stop "[Font] Error: Impossible Y value on line ["//int_to_string(i)//"] of font config ["//font_config_file_path//"]"
          end if

          ! Now finally, dump the integral position into the database.
          call character_database_integral%set(key(current_character), vec2i(x_index, y_index))
        end if
      end if
    end do

    ! Check everything to make sure nothing blew up.
    if (slots_horizontal <= 0) then
      error stop "[Font] Error: SLOTS_HORIZONTAL was not set."
    else if (slots_vertical <= 0) then
      error stop "[Font] Error: SLOTS_VERTICAL was not set."
    else if (character_width <= 0) then
      error stop "[Font] Error: CHAR_WIDTH was not set."
    else if (character_height <= 0) then
      error stop "[Font] Error: CHAR_HEIGHT was not set."
    else if (spacing <= 0) then
      error stop "[Font] Error: SPACING was not set."
    end if

    ! Finally, set the slot sizes.
    slot_width = character_width + spacing
    slot_height = character_height + spacing

    ! Check that as well because this subroutine is already huge.
    if (slot_width <= 0) then
      error stop "[Font] Error: slot_width calculation error."
    else if (slot_height <= 0) then
      error stop "[Font] Error: slot_height calculation error."
    end if

    ! Now we need a base to ensure that our texture size is the same as our calculation
    font_texture_width = slot_width * slots_horizontal
    font_texture_height = slot_height * slots_vertical
  end subroutine process_font_configuration


  !* Automates converting the pixel positions into OpenGL texture mapping positions.
  subroutine calculate_opengl_texture_coordinates(raw_image_data, character_database_integral)
    use :: math_helpers
    use, intrinsic :: iso_c_binding
    use :: fhash, only: fhash_iter_t, fhash_key_t
    use :: vector_2i
    implicit none

    integer(1), dimension(:), intent(in) :: raw_image_data
    type(fhash_tbl_t), intent(in) :: character_database_integral
    integer(c_int), dimension(:), allocatable :: integral_image_data
    type(fhash_iter_t) :: iterator
    class(fhash_key_t), allocatable :: generic_key
    class(*), allocatable :: generic_data
    type(vec2i) :: position
    integer :: pixel_x, pixel_y
    type(opengl_character), pointer :: gpu_character

    ! Shift this into a format we can use.
    integral_image_data = c_uchar_to_int_array(raw_image_data)

    ! Iterate integral character position.
    iterator = fhash_iter_t(character_database_integral)
    do while(iterator%next(generic_key, generic_data))

      ! Enforce that we are running with a vec2i.
      select type(generic_data)
       type is (vec2i)
        position = generic_data
       class default
        error stop "[Font] Error: The wrong type got inserted for character ["//generic_key%to_string()//"]"
      end select

      ! So now that we have the position of the character in the texture, let's calculate some basic elements.
      ! I could have made this an array for super speed, but I want to be able to understand it in the future.
      allocate(gpu_character)

      ! We put our initial brush position at the top left of the character.
      pixel_x = ((position%x - 1) * slot_width) + 1
      pixel_y = ((position%y - 1) * slot_height) + 1

      ! Assign the widths.
      gpu_character%width_pixels = find_pixel_width(pixel_x, pixel_y)
      gpu_character%width_real = convert_pixel_width_to_real_width(gpu_character%width_pixels)

      ! Now assign the quad texture positions.
      gpu_character%top_left = pixel_position_to_opengl_position(pixel_x, pixel_y)
      gpu_character%bottom_left = pixel_position_to_opengl_position(pixel_x, pixel_y + character_height)
      gpu_character%bottom_right = pixel_position_to_opengl_position(pixel_x + gpu_character%width_pixels, pixel_y + character_height)
      gpu_character%top_right = pixel_position_to_opengl_position(pixel_x + gpu_character%width_pixels, pixel_y)

      ! Finally, we can assign this character into the database.
      call character_database%set_ptr(key(generic_key%to_string()), gpu_character)
    end do


  contains


    !* We need to do such complex work we need this subroutine to have functions.


    !* Convert the integral pixel width into double floating precision with range 0.0 - 1.0.
    function convert_pixel_width_to_real_width(input_width) result(real_width)
      implicit none

      integer(c_int), intent(in), value :: input_width
      real(c_double) :: real_width

      !! +1 and slot width cause I have no idea. It just looks more correct with it set like this.
      real_width = real(input_width, kind = c_double) / real(slot_width + 1, kind = c_double)
    end function convert_pixel_width_to_real_width


    !* Find how wide a character is by scanning it.
    function find_pixel_width(starting_x, starting_y) result(pixel_width)
      implicit none

      integer(c_int), intent(in), value :: starting_x, starting_y
      integer(c_int) :: scan_x, scan_y
      integer(c_int) :: pixel_width
      type(rgba) :: pixel_color

      ! Vertical scan, by row, right to left, until we hit something.
      scanner: do scan_x = starting_x + character_width - 1, starting_x, - 1
        do scan_y = starting_y + character_height - 1, starting_y, - 1
          pixel_color = get_color(scan_x, scan_y)
          if (pixel_color%r + pixel_color%g + pixel_color%b + pixel_color%a > 0) then
            pixel_width = (scan_x - starting_x) + 1
            exit scanner
          end if
        end do
      end do scanner
    end function find_pixel_width


    !* Convert the pixel position into the OpenGL floating texture map position.
    !* Pixel position is the top left of a pixel viewed in GIMP.
    function pixel_position_to_opengl_position(x,y) result(pos)
      implicit none

      integer(c_int), intent(in), value :: x, y
      type(vec2d) :: pos
      real(c_double) :: x_f64, y_f64, canvas_width_f64, canvas_height_f64

      ! We want the top left of the pixel. Shift into 0 indexed.
      x_f64 = real(x - 1, kind = c_double)
      y_f64 = real(y - 1, kind = c_double)

      canvas_width_f64 = real(font_texture_width, kind = c_double)
      canvas_height_f64 = real(font_texture_height, kind = c_double)

      ! A 0.0 - 1.0 range is the goal.
      pos = vec2d(x_f64 / canvas_width_f64, y_f64 / canvas_height_f64)
    end function pixel_position_to_opengl_position


    !* This wraps a chain of functions to just get the data we need, which is RGBA of a pixel.
    function get_color(x,y) result(color)
      implicit none

      integer(c_int), intent(in), value :: x, y
      type(rgba) :: color

      color = index_get_color(position_to_index(x,y))
    end function get_color


    !* Position (in pixels) to the index in the texture array.
    function position_to_index(x, y) result(i)
      implicit none

      integer(c_int), intent(in), value :: x, y
      integer(c_int) :: a, b
      integer(c_int) :: i

      ! Shift into 0 indexed, because math.
      a = x - 1
      b = y - 1

      ! Times 4 because we have 4 individual channels we're hopping over.
      ! Plus 1 because we're shifting back into 1 indexed.
      i = (((b * font_texture_width) + a) * 4) + 1
    end function position_to_index


    !* Get the RGBA of an index.
    function index_get_color(index) result(color)
      implicit none

      integer(c_int), intent(in), value :: index
      type(rgba) :: color

      color%r = integral_image_data(index)
      color%g = integral_image_data(index + 1)
      color%b = integral_image_data(index + 2)
      color%a = integral_image_data(index + 3)
    end function index_get_color
  end subroutine calculate_opengl_texture_coordinates


  !* Completely wipe out all existing font characters. This might be slow.
  subroutine font_clear_database()
    use :: fhash, only: fhash_iter_t, fhash_key_t
    use :: string
    use :: terminal
    implicit none

    type(heap_string), dimension(:), allocatable :: key_array
    type(fhash_iter_t) :: iterator
    class(fhash_key_t), allocatable :: generic_key
    class(*), allocatable :: generic_data
    class(*), pointer :: generic_pointer
    integer :: i
    integer :: remaining_size

    !* We must check that there is anything in the database before we iterate.
    call character_database%stats(num_items = remaining_size)
    if (remaining_size == 0) then
      print"(A)", "[Font]: Database was empty. Nothing to do. Success!"
      return
    end if

    ! Start with a size of 0.
    allocate(key_array(0))

    ! Create the iterator.
    iterator = fhash_iter_t(character_database)

    ! Now we will collect the keys from the iterator.
    do while(iterator%next(generic_key, generic_data))
      ! Appending. Allocatable will clean up the old data.
      key_array = [key_array, heap_string_array(generic_key%to_string())]
    end do

    ! Now clear the database out.
    do i = 1,size(key_array)
      !* We are manually managing memory, we must free as we go.
      call character_database%get_raw_ptr(key(key_array(i)%get()), generic_pointer)
      deallocate(generic_pointer)

      call character_database%unset(key(key_array(i)%get()))
    end do

    !* We will always check that the remaining size is 0. This will protect us from random issues.
    call character_database%stats(num_items = remaining_size)

    if (remaining_size /= 0) then
      print"(A)", colorize_rgb("[Font] Error: Did not delete all characters! Expected size: [0] | Actual: ["//int_to_string(remaining_size)//"]", 255, 0, 0)
    else
      print"(A)", "[Font]: Successfully cleared the character database."
    end if
  end subroutine font_clear_database


end module font
