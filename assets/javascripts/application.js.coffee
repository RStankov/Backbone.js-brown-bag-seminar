#= require 'vendor/jquery'
#= require 'vendor/jquery_ui'
#= require 'vendor/underscore'
#= require 'vendor/backbone'
#= require 'vendor/backbone_localstorage'
#= require 'vendor/backbone_validations'
#= require 'vendor/handlebars'

#= require_self

App = {}

class App.View extends Backbone.View
  find: (selector) -> $(selector, @el)

  render: ->
    @el.innerHTML = @template(@model.toJSON())
    this

App.templateFor = (view) ->
  Handlebars.compile $("#template-#{view}").html()

class Pin extends Backbone.Model
  defaults:
    number: 0
    x: 220
    y: 300

  validate:
    title: {required: true}
    body:  {required: true}

  edit: -> @trigger 'edit'
  show: -> @trigger 'show'

  number: -> @get 'number'
  x: -> @get 'x'
  y: -> @get 'y'

  setPosition: (position) ->
    {top, left} = position
    @attributes.x = left
    @attributes.y = top

  cancel: ->
    errors = @validate(attributes: @attributes)
    unless errors
      @trigger 'show'
    else
      @destroy()

class Look extends Backbone.Model
  initialize: ->
    @pins = new Pins()

  addPin: ->
    pin = new Pin(number: @pins.maxNumber())
    @pins.add pin
    pin

class Looks extends Backbone.Collection
  model: Look

class Pins extends Backbone.Collection
  model: Pin
  maxNumber: ->
    current = @max((pin) ->  pin.get 'number')?.get('number')
    (current or 0) + 1

class PinMakerView extends App.View
  tagName: 'mark'
  events:
    'drag': 'tracePosition'

  initialize: ->
    @model.bind 'destroy', @remove, this

    $(@el)
      .html(@model.number())
      .draggable(containment: 'parent')
      .css position: 'absolute', top: @model.y(), left: @model.x()

  tracePosition: (e, ui) ->
    @model.setPosition ui.position

class PinView extends App.View
  tagName: 'section'
  template: App.templateFor('pin')

  initialize: ->
    @form = new PinView.Form model: @model
    @display = new PinView.Display model: @model

    @el.innerHTML = @template(@model.toJSON())
    @el.appendChild @form.el
    @el.appendChild @display.el

    @model.bind 'show', @show, this
    @model.bind 'edit', @edit, this
    @model.bind 'destroy', @remove, this

  show: ->
    @form.hide()
    @display.show()

  edit: ->
    @display.hide()
    @form.show()

class PinView.Form extends App.View
  template: App.templateFor('pin-form')
  events:
    'click [data-cancel]': 'cancel'
    'click [data-save]': 'save'

  save: ->
    titleInput = @find('[data-attribute="title"]')
    bodyInput = @find('[data-attribute="body"]')

    attributes =
      title: titleInput.val()
      body: bodyInput.val()

    errors = @model.validate(attributes: attributes)
    unless errors
      @model.set(attributes)
      @model.show()
    else
      titleInput.toggleClass 'error', 'title' of errors
      bodyInput.toggleClass 'error', 'body' of errors

  cancel: ->
    @model.cancel()

  hide: ->
    $(@el).hide()

  show: ->
    @render()
    $(@el).show()
    @find(':input:first').focus()

class PinView.Display extends App.View
  template: App.templateFor('pin-display')
  events:
    'click [data-edit]': 'edit'
    'click [data-delete]': 'destroy'

  edit: ->
    @model.edit()

  destroy: ->
    @model.destroy()

  hide: ->
    $(@el).hide()

  show: ->
    @render()
    $(@el).show()

class LookView extends App.View
  tagName: 'article'
  template: App.templateFor('look')
  events:
    'click [data-delete-look]': 'destroy'
    'click [data-add-pin]': 'addPin'

  initialize: ->
    @model.bind 'destroy', @remove, this
    @model.pins.bind 'add', @pinAdded, this

  destroy: ->
    @model.destroy()

  addPin: ->
    pin = @model.addPin()
    pin.edit()

  render: ->
    @el.innerHTML = @template(@model.toJSON())
    @model.pins.each @pinAdded, this
    this

  pinAdded: (pin) ->
    @find('aside').append new PinView(model: pin).el
    @find('.image-wrapper').append new PinMakerView(model: pin).el

class LooksView extends App.View
  el: '#looks'
  events:
    'click [data-add-look]': 'addLook'

  initialize: ->
    @collection.bind 'add', @lookAdded, this

  addLook: ->
    @collection.add new Look

  lookAdded: (look) ->
    view = new LookView(model: look)
    @find('[data-add-look]').before view.render().el

window.collection = new Looks()
window.view = new LooksView(collection: collection)
