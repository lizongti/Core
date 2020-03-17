function os.now_date()
    return os.date("*t")
end

local function clamp(v, min, max)
    if min and v < min then
        return min
    end
    if max and v > max then
        return max
    end
    return v
end

function os.day(time)
    local delta_hour = 3
    local first = time - 3600 * delta_hour
    if first < 0 then
        first = 0
    end
    local first_date = os.date("*t", first)
    return first_date.day
end

function os.same_day(first, second)
    local delta_hour = 3
    local first = first - 3600 * delta_hour
    if first < 0 then
        first = 0
    end
    local second = second - 3600 * delta_hour
    if second < 0 then
        second = 0
    end
    local first_date = os.date("*t", first)
    local second_date = os.date("*t", second)
    return first_date.day == second_date.day and first_date.month == second_date.month and
        first_date.year == second_date.year
end

--以周日为每周的第一天
function os.same_week(first, second)
    local delta_hour = 3
    local large = (first > second) and first or second
    local small = (first <= second) and first or second
    local large_date = os.date("*t", math.max(large - 3600 * delta_hour, 0))
    local small_date = os.date("*t", math.max(small - 3600 * delta_hour, 0))
    local delta_day = (large - small) / (3600 * 24)
    local large_wday = large_date.wday
    --周日的wday=1,周六的wday=7
    if delta_day >= 7 or delta_day >= large_wday then
        return false
    end
    return true
end

function os.is_today(timestamp)
    return os.same_day(timestamp, os.time())
end

function os.is_yesterday(timestamp)
    return os.same_day(timestamp, os.time() - 86400)
end

function os.same_month(first, second)
    local delta_hour = 3
    local first_date = os.date("*t", math.max(first - 3600 * delta_hour, 0))
    local second_date = os.date("*t", math.max(second - 3600 * delta_hour, 0))
    return first_date.month == second_date.month and first_date.year == second_date.year
end

function os.is_current_month(timestamp)
    return os.same_month(timestamp, os.time())
end

function os.today_str()
    local delta_hour = 3
    local today = os.date("*t", math.max(0, os.time() - 3600 * delta_hour))
    return string.format("%04d-%02d-%02d", today.year, today.month, today.day)
end

function os.yesterday_str()
    local delta_hour = 3
    local today = os.date("*t", math.max(0, os.time() - 3600 * (delta_hour + 24)))
    return string.format("%04d-%02d-%02d", today.year, today.month, today.day)
end

function os.today_clock(hour, minute, second)
    local now_date = os.date("*t")
    return os.time(
        {
            day = now_date.day,
            month = now_date.month,
            year = now_date.year,
            hour = hour or 0,
            minute = minute or 0,
            second = second or 0
        }
    )
end

function os.string2date(date)
    local pattern = "(%d+)-(%d+)-(%d+)"
    local y, m, d = date:match(pattern)
    return os.time({year = y, month = m, day = d})
end

function os.string2time(date)
    local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
    local y, m, d, h, min, s = date:match(pattern)

    return os.time(
        {
            year = y,
            month = m,
            day = d,
            hour = h or 0,
            minute = min or 0,
            second = s or 0
        }
    )
end

function os.chs_time()
    local now_date = os.date("*t")
    return string.format(
        "%s年%s月%s日%s时%s分%s秒",
        now_date.year,
        now_date.month,
        now_date.day,
        now_date.hour,
        now_date.min,
        now_date.sec
    )
end
