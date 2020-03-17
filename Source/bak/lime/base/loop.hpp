#ifndef LOOP_HPP
#define LOOP_HPP

#include <uv.h>
#include "log.hpp"
#include "define.hpp"

namespace lime
{
class loop
{
public:
    loop()
    {
        thread_ = pool::new<uv_thread_t>();
        loop_ = pool::new<uv_loop_t>();
        stop_ = pool::new<uv_async_t>();
        work_ = pool::new<uv_async_t>();

        services_ = pool::new<boost::lockfree::queue<service *>>(LOOP_SERVICE_QUEUE_MAX);
    };

    virtual ~loop()
    {
        pool::delete (thread_);
        pool::delete (loop_);
        pool::delete (stop_);
        pool::delete (work_);
        pool::delete (services_);
    }

public:
    void start()
    {
        uv_timer_init(loop_, timer_);
        uv_timer_start(timer_, timer_cb, 0, LOOP_SERVICE_MAX_TIME);

        uv_async_init(loop_, async_, async_cb);
        uv_thread_create(thread_, thread_cb, this);
    }

    void stop()
    {
        uv_async_send(stop_);
    }

    void adopt(service *service)
    {
        services_.push(service);
        uv_async_send(work_);
    }

protected:
    static void thread_cb(void *arg)
    {
        uv_run((loop *)arg->loop_, UV_RUN_DEFAULT);
        auto result = uv_loop_close((loop *)arg->loop_);
        if (result)
        {
            LOG(ERROR) << "failed to close uv loop" << uv_err_name(result) << std::endl;
        }
        else
        {
            LOG(INFO) << "uv loop is closed successfully!" << std::endl;
        }
    }

    static void stop_cb(uv_async_t *handle, int status)
    {
        auto result = uv_loop_close(handle->loop);
        if (result == UV_EBUSY)
        {
            uv_walk(handle->loop, walk_cb, NULL);
        }
    }

    static void walk_cb(uv_handle_t *handle, void *arg)
    {
        uv_close(handle, close_cb);
    }

    static void close_cb(uv_handle_t *handle, int status)
    {
        if (handle)
        {
            delete handle;
        }
    }

    static void work_cb(uv_handle_t *handle, int status)
    {
        service *s;
        while (services_->pop(s))
        {
            while (s.consume())
            {
                if (!shift_.load())
                {
                    continue;
                }
                shift_.store(false);
                if (!services.push(s))
                {
                    LOG(WARN) << "service in loop is full, abandon service" << std::endl;
                }
            }
        }
    }

private:
    uv_thread_t *thread_;
    uv_loop_t *loop_;
    uv_async_t *stop_;
    uv_async_t *work_;

    // uv_timer_t *timer_;
    uint64_t timer_dispatch_id_;
    uint64_t current_dispatch_id_;

    boost::lockfree::queue<service *> *services;
    std::atomic_bool shift_;
};
};     // namespace lime
#endif // !LOOP_HPP