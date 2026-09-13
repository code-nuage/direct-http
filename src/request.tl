local type http_header = require("iheader")

local record request
    --+ Properties +--
    method: string
    target: string
    version: string
    headers: {http_header}
    body: string

    --+ Constructor +--
    new: function(): request

    --+ Setters +--
    set_method: function(self, method: string): request
    set_target: function(self, target: string): request
    set_version: function(self, version: string): request
    set_headers: function(self, headers: {http_header}): request
    add_header: function(self, header: http_header): request
    set_body: function(self, body: string): request

    --+ Getters +--
    get_method: function(self): string = macroexp(self: request): string
        return self.method
    end
    get_target: function(self): string = macroexp(self: request): string
        return self.target
    end
    get_method: function(self): string = macroexp(self: request): string
        return self.version
    end
    get_headers: function(self): {http_header} = macroexp(self: request): {http_header}
        return self.headers
    end
    get_header: function(self, key: string): http_header
    get_body: function(self): string = macroexp(self: request): string
        return self.method
    end
end

--+ Constructor +--
function request.new(): request
    return setmetatable({}, {__index = request})
end

--+ Setters +--
function request:set_method(method: string): request
    self.method = method
    return self
end

function request:set_target(target: string): request
    self.target = target
    return self
end

function request:set_version(version: string): request
    self.version = version
    return self
end
function request:set_headers(headers: {http_header}): request
    self.headers = headers
    return self
end

function request:add_header(header: http_header): request
    table.insert(self:get_headers(), header)
    return self
end

function request:set_body(body: string): request
    self.body = body
    return self
end


--+ Getters +--
function request:get_header(key: string): http_header
    for _, header in ipairs(self:get_headers()) do
        if header.key == key:lower() then return header end
    end
end

return request
