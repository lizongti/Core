#ifndef ANTS_CORE_UTIL_HPP
#define ANTS_CORE_UTIL_HPP

class Util
{
public:
    static std::string shared_library_suffix()
    {
        if (BOOST_PLATFORM == "Win32" || BOOST_PLATFORM == "Win64")
        {
            return ".dll";
        }
        else if (BOOST_PLATFORM == "linux")
        {
            return ".so";
        }
        else if (BOOST_PLATFORM == "macos")
        {
            return ".dylib";
        }
        else
        {
            return "";
        }
    }
};

#endif // ANTS_CORE_UTIL_HPP