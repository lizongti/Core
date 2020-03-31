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

class module
{
    friend class module_loader;

public:
    const std::string &name() { return name_; };
    const std::string &path() { return path_; };
    boost::dll::shared_library &shared_library() { return shared_library_; };
    std::function<void __cdecl(void)> &init() { return init_; };
    std::function<void __cdecl(void *)> &work() { return work_; };
    std::function<void __cdecl(void)> &fini() { return fini_; };

private:
    std::string name_;
    std::string path_;
    boost::dll::shared_library shared_library_;
    std::function<void __cdecl(void)> init_;
    std::function<void __cdecl(void *)> work_;
    std::function<void __cdecl(void)> fini_;
};

class module_loader
    : public singleton<module_loader>
{
public:
    static std::shared_ptr<module> load(std::string const &name)
    {
        std::lock_guard<std::mutex> lock_guard(instance().mutex);
        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(name) != module_unordered_map.end())
            return module_unordered_map[name];

        auto module = std::shared_ptr<ants::core::module>(new ants::core::module());
        module_unordered_map[name] = module;
        try
        {
            module->shared_library_.load(name);
        }
        catch (std::exception const &)
        {
            std::cerr << "Insufficient memory when loading shared memory:" << name << std::endl;
        }

        if (!module->shared_library_.is_loaded())
        {
            std::cerr << "Failed loading shared library:" << name << std::endl;
            return nullptr;
        }

        try
        {
            module->init_ = module->shared_library_.get<void __cdecl(void)>("init");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'init' in shared library:" << name << std::endl;
            return nullptr;
        }

        try
        {
            module->work_ = module->shared_library_.get<void __cdecl(void *)>("work");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'work' in shared library:" << name << std::endl;
            return nullptr;
        }

        try
        {
            module->fini_ = module->shared_library_.get<void __cdecl(void)>("fini");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'fini' in shared library:" << name << std::endl;
            return nullptr;
        }

        return module_unordered_map[name];
    }

    static bool unload(std::string const &name)
    {
        std::lock_guard<std::mutex> lock_guard(instance().mutex);
        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(name) == module_unordered_map.end())
            return true;

        try
        {
            module_unordered_map[name]->shared_library_.unload();
            module_unordered_map.erase(name);
        }
        catch (std::exception const &)
        {
            std::cerr << "Shared library unload failed:" << name << std::endl;
            return false;
        }
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<module>> module_unordered_map;
    std::mutex mutex;
};

};     // namespace core
};     // namespace ants
#endif // ANTS_CORE_SERVICE_HPP