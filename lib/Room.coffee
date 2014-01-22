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
		
		# Send "create" to the entity
		entity.sendOwner(ness.CREATE, entity.create(entity))
		
		# Sync this user with everyone
		@sendEveryone(ness.CREATE, entity.create(), [entity])
		
		# Get information about everyone else
		for other in @models
			entity.sendOwner(ness.CREATE, other.create()) unless other is entity
		
		console.log "#{@models.length} entity in #{@name}"
		
	entityLeft: (entity) ->
		@sendEveryone(ness.DELETE, entity.delete())
		

module.exports = Room
