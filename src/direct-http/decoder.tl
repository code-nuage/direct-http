local type request = require("direct-http.request")
local type i_header = require("direct-http.i_header")
local type e_state = require("direct-http.e_state")

local record decoder
    state: e_state
    buffer: string
    bytes_read: integer
    body_chunks: {string}
    content_length: integer
    is_chunked: boolean

    new: function(): decoder

    reset: function(self)
    decode: function(self, req: request, chunk: string): (boolean, string)

    decode_start_line: function(self, req: request): (boolean, string)
    decode_headers: function(self, req: request): (boolean, string)
    decode_body: function(self): (boolean, string)
    decode_chunked_size: function(self): (boolean, string)
    decode_chunked_data: function(self): (boolean, string)
end

function decoder.new(): decoder
    local i: decoder = setmetatable({}, { __index = decoder })

    i:reset()

    return i
end

function decoder:reset()
    self.state = "start_line"
    self.buffer = ""
    self.bytes_read = 0
    self.body_chunks = {}
    self.content_length = 0
    self.is_chunked = false
end

function decoder:decode(req: request, chunk: string): (boolean, string)
    self.buffer = self.buffer .. chunk

    while true do
        if not self.state then return false, "Parser has not state" end

        if self.state == "start_line" then
            return self:decode_start_line(req)
        elseif self.state == "headers" then
            return self:decode_headers(req)
        elseif self.state == "body" then
            return self:decode_body()
        elseif self.state == "chunked_size" then
            return self:decode_chunked_size()
        elseif self.state == "chunked_data" then
            return self:decode_chunked_data()
        elseif self.state == "done" then
            req.body = table.concat(self.body_chunks)
            return true
        end
    end
end

function decoder:decode_start_line(req: request): (boolean, string)
    local line_end: integer = self.buffer:find("\r\n", 1, true)
    if not line_end then return true end                                                            -- Search for the end of the request line

    local line: string = self.buffer:sub(1, line_end - 1)
    local method, target, version = line:match("^(%u+) (%S+) HTTP/(%d%.%d)$")

    if not method then return false, "Malformed request line:" .. line end

    req.method = method
    req.target = target
    req.version = version

    self.buffer = self.buffer:sub(line_end + 2)                                                     -- Offset the buffer by two (\r\n)
    self.state = "headers"
    return true
end

function decoder:decode_headers(req: request): (boolean, string)
    local line_end: integer = self.buffer:find("\r\n", 1, true)
    if not line_end then return true end

    local line: string = self.buffer:sub(1, line_end - 1)
    self.buffer = self.buffer:sub(line_end + 2)                                                     -- Offset the buffer by two (\r\n)

    if line == "" then
        local transfer_encoding: i_header = req:get_header("transfer-encoding")
        local content_length: i_header = req:get_header("content-length")

        if transfer_encoding and transfer_encoding.value:find("chunked") then
            self.is_chunked = true
            self.state = "chunked_size"
        elseif content_length then
            self.content_length = tonumber(content_length.value) as integer or 0
            self.state = self.content_length > 0 and "body" or "done"
        else
            self.state = "done"
        end
    else
        local key, value = line:match("^([^:]+):%s*(.*)$")
        if not key then return false, "Malformed header: " .. line end
        table.insert(req.headers, {key = key:lower(), value = value:lower()})
    end
    return true
end

function decoder:decode_body(): (boolean, string)
    local remaining: integer = self.content_length - self.bytes_read

    if #self.buffer < remaining then
        table.insert(self.body_chunks, self.buffer)
        self.bytes_read = self.bytes_read + #self.buffer
        self.buffer = ""
        return true
    else
        table.insert(self.body_chunks, self.buffer:sub(1, remaining))
        self.buffer = self.buffer:sub(remaining + 1)
        self.bytes_read = self.content_length
        self.state = "done"
    end
    return true
end

function decoder:decode_chunked_size(): (boolean, string)
    local line_end: integer = self.buffer:find("\r\n", 1, true)
    if not line_end then return true end


    local size_line: string = self.buffer:sub(1, line_end - 1)

    local size: integer = tonumber(size_line:match("^(%x+)"), 16)
    if not size then return false, "Invalid chunk size" end

    self.buffer = self.buffer:sub(line_end + 2)

    if size == 0 then
        self.state = "done"
    else
        self.content_length = 0
        self.bytes_read = 0
        self.state = "chunked_data"
    end
    return true
end

function decoder:decode_chunked_data(): (boolean, string)
    local remaining: integer = self.content_length - self.bytes_read

    if #self.buffer < remaining + 2 then return true end

    table.insert(self.body_chunks, self.buffer:sub(1, remaining))
    self.state = "chunked_size"
    return true
end

return decoder
