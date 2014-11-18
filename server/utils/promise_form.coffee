multiparty  = require 'multiparty'
stream_to_buffer_array = require './stream_to_array'
Promise = require 'bluebird'



module.exports = (request) -> new Promise (resolve, reject) ->
    form = new multiparty.Form(autoFields: true)
    fields = {}
    files = {}

    form.on 'field', (name, value) ->
        fields[name] = value

    form.on 'part', (part) ->
        stream_to_buffer_array part, (err, bufs) ->
            files[part.name] =
                filename: part.filename
                headers: part.headers
                content: Buffer.concat bufs

        part.resume()

    form.on 'error', reject
    form.on 'close', => resolve [fields, files]
    form.parse request