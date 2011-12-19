#= require 'vendor/jquery'
#= require 'vendor/underscore'
#= require 'vendor/backbone'
#= require 'vendor/backbone_localstorage'
#= require 'vendor/handlebars'

#= require_self

App = {}

class App.View extends Backbone.View
  find: (selector) ->
    $(selector, @el)

  render: ->
    @el.innerHTML = @template(@model.toJSON())
    this

App.templateFor = (view) ->
  Handlebars.compile $("#template-#{view}").html()

class Pin extends Backbone.Model
  defaults:
    number: 0
    title: ''
    body: ''

  edit: -> @trigger 'edit'
  show: -> @trigger 'show'
  cancel: -> @trigger 'show'

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
    current = @.max((pin) ->  pin.get 'number')?.get('number')
    (current or 0) + 1

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
    @model.set
      title: @find('[data-attribute="title"]').val()
      body: @find('[data-attribute="body"]').val()
    @model.show()

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
    view = new PinView(model: pin)
    @find('aside').append view.el

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
