local type request = require("direct-http.request")
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

return decoder
