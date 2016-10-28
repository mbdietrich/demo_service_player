Hapi = require 'hapi'
status = require 'hapi-status'
http = require 'q-io/http'

score_uri = "http://localhost:8043"

players = {}

server = new Hapi.Server()

server.connection(
  {
    host: 'localhost'
    port: '8042'
  }
)

server.route(
  {
    method: 'POST'
    path: '/player'
    handler: (request, reply) ->
      body = JSON.parse( request.payload.toString() )
      players[body.name] = body
      reply({message: "OK"})
  }
)

server.route(
  {
    method: 'GET'
    path: '/player/{name}'
    handler: (request, reply) ->
      name = request.params.name
      body = players[name]
      if body
        http.request("#{score_uri}/score/#{name}")
        .then( (response) =>
          response.body.read()
          .then( (data) =>
            if response.status == 200
              body.scores = JSON.parse( data.toString() ).map( (i) -> parseInt(i) )
              if body.scores.length > 1
                body.max_score = Math.max( body.scores... )
                body.avg_score = ( body.scores.reduce (a,b)->a+b )/(body.scores.length)
              reply(body)
            else
              status.serviceUnavailable(reply, "Score service is down")
          )
          .catch( (err) =>
            console.log err
            status.internalServerError(reply)
          )
        )
      else
        status.notFound(reply)
  }
)

server.start( (err) =>
    throw err if err
    console.log("Player Service launched at #{server.info.uri}");
)