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
    queue(){};
    virtual ~queue(){};

public:
    void reserve(size_t n)
    {
        q.reserve(n);
    }
    T *pop()
    {
        T *s;
        return q.pop(s) ? s : nullptr;
    }
    bool push(T *s)
    {
        return q.bounded_push(s);
    }

protected:
    boost::lockfree::queue<T *> q;
};
}; // namespace core
} // namespace lime
#endif // ! QUEUE_HPP