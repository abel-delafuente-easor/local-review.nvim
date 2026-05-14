local M = {}

local seconds_per_day = 24 * 60 * 60

local function utc_offset_for_epoch(epoch)
  local utc_table = os.date("!*t", epoch)
  if type(utc_table) ~= "table" then
    return 0
  end
  return epoch - os.time(utc_table)
end

---@param timestamp string?
---@return integer?
function M.parse_iso8601_utc(timestamp)
  if type(timestamp) ~= "string" then
    return nil
  end

  local year, month, day, hour, min, sec = timestamp:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z$")
  if not year then
    return nil
  end

  local parsed_year = tonumber(year)
  local parsed_month = tonumber(month)
  local parsed_day = tonumber(day)
  local parsed_hour = tonumber(hour)
  local parsed_min = tonumber(min)
  local parsed_sec = tonumber(sec)
  if not parsed_year or not parsed_month or not parsed_day or not parsed_hour or not parsed_min or not parsed_sec then
    return nil
  end

  local local_epoch = os.time({
    year = parsed_year,
    month = parsed_month,
    day = parsed_day,
    hour = parsed_hour,
    min = parsed_min,
    sec = parsed_sec,
    isdst = false,
  })
  if not local_epoch then
    return nil
  end

  return local_epoch + utc_offset_for_epoch(local_epoch)
end

---@param seconds integer
---@return string
function M.format_duration(seconds)
  if seconds <= 0 then
    return "0d"
  end

  if seconds % seconds_per_day == 0 then
    return string.format("%dd", math.floor(seconds / seconds_per_day))
  end

  local days = seconds / seconds_per_day
  return string.format("%.1fd", days)
end

---@param comments table[]
---@param threshold_seconds integer?
---@param now_epoch integer?
---@return integer, integer?
function M.count_comments_older_than(comments, threshold_seconds, now_epoch)
  if type(threshold_seconds) ~= "number" or threshold_seconds <= 0 then
    return 0, nil
  end

  local now_value = now_epoch or os.time()
  local count = 0
  local oldest_age

  for _, comment in ipairs(comments or {}) do
    local last_updated = M.parse_iso8601_utc(comment.updated_at) or M.parse_iso8601_utc(comment.created_at)
    if last_updated then
      local age = now_value - last_updated
      if age >= threshold_seconds then
        count = count + 1
        if oldest_age == nil or age > oldest_age then
          oldest_age = age
        end
      end
    end
  end

  return count, oldest_age
end

return M
