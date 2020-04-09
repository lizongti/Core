#ifndef ANTS_DETAIL_SINGLETON_HPP
#define ANTS_DETAIL_SINGLETON_HPP

namespace ants
{
namespace detail
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
}; // namespace detail
}; // namespace ants

#endif // ANTS_DETAIL_SINGLETON_HPP