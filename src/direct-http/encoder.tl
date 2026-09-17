local type response = require("direct-http.response")

local reasons = require("direct-http.reasons")

local record encoder
    new: function(): encoder

    encode: function(self, res: response): (boolean, string)

    encode_start_line: function(self, res: response): (boolean, string)
    encode_headers: function(self, res: response): (boolean, string)
    encode_body: function(self, res: response): (boolean, string)
end

function encoder.new(): encoder
    return setmetatable({}, { __index = encoder })
end

function encoder:encode(res: response): (boolean, string)
    local steps: {function(self: encoder, res: response): (boolean, string)} = {
        self.encode_start_line,
        self.encode_headers,
        self.encode_body,
    }

    local parts: {string} = {}

    for _, step in ipairs(steps) do
        local ok, part = step(self, res)
        if not ok then return false, part end
        table.insert(parts, part)
    end

    return true, table.concat(parts)
end

function encoder:encode_start_line(res: response): (boolean, string)
    local ok, reason = reasons.get_reason(res.code)
    if not ok then return false, "Unknown HTTP status code" end

    return true, string.format("HTTP/%s %d %s\r\n", res.version, res.code, reason)
end

function encoder:encode_headers(res: response): (boolean, string)
    local headers = {}

    for _, h in ipairs(res.headers) do
        table.insert(headers, string.format("%s: %s\r\n", h.key, h.value))
    end

    table.insert(headers, "\r\n")
    return true, table.concat(headers)
end

function encoder:encode_body(res: response): (boolean, string)
    return true, res.body
end

return encoder
