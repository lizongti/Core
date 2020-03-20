#ifndef QUEUE_HPP
#define QUEUE_HPP

#include <boost/lockfree/queue.hpp>

namespace lime
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
        q = new queue_type(n);
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
    queue_type *q;
};
}; // namespace core
} // namespace lime
#endif // ! QUEUE_HPP