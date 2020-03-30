#ifndef ANTS_CORE_MODULE_HPP
#define ANTS_CORE_MODULE_HPP

#include <iostream>
#include <functional>
#include <boost/dll/shared_library.hpp>
#include <ants/core/singleton.hpp>

namespace ants
{
namespace core
{
class module
{
public:
    module(){};
    virtual ~module(){};

public:
    bool load(std::string const &name)
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
            init = lib.get<void __cdecl(void)>("init");
            // std::cout << reinterpret_cast<void *>(init) << std::endl;
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'init' in shared library:" << name << std::endl;
            return false;
        }

        try
        {
            work = lib.get<void __cdecl(void *)>("work");
            // std::cout << reinterpret_cast<void *>(work) << std::endl;
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'work' in shared library:" << name << std::endl;
            return false;
        }

        try
        {
            fini = lib.get<void __cdecl(void)>("fini");
            // std::cout << reinterpret_cast<void *>(fini) << std::endl;
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'fini' in shared library:" << name << std::endl;
            return false;
        }

        return true;
    }

    bool unload(std::string const &name)
    {
    }

public:
    std::function<void __cdecl(void)> init;
    std::function<void __cdecl(void *)> work;
    std::function<void __cdecl(void)> fini;
};
};     // namespace core
};     // namespace ants
#endif // ANTS_CORE_SERVICE_HPP