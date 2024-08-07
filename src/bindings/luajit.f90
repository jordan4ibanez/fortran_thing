module luajit
  use, intrinsic :: iso_c_binding
  implicit none


  private

  !* Why yes, I did have to read the way too much documentation to do this.
  ! References:
  ! https://lucasklassmann.com/blog/2019-02-02-embedding-lua-in-c/
  ! https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lua.h#L43
  ! https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/luajit.c
  ! And I pretty much have to search through the LuaJIT source code for anything else.

  public :: luajit_initialize
  public :: luajit_destroy


  integer(c_int), parameter :: LUA_OK = 0
  integer(c_int), parameter :: LUA_YIELD = 1
  integer(c_int), parameter :: LUA_ERRRUN = 2
  integer(c_int), parameter :: LUA_ERRSYNTAX = 3
  integer(c_int), parameter :: LUA_ERRMEM = 4
  integer(c_int), parameter :: LUA_ERRERR = 5


  type(c_ptr) :: lua_state


  interface


    function lual_newstate() result(new_state) bind(c, name = "luaL_newstate")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr) :: new_state
    end function lual_newstate


    !* This makes the LuaJIT standard library available.
    subroutine lual_openlibs(state) bind(c, name = "luaL_openlibs")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
    end subroutine lual_openlibs


    subroutine lua_close(state) bind(c, name = "lua_close")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
    end subroutine lua_close

    function lual_loadstring(state, string) result(status) bind(c, name = "luaL_loadstring")
      use, intrinsic :: iso_c_binding
      implicit none

      type(c_ptr), intent(in), value :: state
      character(kind = c_char), intent(in) :: string
      integer(c_int) :: status
    end function lual_loadstring

  end interface


contains


  !* Create the actual LuaJIT state that we will use.
  subroutine luajit_initialize()
    implicit none

    if (c_associated(lua_state)) then
      error stop "[LuaJIT] Error: Tried to initialize LuaJIT when already initialized."
    end if

    lua_state = lual_newstate()

    if (.not. c_associated(lua_state)) then
      error stop "[LuaJIT] Error: Failed to initialize."
    end if

    ! Make the entire standard library available.
    !! Is this safe for the end user when using external mods? HELL NO.
    call lual_openlibs(lua_state)
  end subroutine luajit_initialize


  !* Clean up the memory used by LuaJIT and destroy it.
  subroutine luajit_destroy()
    implicit none

    if (.not. c_associated(lua_state)) then
      error stop "[LuaJIT] Error: Tried to destroy LuaJIT when not initialized."
    end if

    call lua_close(lua_state)
  end subroutine luajit_destroy


  subroutine luajit_run_string(string_to_run)
    use :: string
    implicit none

    character(len = *), intent(in) :: string_to_run
    character(len = :, kind = c_char), allocatable :: c_string

    c_string = into_c_string(string_to_run)

    if (lual_loadstring(lua_state, c_string) == LUA_OK) then
      print*,"yay"
    end if
  end subroutine luajit_run_string


end module luajit
