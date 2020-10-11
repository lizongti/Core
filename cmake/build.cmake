
include(compiler)
include(os)

use_function_call_convention(__cdecl)
use_c_standard(99)
use_cxx_standard(17)
set_c_flags()
set_cxx_flags()

if(WINDOWS)
    msvc_export_all_symbols()
    msvc_link(MD)
endif()