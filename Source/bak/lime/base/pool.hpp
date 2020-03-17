#ifndef POOL_HPP
#define POOL_HPP
#include <atomic>

#include "singleton.hpp"
#include "define.hpp"
#include "log.hpp"

namespace lime
{
class pool
	: public singleton<pool>
{
public:
	static void *malloc(size_t size)
	{
#ifdef _DEBUG
		++instance().count_;
		uint32_t now = time(NULL);
		if (now - instance().time_ > NUM_MEMORY_STATISTICS_INTERVAL)
		{
			instance().time_ = now;
			LOG(INFO) << "current memory block count is" << instance().count_.load();
		}
#endif
		return std::malloc(size);
	}

	static void free(void *const block)
	{
#ifdef _DEBUG
		--singleton<pool>::count_;
		uint32_t now = time(NULL);
		if (now - singleton<pool>::m_Time > NUM_MEMORY_STATISTICS_INTERVAL)
		{
			singleton<pool>::m_Time = now;
			LOG(INFO) << "current memory block count is %d" << singleton<pool>::m_Count.load());
		}
#endif
		std::free(block);
	}

	template <typename T, typename... ArgsType>
	static T *new (ArgsType... args)
	{
		return new (std::malloc(sizeof(T))) T(args...);
	}

	template <typename T>
	static void delete (T *const block)
	{
		if (!block)
		{
			return;
		}

		((T *)block)->~T();
		std::free(block);
	}

private:
#ifdef _DEBUG
	std::atomic_int count_ = {0};
	std::atomic_int time_ = {0};
#endif
};
};	 // namespace lime
#endif // !POOL_HPP