#ifndef ANTS_CORE_SINGLETON_HPP
#define ANTS_CORE_SINGLETON_HPP

namespace ants
{
namespace core
{
template <typename T>
class singleton
{
public:
    static T &instance()
    {
        static T t;
        return t;
    }
};
}; // namespace core
}; // namespace ants

#endif // ANTS_CORE_SINGLETON_HPP