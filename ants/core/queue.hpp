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
    queue(){};
    virtual ~queue(){};

public:
    void malloc(size_t n)
    {
        q = std::shared_ptr<queue_type>(new queue_type(n));
    }
    T *pop()
    {
        T *s;
        return q->pop(s) ? s : nullptr;
    }
    bool push(T *s)
    {
        return q->bounded_push(s);
    }

protected:
    std::shared_ptr<queue_type> q;
};
}; // namespace core
} // namespace ants
#endif // ANTS_CORE_QUEUE_HPP