express = require 'express'
app = express()
coffeeMiddleware = require 'coffee-middleware'
fs = require 'fs'
PORT = process.env.PORT

app.use(require('stylus').middleware(__dirname + '/public'));
app.use(express.static('public'))

# Configure browserify middleware to serve client.coffee as client.js
browserify = require('browserify-middleware')
browserify.settings
  transform: ['coffeeify']
  extensions: ['.coffee', '.litcoffee']
app.use '/client.js', browserify(__dirname + '/client.coffee')

app.set 'view engine', 'jade'

app.listen PORT, ->
  console.log "Your app is running on #{PORT}"

# ROUTES

app.get '/', (request, response) ->
  response.render 'index',
    title: 'Detachmentizer',
    messages: ["a"]
