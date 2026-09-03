local enum parser_state
    "request_line"
    "headers"
    "body"
    "chunked_size"
    "chunked_data"
    "done"
end


local record http_header
    key: string
    value: string
end

local record parser
    --+ Properties +--
    buffer: string
    state: parser_state
    method: string
    path: string
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
    set_path: function(self, path: string): parser
    set_http_version: function(self, http_version: string): parser
    set_headers: function(self, headers: {http_header}): parser
    append_header: function(self, header: http_header): parser
    set_content_length: function(self, content_length: integer): parser
    set_is_chunked: function(self, is_chunked: boolean): parser
    set_body_chunks: function(self, body_chunks: {string}): parser
    append_body_chunks: function(self, body_chunk: string): parser
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
    get_path: function(self): string = macroexp(self: parser): string
        return self.path
    end
    get_http_version: function(self): string = macroexp(self: parser): string
        return self.http_version
    end
    get_headers: function(self): {http_header} = macroexp(self: parser): {http_header}
        return self.headers
    end
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

function parser:set_path(path: string): parser
    self.path = path
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

function parser:append_body_chunks(body_chunk: string): parser
    table.insert(self.body_chunks, body_chunk)
    return self
end

function parser:set_bytes_read(bytes_read: integer): parser
    self.bytes_read = bytes_read
    return self
end

--+ Logic +--
function parser:reset(): parser
    self
    :set_buffer("")
    :set_state("request_line")
    :set_method(nil)
    :set_path(nil)
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

    local state = self:get_state()

    while true do
        if not state then return false, "Parser has no state" end

        if state == "request_line" then                                                             -- Request line of the HTTP request
            local line_end: integer = self:get_buffer():find("\r\n", 1, true)
            if not line_end then return true end                                                    -- Search for the end of th request line
                                                                                                    -- If there are none, continue to fetch request chunks
            local line: string = self:get_buffer():sub(1, line_end - 1)
            local method, path, version = line:match("^(%u+) (%S+) HTTP/(%d%.%d)$")

            if not method then return false, "Malformed request line" end                           -- If pattern matching fails, the request line is malformed

            self
                :set_method(method)
                :set_path(path)
                :set_http_version(version)
                :set_buffer(self:get_buffer():sub(line_end + 2))
                :set_state("headers")                                                               -- Bump parser state to search for headers
        end
    end
end

return parser
