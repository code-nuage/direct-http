local record http
    record server
        host: string
        port: integer

        new: function(host: string, port: integer): server

        start: function(self, function(req: http.request, res: http.response)): boolean
    end

    record request
        method: string
        target: string
        version: string
        headers: {i_header}
        body: string

        new: function(): request
    end
end

return http
