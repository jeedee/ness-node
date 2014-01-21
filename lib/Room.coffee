Backbone = require('backbone')
_ = require('underscore')
ness = require('./ness')

class Room extends Backbone.Collection
	initialize: ->
		# TEMPORARY NAME
		@name = 'town'
		
		# Binds join and leave events
		@on 'add', _.bind(@entityJoined, @)
		@on 'remove', _.bind(@entityLeft, @)
		
		# Add to the ness rooms object
		ness.Rooms[@name] = @
		
		super({}, [])

	# Send everyone
	sendEveryone: (type, data, exclude=[]) ->
		for entity in @models
			entity.sendOwner(type, data) unless entity in exclude
	
	# Entity events
	entityJoined: (entity) ->
		# Assign room to the entity
		entity.room = @
		
		# Sync this user with everyone
		@sendEveryone('get', entity.sync(), [entity])
		
		# Get information about everyone else
		for other in @models
			entity.sendOwner('get', other.sync()) unless other is entity
		
		console.log "#{@models.length} entity in #{@name}"
		
	entityLeft: (entity) ->
		@sendEveryone('action', {id: 'remove', data: id: entity.get('id') })
		

module.exports = Room
