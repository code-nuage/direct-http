local type i_header = require("direct-http.i_header")

local record request
    method: string
    target: string
    version: string
    headers: {i_header}
    body: string

    new: function(): request
end

function request.new(): request
    return setmetatable({
        headers = {}
    }, { __index = request })
end

function request:get_header(key: string): i_header
    for _, h in ipairs(self.headers) do
        if h.key:lower() == key:lower() then
            return h
        end
    end
end

return request
