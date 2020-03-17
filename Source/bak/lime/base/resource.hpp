#ifndef RESOURCE_HPP
#define RESOURCE_HPP

#include <atomic>
#include <mutex>
#include <unordered_map>
#include <functional>
#include <assert.h>

#include "Pool.h"
#include "Resource.h"

template <typename Key_Type, typename Value_Type = void *>
class Resource
	: public singleton<Resource<Key_Type, Value_Type>>
{
public:
	Resource()
	{
		lock_.store(true);
	}
	virtual ~Resource()
	{
	}

public:
	template <typename Return_Type>
	inline Return_Type Call(std::function<Return_Type()> f)
	{
		if (lock_.load())
		{
			std::lock_guard<std::mutex> lock(mutex_);
			return f();
		}
		else
		{
			return f();
		}
	}

	//Template specification in a template class is not valid in linux, using function reload instead.
	inline void Call(std::function<void()> f)
	{
		if (lock_.load())
		{
			std::lock_guard<std::mutex> lock(mutex_);
			f();
		}
		else
		{
			f();
		}
	};

public:
	// for Value_Type is value passing
	static Value_Type &Create(const Key_Type &key)
	{
		return Resource<Key_Type, Value_Type>::Instance().create(key);
	}
	static void Set(const Key_Type &key, const Value_Type &value)
	{
		Resource<Key_Type, Value_Type>::Instance().set(key, value);
	}
	static Value_Type &Get(const Key_Type &key)
	{
		return Resource<Key_Type, Value_Type>::Instance().get(key);
	}
	static bool Destroy(const Key_Type &key)
	{
		return Resource<Key_Type, Value_Type>::Instance().destroy(key);
	}
	static void Truncate()
	{
		Resource<Key_Type, Value_Type>::Instance().taruncate();
	}

public:
	// for Value_Type is reference passing
	static void Insert(const Key_Type &key, const Value_Type *value)
	{
		Resource<Key_Type, Value_Type>::Instance().insert(key, value);
	}

	static Value_Type *Find(const Key_Type &key)
	{
		return Resource<Key_Type, Value_Type>::Instance().find(key);
	}
	static bool Erase(const Key_Type &key)
	{
		return Resource<Key_Type, Value_Type>::Instance().erase(key);
	}
	static void Clear()
	{
		Resource<Key_Type, Value_Type>::Instance().clear();
	}

public:
	static void Traverse(std::function<void(Key_Type, Value_Type *)> f)
	{
		Resource<Key_Type, Value_Type>::Instance().traverse(f);
	}
	static size_t Count()
	{
		return Resource<Key_Type, Value_Type>::Instance().count();
	}

public:
	static void Lock()
	{
		Resource<Key_Type, Value_Type>::Instance().lock();
	}
	static void Unlock()
	{
		Resource<Key_Type, Value_Type>::Instance().unlock();
	}
	static bool Locked()
	{
		return Resource<Key_Type, Value_Type>::Instance().locked();
	}

protected:
	Value_Type &create(const Key_Type &key)
	{
		return *Call<Value_Type *>([&]() {
			auto value = object_pool<Value_Type>::new ();
			dict_[key] = value;
			return value;
		});
	}
	void set(const Key_Type &key, const Value_Type &value)
	{
		Call<void>([&]() {
			dict_[key] = object_pool<Value_Type>::new (value);
		});
	}
	Value_Type &get(const Key_Type &key)
	{
		return *Call<Value_Type *>([&]() {
			auto it = dict_.find(key);
			if (it == dict_.end())
			{
				auto value = object_pool<Value_Type>::new ();
				dict_[key] = value;
				return value;
			}
			else
			{
				assert(it->second);
				return it->second;
			}
		});
	}
	bool destroy(const Key_Type &key)
	{
		return Call<bool>([&]() {
			auto it = dict_.find(key);
			if (it == dict_.end())
			{
				return false;
			}

			object_pool<Value_Type>::delete (it->second);
			dict_.erase(it);
			return true;
		});
	}
	void truncate()
	{
		Call<void>([&]() {
			for (auto it : dict_)
			{
				object_pool<Value_Type>::delete (it->second);
			}
			dict_.clear();
		});
	}

protected:
	void insert(const Key_Type &key, const Value_Type *value)
	{
		Call<void>([&]() {
			dict_[key] = const_cast<Value_Type *>(value);
		});
	}
	Value_Type *find(const Key_Type &key)
	{
		return Call<Value_Type *>([&]() {
			auto it = dict_.find(key);
			if (it == dict_.end())
			{
				return (Value_Type *)nullptr;
			}
			else
			{
				return it->second;
			}
		});
	}
	bool erase(const Key_Type &key)
	{
		return Call<bool>([&]() {
			auto it = dict_.find(key);
			if (it == dict_.end())
			{
				return false;
			}

			dict_.erase(it);
			return true;
		});
	}
	void clear()
	{
		Call<void>([&]() {
			dict_.clear();
		});
	}

protected:
	void traverse(std::function<void(Key_Type, Value_Type *)> f)
	{
		Call<void>([&]() {
			for (auto pair : dict_)
			{
				f(pair.first, pair.second);
			}
		});
	}

	size_t count()
	{
		return Call<size_t>([&]() {
			size_t count = 0;
			for (auto pair : dict_)
			{
				++count;
			}
			return count;
		});
	}

protected:
	void lock()
	{
		return lock_.store(true);
	}
	void unlock()
	{
		return lock_.store(false);
	}
	bool locked()
	{
		return lock_.load();
	}

private:
	std::unordered_map<Key_Type, Value_Type *> dict_;
	std::mutex mutex_;
	std::atomic_bool lock_;
};

template <uint32_t COUNTER_TYPE>
class ResourceCounter
	: singleton<ResourceCounter<COUNTER_TYPE>>
{
public:
	ResourceCounter()
	{
		Resource<uint32_t, std::atomic_int>::Insert(COUNTER_TYPE, object_pool<std::atomic_int>::new ());
	}

public:
	static void Increase()
	{
		ResourceCounter<COUNTER_TYPE>::Instance().increase();
	}
	static void Decrease()
	{
		ResourceCounter<COUNTER_TYPE>::Instance().decrease();
	}
	static int Get()
	{
		return ResourceCounter<COUNTER_TYPE>::Instance().Get();
	}
	static void Set(int value)
	{
		ResourceCounter<COUNTER_TYPE>::Instance().set(value);
	}

protected:
	void increase()
	{
		auto counter = Resource<uint32_t, std::atomic_int>::Find(COUNTER_TYPE);
		assert(counter);
		++(*counter);
	}
	void decrease()
	{
		auto counter = Resource<uint32_t, std::atomic_int>::Find(COUNTER_TYPE);
		assert(counter);
		--(*counter);
	}
	int get()
	{
		auto counter = Resource<uint32_t, std::atomic_int>::Find(COUNTER_TYPE);
		assert(counter);
		return counter->load();
	}
	void set(int value)
	{
		auto counter = Resource<uint32_t, std::atomic_int>::Find(COUNTER_TYPE);
		assert(counter);
		counter->store(value);
	}
};

#endif // !RESOURCE_HPP
