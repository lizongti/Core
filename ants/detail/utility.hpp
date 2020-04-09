#ifndef ANTS_DETAIL_UTIL_HPP
#define ANTS_DETAIL_UTIL_HPP
namespace ants
{
namespace detail
{
class utility
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
};     // namespace detail
};     // namespace ants
#endif // ANTS_DETAIL_UTIL_HPP