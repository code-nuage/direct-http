local type http_header = require("iheader")

local enum parser_state
    "request_line"
    "headers"
    "body"
    "chunked_size"
    "chunked_data"
    "done"
end

local record parser
    --+ Properties +--
    buffer: string
    state: parser_state
    method: string
    target: string                                                                                  -- Path of an HTTP message is named a "target" in RFC 9112
    http_version: string
    headers: {http_header}
    content_length: integer
    is_chunked: boolean
    body_chunks: {string}
    bytes_read: integer

    --+ Constructor +--
    new: function(): parser

    --+ Setters +--
    set_buffer: function(self, buffer: string): parser
    append_buffer: function(self, chunk: string): parser
    set_state: function(self, state: parser_state): parser
    set_method: function(self, method: string): parser
    set_target: function(self, target: string): parser
    set_http_version: function(self, http_version: string): parser
    set_headers: function(self, headers: {http_header}): parser
    append_header: function(self, header: http_header): parser
    set_content_length: function(self, content_length: integer): parser
    set_is_chunked: function(self, is_chunked: boolean): parser
    set_body_chunks: function(self, body_chunks: {string}): parser
    append_body_chunk: function(self, body_chunk: string): parser
    set_bytes_read: function(self, bytes_read: integer): parser

    --+ Getters +--
    get_buffer: function(self): string = macroexp(self: parser): string
        return self.buffer
    end
    get_state: function(self): parser_state = macroexp(self: parser): parser_state
        return self.state
    end
    get_method: function(self): string = macroexp(self: parser): string
        return self.method
    end
    get_target: function(self): string = macroexp(self: parser): string
        return self.target
    end   get_http_version: function(self): string = macroexp(self: parser): string
        return self.http_version
    end
    get_headers: function(self): {http_header} = macroexp(self: parser): {http_header}
        return self.headers
    end
    get_header: function(self, key: string): http_header
    get_content_length: function(self): integer = macroexp(self: parser): integer
        return self.content_length
    end
    get_is_chunked: function(self): boolean = macroexp(self: parser): boolean
        return self.is_chunked
    end
    get_body_chunks: function(self): {string} = macroexp(self: parser): {string}
        return self.body_chunks
    end
    get_bytes_read: function(self): integer = macroexp(self: parser): integer
        return self.bytes_read
    end

    --+ Logic +--
    feed: function(self, chunk: string): (boolean, string)
    reset: function(self): parser

    parse_request_line: function(self): (boolean, string)
    parse_headers: function(self): (boolean, string)
    parse_body: function(self): (boolean, string)
    parse_chunked_size: function(self): (boolean, string)
    parse_chunked_data: function(self): (boolean, string)
end

--+ Constructor +--
function parser.new(): parser
    local self: parser = setmetatable({}, {__index = parser} as metatable<parser>)

    self:reset()

    return self
end

--+ Setters +--
function parser:set_buffer(buffer: string): parser
    self.buffer = buffer
    return self
end

function parser:append_buffer(chunk: string): parser
    self.buffer = self.buffer .. chunk
    return self
end

function parser:set_state(state: parser_state): parser
    self.state = state
    return self
end

function parser:set_method(method: string): parser
    self.method = method
    return self
end

function parser:set_target(target: string): parser
    self.target = target
    return self
end

function parser:set_http_version(http_version: string): parser
    self.http_version = http_version
    return self
end

function parser:set_headers(headers: {http_header}): parser
    self.headers = headers
    return self
end

function parser:append_header(header: http_header): parser
    table.insert(self.headers, header)
    return self
end

function parser:set_content_length(content_length: integer): parser
    self.content_length = content_length
    return self
end

function parser:set_is_chunked(is_chunked: boolean): parser
    self.is_chunked = is_chunked
    return self
end

function parser:set_body_chunks(body_chunks: {string}): parser
    self.body_chunks = body_chunks
    return self
end

function parser:append_body_chunk(body_chunk: string): parser
    table.insert(self.body_chunks, body_chunk)
    return self
end

function parser:set_bytes_read(bytes_read: integer): parser
    self.bytes_read = bytes_read
    return self
end

--+ Getters +--
function parser:get_header(key: string): http_header
    for _, header in ipairs(self:get_headers()) do
        if header.key == key:lower() then return header end
    end
end

--+ Logic +--
function parser:reset(): parser
    self
    :set_buffer("")
    :set_state("request_line")
    :set_method(nil)
    :set_target(nil)
    :set_http_version(nil)
    :set_headers({})
    :set_content_length(nil)
    :set_is_chunked(false)
    :set_body_chunks({})
    :set_bytes_read(0)

    return self
end

function parser:feed(chunk: string): (boolean, string)
    self:append_buffer(chunk)

    while true do
        local state = self:get_state()
        if not state then return false, "Parser has no state" end

        if state == "request_line" then                                                             -- Request line of the HTTP request
            local line_end: integer = self:get_buffer():find("\r\n", 1, true)
            if not line_end then return true end                                                    -- Search for the end of the request line
                                                                                                    -- If there are none, continue to fetch request chunks
            local line: string = self:get_buffer():sub(1, line_end - 1)
            local method, target, version = line:match("^(%u+) (%S+) HTTP/(%d%.%d)$")

            if not method then return false, "Malformed request line: " .. line end                 -- If pattern matching fails, the request line is malformed

            self
                :set_method(method)
                :set_target(target)
                :set_http_version(version)
                :set_buffer(self:get_buffer():sub(line_end + 2))
                :set_state("headers")                                                               -- Bump parser state to search for headers
        elseif state == "headers" then                                                              -- Headers line of the HTTP request
            local line_end: integer = self:get_buffer():find("\r\n", 1, true)
            if not line_end then return true end

            local line: string = self:get_buffer():sub(1, line_end - 1)
            self:set_buffer(self:get_buffer():sub(line_end + 2))

            if line == "" then                                                                      -- Quoting RFC 9112: "an empty line indicating the end of the header section"
                local content_length = self:get_header("content-length")
                local transfer_encoding = self:get_header("transfer-encoding")

                if transfer_encoding and transfer_encoding.value:find("chunked") then               -- If Transfer-Encoding is chunked, start parsing the chunks
                    self
                        :set_is_chunked(true)
                        :set_state("chunked_size")
                elseif content_length then
                    self
                        :set_content_length(tonumber(content_length.value) as integer or 0)
                        :set_state(self:get_content_length() > 0 and "body" or "done")
                else
                    self:set_state("done")
                end
            else
                local key, value = line:match("^([^:]+):%s*(.*)$")
                if not key then return false, "Malformed header: " .. line end
                self:append_header({key = key:lower(), value = value})                              -- Append the formed header to the parser with its key lowered
            end
        elseif state == "body" then
            local remaining = self:get_content_length() - self:get_bytes_read()

            if #self:get_buffer() < remaining then
                self
                    :append_body_chunk(self:get_buffer())
                    :set_bytes_read(self:get_bytes_read() + #self:get_buffer())
                    :set_buffer("")
                return true
            else
                self
                    :append_body_chunk(self:get_buffer():sub(1, remaining))
                    :set_buffer(self:get_buffer():sub(remaining + 1))
                    :set_bytes_read(self:get_content_length())
                    :set_state("done")
            end
        elseif state == "chunked_size" then
            local line_end: integer = self:get_buffer():find("\r\n", 1, true)
            if not line_end then
                return true
            end

            local size_line: string = self:get_buffer():sub(1, line_end - 1)

            local size: integer = tonumber(size_line:match("^(%x+)"), 16)
            if not size then
                return false, "Invalid chunk size"
            end

            self:set_buffer(self:get_buffer():sub(line_end + 2))

           if size == 0 then
                self:set_state("done")
            else
                self
                    :set_content_length(0)
                    :set_bytes_read(0)
                    :set_state("chunked_data")
            end
        elseif state == "chunked_data" then
            local remaining: integer = self:get_content_length() - self:get_bytes_read()

            if #self:get_buffer() < remaining + 2 then return true end                              -- +2 gets the last \r\n

            self
                :append_body_chunk(self:get_buffer():sub(1, remaining))                             -- Append the possibly unfinished chunk
                :set_buffer(self:get_buffer():sub(remaining + 2 + 1))
                :set_state("chunked_size")
        elseif state == "done" then
            return true
        end
    end
end

return parser
