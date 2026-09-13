local uv = require("luv")

local parser = require("parser")

local record server
    --+ Properties +--
    host: string
    port: integer

    --+ Constructor +--
    new: function(host: string | nil, port: integer | nil): server

    --+ Setters +--
    set_host: function(self, host: string | nil): server
    set_port: function(self, port: integer | nil): server

    --+ Getters +--
    get_host: function(self): string = macroexp(self: server): string
        return self.host
    end
    get_port: function(self): integer = macroexp(self: server): integer
        return self.port
    end

    --+ Logic +--
    start: function(self)
end

--+ Constructor +--
function server.new(host: string | nil, port: integer | nil): server
    local self: server = setmetatable({}, {__index = server} as metatable<server>)

    self:set_host(host)
    self:set_port(port)

    return self
end

--+ Setters +--
function server:set_host(host: string | nil): server
    self.host = host and host or "127.0.0.1"
    return self
end

function server:set_port(port: integer | nil): server
    self.port = port and port or 1337
    return self
end

--+ Logic +--
function server:start()
    local tcp_server: uv.Tcp = uv.new_tcp(nil)

    assert(tcp_server:bind(self:get_host(), self:get_port(), nil))
    tcp_server:listen(128, function()
        local tcp_client: uv.Tcp = uv.new_tcp(nil)
        tcp_server:accept(tcp_client)
        local message_parser = parser.new()

        tcp_client:read_start(function(err: string, chunk: string)
            assert(not err, err)

            if not chunk then
                tcp_client:shutdown(nil)
                tcp_client:close()
                return
            end

            local ok, parse_success, parse_err = pcall(message_parser.feed, message_parser, chunk)

            local connection_header = message_parser:get_header("connection")
            local keep_alive = not (connection_header and connection_header.value:lower() == "close")

            if not ok then
                tcp_client:write("HTTP/1.1 500 Internal server error", nil)
                tcp_client:shutdown(nil)
                tcp_client:close()
                return
            end

            if not parse_success then
                io.write(string.format("Parsing error: %s", parse_err))
                tcp_client:write("HTTP/1.1 400 Bad Request\r\n\r\n", nil)
                tcp_client:shutdown(nil)
                tcp_client:close()
                return
            end

            if message_parser:get_state() ~= "done" then
                return
            end

            tcp_client:write("HTTP/1.1 200 Ok\r\nContent-Length: 0\r\n\r\n", nil)
            if not keep_alive then
                tcp_client:shutdown(nil)
                tcp_client:close()
            end
        end)
    end)

    io.write(string.format("Server listening at %s:%d", self:get_host(), self:get_port()))

    uv.run("default")
end

return server
