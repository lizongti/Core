#ifndef ANTS_CORE_MODULE_HPP
#define ANTS_CORE_MODULE_HPP

#include <iostream>
#include <functional>
#include <mutex>
#include <unordered_map>
#include <boost/dll/shared_library.hpp>
#include <boost/noncopyable.hpp>
#include <ants/core/singleton.hpp>

namespace ants
{
namespace core
{

class module
    : public std::enable_shared_from_this<module>
{
public:
    typedef void *(__cdecl create_function)(const char *service_name,
                                            void *function_array[]);
    typedef void(__cdecl handle_function)(void *context,
                                          int event,
                                          const char *source,
                                          void *data);
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
            create = shared_library_.get<create_function>("create");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'create' in shared library:" << name_ << std::endl;
            return false;
        }

        try
        {
            handle = shared_library_.get<handle_function>("handle");
        }
        catch (std::exception const &)
        {
            std::cerr << "Leak function 'handle' in shared library:" << name_ << std::endl;
            return false;
        }

        try
        {
            destroy = shared_library_.get<destroy_function>("destroy");
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

public:
    std::function<create_function> create;
    std::function<handle_function> handle;
    std::function<destroy_function> destroy;

private:
    std::string name_;
    std::string path_;
    boost::dll::shared_library shared_library_;
};

class module_loader
    : public singleton<module_loader>,
      private boost::noncopyable
{
public:
    static std::shared_ptr<module> load(std::string const &module_name)
    {
        std::lock_guard<std::mutex> lock(instance().mutex);

        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(module_name) != module_unordered_map.end())
            return module_unordered_map[module_name];

        auto module = std::shared_ptr<ants::core::module>(new ants::core::module());
        module_unordered_map[module_name] = module;

        return module->load(module_name) ? module : nullptr;
    }

    static std::shared_ptr<module> unload(std::string const &module_name)
    {
        std::lock_guard<std::mutex> lock(instance().mutex);

        auto &module_unordered_map = instance().module_unordered_map;
        if (module_unordered_map.find(module_name) == module_unordered_map.end())
            return nullptr;

        auto module = module_unordered_map[module_name];
        module_unordered_map.erase(module_name);

        return module->unload() ? module : nullptr;
    }

protected:
    std::unordered_map<std::string, std::shared_ptr<module>> module_unordered_map;
    mutable std::mutex mutex;
};

};     // namespace core
};     // namespace ants
#endif // ANTS_CORE_SERVICE_HPP