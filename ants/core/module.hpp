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
    typedef void *(__cdecl create_function)(void *start_function, void *send_function, void *stop_fucnction);
    typedef void(__cdecl handle_function)(void *context, void *message);
    typedef void(__cdecl destroy_function)(void *context);

public:
    const std::string &module_name()
    {
        return name_;
    };
    const std::string &path()
    {
        return path_;
    };
    boost::dll::shared_library &shared_library()
    {
        return shared_library_;
    };
    std::function<create_function> &create()
    {
        return create_;
    };
    std::function<handle_function> &handle()
    {
        return handle_;
    };
    std::function<destroy_function> &destroy()
    {
        return destroy_;
    };

private:
    std::string name_;
    std::string path_;
    boost::dll::shared_library shared_library_;
    std::function<create_function> create_;
    std::function<handle_function> handle_;
    std::function<destroy_function> destroy_;
};

class module_loader
    : public singleton<module_loader>
{
public:
    static std::shared_ptr<module> load(std::string const &module_name)
    {
        std::lock_guard<std::mutex> lock_guard(instance().mutex);
        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(module_name) != module_unordered_map.end())
            return module_unordered_map[module_name];

        auto module = std::shared_ptr<ants::core::module>(new ants::core::module());
        module_unordered_map[module_name] = module;
        try
        {
            module->shared_library_.load(module_name);
        }
        catch (std::exception const &)
        {
            std::cerr << "Insufficient memory when loading shared memory:" << module_name << std::endl;
        }

        if (!module->shared_library_.is_loaded())
        {
            std::cerr << "Failed loading shared library:" << module_name << std::endl;
            return nullptr;
        }

        try
        {
            module->create_ = module->shared_library_.get<module::create_function>("create");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'create' in shared library:" << module_name << std::endl;
            return nullptr;
        }

        try
        {
            module->handle_ = module->shared_library_.get<module::handle_function>("handle");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'handle' in shared library:" << module_name << std::endl;
            return nullptr;
        }

        try
        {
            module->destroy_ = module->shared_library_.get<module::destroy_function>("destroy");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'destroy' in shared library:" << module_name << std::endl;
            return nullptr;
        }

        return module;
    }

    static bool unload(std::string const &module_name)
    {
        std::lock_guard<std::mutex> lock_guard(instance().mutex);
        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(module_name) == module_unordered_map.end())
            return true;
        auto module = module_unordered_map[module_name];
        try
        {
            module->shared_library_.unload();
            module_unordered_map.erase(module_name);
        }
        catch (std::exception const &)
        {
            std::cerr << "Shared library unload failed:" << module_name << std::endl;
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