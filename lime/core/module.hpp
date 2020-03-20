#ifndef MODULE_HPP
#define MODULE_HPP

#include <iostream>
#include <functional>
#include <boost/dll/shared_library.hpp>

namespace lime
{
namespace core
{
class module
{
public:
    module(){};
    virtual ~module(){};

public:
    void parse(std::string const &path)
    {
    }

    static bool load(std::string const &name)
    {
        boost::dll::shared_library lib;
        try
        {
            lib.load(name);
        }
        catch (std::exception const &)
        {
            std::cerr << "Insufficient memory when loading shared memory:" << name << std::endl;
        }
        if (!lib.is_loaded())
        {
            std::cerr << "Failed loading shared library:" << name << std::endl;
            return false;
        }
        try
        {
            // init = lib.get<void __stdcall()>("init");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function `init` in shared library:" << name << std::endl;
            return false;
        }
        try
        {
            // free = lib.get<void __stdcall()>("free");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function `free` in shared library:" << name << std::endl;
            return false;
        }
        try
        {
            // handle = lib.get<void __stdcall()>("handle");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function `handle` in shared library:" << name << std::endl;
            return false;
        }

        return true;
    }

public:
    std::function<void()> init;
    std::function<void()> free;
    std::function<void(void *)> handle;
};     // namespace core
};     // namespace core
};     // namespace lime
#endif // !SERVICE_HPP