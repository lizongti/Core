#ifndef ANTS_CORE_MESSAGE_HPP
#define ANTS_CORE_MESSAGE_HPP

#include <ants/def/event.h>

namespace ants
{
namespace core
{

static std::atomic_int new_count = {0};
static std::atomic_int delete_count = {0};
class message
{
public:
    message(ants::def::Event event,
            const std::string &source,
            const std::string &destination,
            void *data)
        : event_(event),
          source_(source),
          destination_(destination),
          data_(data)
    {
    }

public:
    ants::def::Event event() { return event_; }
    const std::string &source() { return source_; }
    const std::string &destination() { return destination_; }
    void *data() { return data_; }

private:
    ants::def::Event event_;
    std::string source_;
    std::string destination_;
    void *data_;
};
};     // namespace core
};     // namespace ants
#endif // ANTS_CORE_MESSAGE_HPP