Backbone = require('backbone')
_ = require('underscore')

OWNER_ONLY = 'o'
EVERYONE = 'e'
module.exports.OWNER_ONLY = OWNER_ONLY
module.exports.EVERYONE = EVERYONE

class NModel extends Backbone.Model
	
	# [KEY] : [SYNC: TRUE/FALSE, READ: OWNER_ONLY, WRITE: OWNER_ONLY]
	networkedAttributes: {}
	
	initialize: ->
		super
		
		# Send the UID to the owner
		@get('socket').emit('self', {id: @get('id')})
		
		# Bind network update on change
		@on('change', @_updateNetwork)
	
	# Networked GET/SET
	setNetworked: (socket, attrs) ->
		isOwner = _.isEqual(socket, @get('socket'))
		
		_.each(attrs, (value, key) =>
			# TODO : VALIDATE PERMISSION
			# TODO : FILTER N SHIT
			@set(key, value) if value?
		)	
		
	getNetworked: (socket, attrs) ->
		isOwner = _.isEqual(socket, @get('socket'))
		
		attributes = {id: @get('id')}
		
		_.each(attrs, (value, key) =>
			# TODO : VALIDATE PERMISSION
			attributes[key] = @get(key)
		)
		
		# Send informations to the requester
		socket.emit('get', attributes) if socket?
	
	# Action
	actionRequest: (socket, action, data) ->
		fn = @[action]
		if typeof fn is 'function'
			fn(data)
		else
			console.log "Client sent an unsupported RPC! #{action}"
	
	# Status sync
	networkSync: (requester=null) ->
		isOwner = _.isEqual(requester, @)
		
		attrs = @_filterNetworked(@networkedAttributes)

		if isOwner then attrs[0] else attrs[1]

	# Private methods
	
	# Sort attributes by person to send it to
	_filterNetworked: (attrs) ->
		# Attributes to send out to everyone
		attributes = {id: @get('id')}
		attributesOwner = {id: @get('id')}
		
		_.each(attrs, (value, key) =>
			if @_mustSync(key)
				# Store attributes readable by owner only
				attributesOwner[key] = @get(key) if value.read == OWNER_ONLY
				
				attributes[key] = @get(key) if value.read != OWNER_ONLY
		)
			
		return [attributesOwner, attributes];
	
	# Send relevant updates to concerned parties
	_updateNetwork: (model, options) =>
		# Fetch changed attributes that requires sync
		attrs = @_filterNetworked(model.changedAttributes())
		
		# Update the owner
		@get('socket').emit('get', attrs[0]) if Object.keys(attrs[0]).length > 1
		
		# Trigger sync event
		@trigger('networkSync', @, attrs[1]) if Object.keys(attrs[1]).length > 1
	
	# Should the attribute stay in sync or not
	_mustSync: (key) =>
		# TODO: CACHE SYNCABLES ON MODEL INIT
		return _.has(@networkedAttributes, key)
		

class NCollection extends Backbone.Collection
	initialize: ->
		@name = 'town'
		
		@on('add', (model, data) =>
			model.get('socket').join(@name)
			
			# Send everyone's info of this user
			for room in _.keys(io.sockets.manager.roomClients[model.get('socket').id])
				model.get('socket').broadcast.to(room).emit('get', model.networkSync())
			
			# Get sync data of nearby clients
			for other in global.zones[@name].models
				console.log other.get('id')
				model.get('socket').emit('get', other.networkSync())
		)
		
		@on('remove', (model, data) ->
			model.get('socket').leave(@name)
		)
		
		@on('networkSync', (model, data) ->
			for room in _.keys(io.sockets.manager.roomClients[model.get('socket').id])
				console.log 'send ' + data
				io.sockets.in(room).emit('get', data)
		)
		
		@on('sendEveryone', (model, type, data) ->
			for room in _.keys(io.sockets.manager.roomClients[model.get('socket').id])
				io.sockets.in(room).emit(type, data)
		)
		
		super({}, [])
	

module.exports.NModel = NModel
module.exports.NCollection = NCollection