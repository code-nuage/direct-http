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
    local host = self:get_host()
    local port = self:get_port()

    local tcp_server: uv.Tcp = uv.new_tcp(nil)

    assert(tcp_server:bind(host, port, nil))
    tcp_server:listen(128, function()
        local tcp_client: uv.Tcp = uv.new_tcp(nil)
        tcp_server:accept(tcp_client)

        tcp_client:read_start(function(err: string, chunk: string)
            assert(not err, err)
            if chunk then
                tcp_client:write(chunk, nil)
            else
                tcp_client:shutdown(nil)
                tcp_client:close()
            end
        end)
    end)

    print(string.format("Server listening at %s:%d", host, port))

    uv.run("default")
end

return server
