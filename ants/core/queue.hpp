#ifndef ANTS_CORE_QUEUE_HPP
#define ANTS_CORE_QUEUE_HPP

#include <boost/lockfree/queue.hpp>

namespace ants
{
namespace core
{
template <typename T>
class queue
{
public:
    typedef boost::lockfree::queue<T *, boost::lockfree::fixed_sized<true>> queue_type;

public:
    void malloc(size_t n)
    {
        queue_ = std::shared_ptr<queue_type>(new queue_type(n));
    };
    T *pop()
    {
        T *t;
        return queue_->pop(t) ? t : nullptr;
    };
    bool push(T *t)
    {
        return queue_->bounded_push(t);
    };

protected:
    std::shared_ptr<queue_type> queue_;
};

template <typename T>
class unique_queue
{
public:
    static void malloc(size_t n)
    {
        singleton<queue<T>>::instance().malloc(n);
    };
    static T *pop()
    {
        return singleton<queue<T>>::instance().pop();
    };
    static bool push(T *t)
    {
        return singleton<queue<T>>::instance().push();
    };
};
}; // namespace core
} // namespace ants
#endif // ANTS_CORE_QUEUE_HPP