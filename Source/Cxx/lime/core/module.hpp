#ifndef MODULE_HPP
#define MODULE_HPP

#include <functional>

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
    std::function<void()> load;
    std::function<void()> free;
    std::function<void(message *)> handle;
};
};     // namespace core
};     // namespace lime
#endif // !SERVICE_HPP