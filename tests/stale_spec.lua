---@diagnostic disable: undefined-global, undefined-field
require("busted.runner")()

package.path = table.concat({
  "./lua/?.lua",
  "./lua/?/init.lua",
  package.path,
}, ";")

local stale = require("local_review.stale")

describe("local_review.stale", function()
  it("parses UTC timestamps consistently", function()
    local first = assert(stale.parse_iso8601_utc("2026-04-10T12:00:00Z"))
    local second = assert(stale.parse_iso8601_utc("2026-04-11T12:00:00Z"))
    assert.are.equal(24 * 60 * 60, second - first)
  end)

  it("counts comments older than the threshold using updated_at", function()
    local now_epoch = assert(stale.parse_iso8601_utc("2026-04-18T12:00:00Z"))
    local count, oldest_age = stale.count_comments_older_than({
      {
        created_at = "2026-04-01T12:00:00Z",
        updated_at = "2026-04-05T12:00:00Z",
      },
      {
        created_at = "2026-04-15T12:00:00Z",
        updated_at = "2026-04-16T12:00:00Z",
      },
      {
        created_at = "2026-04-10T12:00:00Z",
      },
    }, 7 * 24 * 60 * 60, now_epoch)

    assert.are.equal(2, count)
    assert.are.equal(13 * 24 * 60 * 60, oldest_age)
  end)

  it("treats missing or disabled thresholds as inactive", function()
    local count, oldest_age = stale.count_comments_older_than({
      { updated_at = "2026-04-01T12:00:00Z" },
    }, nil, os.time())

    assert.are.equal(0, count)
    assert.is_nil(oldest_age)
  end)
end)
