local type i_header = require("direct-http.i_header")

local record response
    version: string
    code: integer
    headers: {i_header}
    body: string

    new: function(): response

    add_header: function(self, key: string, value: string): response
end

function response.new(): response
    return setmetatable({
        version = "1.1",
        code = 200,
        headers = {},
        body = ""
    }, { __index = response })
end

function response:add_header(key: string, value: string): response
    table.insert(self.headers, {key = key, value = value})
    return self
end

return response
