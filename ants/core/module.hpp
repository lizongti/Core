#ifndef ANTS_CORE_MODULE_HPP
#define ANTS_CORE_MODULE_HPP

#include <iostream>
#include <functional>
#include <mutex>
#include <unordered_map>
#include <boost/dll/shared_library.hpp>
#include <ants/core/singleton.hpp>

namespace ants
{
namespace core
{

struct module
{
    std::string name;
    std::string path;
    boost::dll::shared_library shared_library;
    std::function<void __cdecl(void)> init;
    std::function<void __cdecl(void *)> work;
    std::function<void __cdecl(void)> fini;
};

class module_loader
    : public singleton<module_loader>
{
public:
    bool load(std::string const &name)
    {
        std::lock_guard<std::mutex> lock_guard(instance().mutex);
        auto &module_hash_map = instance().module_hash_map;
        if (module_hash_map.find(name) != module_hash_map.end())
            return true;

        auto module = std::shared_ptr<ants::core::module>(new ants::core::module());
        module_hash_map[name] = module;
        try
        {
            module->shared_library.load(name);
        }
        catch (std::exception const &)
        {
            std::cerr << "Insufficient memory when loading shared memory:" << name << std::endl;
        }

        if (!module->shared_library.is_loaded())
        {
            std::cerr << "Failed loading shared library:" << name << std::endl;
            return false;
        }

        try
        {
            module->init = module->shared_library.get<void __cdecl(void)>("init");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'init' in shared library:" << name << std::endl;
            return false;
        }

        try
        {
            module->work = module->shared_library.get<void __cdecl(void *)>("work");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'work' in shared library:" << name << std::endl;
            return false;
        }

        try
        {
            module->fini = module->shared_library.get<void __cdecl(void)>("fini");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'fini' in shared library:" << name << std::endl;
            return false;
        }

        return true;
    }

    static bool unload(std::string const &name)
    {
        std::lock_guard<std::mutex> lock_guard(instance().mutex);
        auto &module_hash_map = instance().module_hash_map;
        if (module_hash_map.find(name) == module_hash_map.end())
            return true;

        try
        {
            module_hash_map[name]->shared_library.unload();
            module_hash_map.erase(name);
        }
        catch (std::exception const &)
        {
            std::cerr << "Shared library unload failed:" << name << std::endl;
            return false;
        }
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<module>> module_hash_map;
    std::mutex mutex;
};

};     // namespace core
};     // namespace ants
#endif // ANTS_CORE_SERVICE_HPP