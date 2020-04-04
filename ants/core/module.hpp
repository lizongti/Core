#ifndef ANTS_CORE_MODULE_HPP
#define ANTS_CORE_MODULE_HPP

#include <iostream>
#include <functional>
#include <mutex>
#include <shared_mutex>
#include <unordered_map>
#include <boost/dll/shared_library.hpp>
#include <ants/core/singleton.hpp>

namespace ants
{
namespace core
{

class module
{
public:
    typedef void *(__cdecl create_function)(const char *service_name, void *function_array[]);
    typedef void(__cdecl handle_function)(void *context, void *message);
    typedef void(__cdecl destroy_function)(void *context);

public:
    bool load(std::string const &module_name)
    {
        name_ = module_name;
        try
        {
            shared_library_.load(name_);
        }
        catch (std::exception const &)
        {
            std::cerr << "Insufficient memory when loading shared memory:" << name_ << std::endl;
        }

        if (!shared_library_.is_loaded())
        {
            std::cerr << "Failed loading shared library:" << name_ << std::endl;
            return false;
        }

        try
        {
            create_ = shared_library_.get<create_function>("create");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'create' in shared library:" << name_ << std::endl;
            return false;
        }

        try
        {
            handle_ = shared_library_.get<handle_function>("handle");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'handle' in shared library:" << name_ << std::endl;
            return false;
        }

        try
        {
            destroy_ = shared_library_.get<destroy_function>("destroy");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'destroy' in shared library:" << name_ << std::endl;
            return false;
        }
        return true;
    }

    bool unload()
    {
        try
        {
            shared_library_.unload();
        }
        catch (std::exception const &)
        {
            std::cerr << "Shared library unload failed:" << name_ << std::endl;
            return false;
        }
        return true;
    }

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
    : public singleton<module_loader>,
      private boost::noncopyable
{
public:
    static std::shared_ptr<module> load(std::string const &module_name)
    {
        std::lock_guard<std::mutex> _(instance().mutex);
        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(module_name) != module_unordered_map.end())
            return module_unordered_map[module_name];

        auto module = std::shared_ptr<ants::core::module>(new ants::core::module());
        module_unordered_map[module_name] = module;

        return module->load(module_name) ? module : nullptr;
    }

    static bool unload(std::string const &module_name)
    {
        std::lock_guard<std::mutex> _(instance().mutex);
        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(module_name) == module_unordered_map.end())
            return true;
        auto module = module_unordered_map[module_name];
        module_unordered_map.erase(module_name);

        return module->unload();
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<module>> module_unordered_map;
    mutable std::mutex mutex;
};

};     // namespace core
};     // namespace ants
#endif // ANTS_CORE_SERVICE_HPP