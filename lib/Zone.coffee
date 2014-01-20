Backbone = require('backbone')
_ = require('underscore')

class Zone extends Backbone.Collection
	initialize: ->
		# TEMPORARY NAME
		@name = 'town'
		
		# Binds join and leave events
		@on 'add', _.bind(@entityJoined, @)
		@on 'remove', _.bind(@entityLeft, @)
		
		super({}, [])

	# Send everyone
	sendEveryone: (type, data, exclude=[]) ->
		for entity in @models
			entity.get('socket').emit(type, data)
	
	# Entity events
	entityJoined: (entity) ->
		# Assign zone to us
		entity.zone = @
		
		# Join the user to the socket.io room
		entity.get('socket').join(@name)

		# Sync this user with everyone
		@sendEveryone('get', entity.networkSync(), [entity])
		
		# Get information from everyone else
		for other in @models
			entity.get('socket').emit('get', other.networkSync())
		
	entityLeft: (entity) ->
		@sendEveryone('action', {id: 'remove', data: id: entity.get('id') })
		
		entity.get('socket').leave(@name)


