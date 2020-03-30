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
        queue_ = std::shared_ptr<queue_type>(new queue_type(n));
    }
    T *pop()
    {
        T *t;
        return queue_->pop(t) ? t : nullptr;
    }
    bool push(T *t)
    {
        return queue_->bounded_push(t);
    }

protected:
    std::shared_ptr<queue_type> queue_;
};
}; // namespace core
} // namespace ants
#endif // ANTS_CORE_QUEUE_HPP