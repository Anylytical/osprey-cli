express = require 'express'
http = require 'http'
path = require 'path'
apiKit = require '../../../dist/middleware/api-kit'

app = express()

app.use express.bodyParser()
app.use express.methodOverride()
app.use express.compress()

# APIKit Configuration
app.use apiKit(__dirname + '/assets/raml/api.raml', app.routes)

app.use '/api/console', express.static(__dirname + '/assets/console')

# TODO: This should be move to the apikit runtime
app.get '/api', (req, res) ->
  if /application\/raml\+yaml/.test(req.headers['accept'])
    res.sendfile __dirname + '/assets/raml/api.raml'
  else
    res.send 415

http.createServer(app).listen(3000)