#ifndef SINGLETON_HPP
#define SINGLETON_HPP

namespace lime
{
template <typename T>
class singelton
{
public:
	static T &instance()
	{
		static T t;
		return t;
	}
};
}; // namespace lime

#endif // !SINGLETON_HPP