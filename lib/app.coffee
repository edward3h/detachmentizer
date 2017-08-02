{ALL_CATEGORIES, find_detachments} = require './detachmentizer.coffee'

{div, ul, li, span} = React.DOM
e = React.createElement
      
class NumberField extends React.Component
  constructor: (props) ->
    super(props)
    @props = props
    
  handleChange: (value) =>
    @props.onNumberChange(@props.name, value)
    
  decrement: (e) =>
    @handleChange(@props.count - 1)
    
  increment: (e) =>
    @handleChange(@props.count + 1)
    
  render: ->
    div
      className: "numberField"
      span
        className: "label"
        "#{@props.name}"
      span
        className: "dec"
        onClick: @decrement
        "-"
      span
        className: "value"
        "#{@props.count}"
      span
        className: "inc"
        onClick: @increment
        "+"
        
class ResultLine extends React.Component
  constructor: (props) ->
    super(props)
    @props = props
    
  render: ->
    r = @props.result
    div
      className: "result #{r.code}"
      span
        className: "desc"
        r.desc
      if r.score > 0
        span
          className: "score"
          "Command Points #{r.score}"
      else
        span
          className: "score"
          "No Battleforged army possible"
      if r.score > 0
        span
          className: "detachments"
          r.detachments.join(", ")
        
class App extends React.Component
  constructor: (props) ->
    super(props)
    @state = 
      catCounts: ALL_CATEGORIES.reduce ((d, o) -> d[o] = 0; d), {}
      max_size: 3
    
  handleCatCountChange: (catName, value) =>
    value = 0 if value < 0
    @setState (prevState, props) ->
      o = prevState.catCounts
      o[catName] = value
      return
        catCounts: o
      
  handleMaxDetsChange: (foo, value) =>
    value = 1 if value < 1
    @setState
      max_size: value
    
  computeResults: =>
    cats = []
    for catName, catCount of @state.catCounts
      cats.push catName for n in [0...catCount]
    results = []
    find_detachments(
      (r) -> results.push(r),
      cats,
      @state.max_size
    )
    results
  
  render: -> 
    div 
      className: "app"
      div
        id: "maxdets"
        e NumberField, 
          name: "Maximum Number of Detachments"
          count: @state.max_size
          onNumberChange: @handleMaxDetsChange
      div
        id: "categories"
        e NumberField, {key:k, name:k, count:v, onNumberChange:@handleCatCountChange}, null for k, v of @state.catCounts
      e "hr", {}, null
      div
        id: "results"
        e ResultLine, {key: r.desc, result: r}, null for r in @computeResults()
    
module.exports = App