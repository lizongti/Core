#ifndef ANTS_CORE_QUEUE_HPP
#define ANTS_CORE_QUEUE_HPP

#include <queue>
#include <mutex>
#include <shared_mutex>
#include <condition_variable>
#include <initializer_list>

namespace ants
{
namespace core
{

template <typename T>
class queue
{
private:
    mutable std::mutex mutex;
    mutable std::condition_variable condition_variable;
    std::queue<T> queue_;

    using queue_type = typename std::queue<T>;
    using value_type = typename queue_type::value_type;
    using container_type = typename queue_type::container_type;

public:
    queue() = default;
    queue(const queue &) = delete;
    queue &operator=(const queue &) = delete;

    template <typename _InputIterator>
    queue(_InputIterator first, _InputIterator last)
    {
        for (auto itor = first; itor != last; ++itor)
        {
            queue_.push(*itor);
        }
    }
    explicit queue(const container_type &c) : queue_(c) {}
    queue(std::initializer_list<value_type> list)
        : queue(list.begin(), list.end())
    {
    }

    void push(const value_type &value)
    {
        std::lock_guard<std::mutex> lock(mutex);
        queue_.push(std::move(value));
        condition_variable.notify_one();
    }

    value_type wait_and_pop()
    {
        std::unique_lock<std::mutex> lock(mutex);
        condition_variable.wait(lock, [this] {
            return !this->queue_.empty();
        });
        auto value = std::move(queue_.front());
        queue_.pop();
        return value;
    }

    bool try_pop(value_type &value)
    {
        std::lock_guard<std::mutex> lock(mutex);
        if (queue_.empty())
            return false;
        value = std::move(queue_.front());
        queue_.pop();
        return true;
    }

    auto empty() const -> decltype(queue_.empty())
    {
        std::lock_guard<std::mutex> lock(mutex);
        return queue_.empty();
    }

    auto size() const -> decltype(queue_.size())
    {
        std::lock_guard<std::mutex> lock(mutex);
        return queue_.size();
    }
};
template <typename T>
class shared_queue
    : public queue<std::shared_ptr<T>>
{
public:
    std::shared_ptr<T> pop(bool wait = false)
    {
        if (wait)
            return wait_and_pop();
        else
        {
            std::shared_ptr<T> value;
            return try_pop(value) ? value : nullptr;
        }
    }
};

template <typename T>
class static_shared_queue
{
public:
    static void push(std::shared_ptr<T> value)
    {
        singleton<shared_queue<T>>::instance().push(value);
    };
    static std::shared_ptr<T> pop(bool wait = false)
    {
        return singleton<shared_queue<T>>::instance().pop(wait);
    }
};

}; // namespace core
} // namespace ants
#endif // ANTS_CORE_QUEUE_HPP