local type response = require("direct-http.response")

local record encoder
    new: function(): encoder

    encode: function(self, res: response): (boolean, string)

    encode_start_line: function(self, res: response): (boolean, string)
    encode_headers: function(self, res: response): (boolean, string)
    encode_body: function(self, res: response): (boolean, string)
end

return encoder
