Backbone = require('backbone')
_ = require('underscore')
ness = require('./ness')

class Entity extends Backbone.Model
	# Current room
	room = null
	
	# [KEY] : [SYNC: TRUE/FALSE, READ: OWNER_ONLY, WRITE: OWNER_ONLY]
	networkedAttributes: {}
	
	initialize: ->
		super
		
		# Generate a UUID
		@set('id', require('hat')(64))
		
		# Bind network update on change
		@on('change', @updatePeers)
	
	onClose: ->
		# Remove the room
		@leave()
	
	# Send message
	sendOwner: (op, data) ->
		message = {}
		message['op'] = op
		message['data'] = data
		@get('socket').send JSON.stringify message if @get('socket')?
	
	###
	CRUDE (CRUD + Execute)
	###
	# Status sync -- Overrides backbone sync
	create: (requester=null) ->
		# Is owner?
		isOwner = _.isEqual(requester, @)
		
		console.log isOwner
		# Get the proper attributes
		attrs = @filterNetworked(@networkedAttributes)
		
		if isOwner then _.extend(attrs[0], attrs[1]) else attrs[1]
	
	# Get data from a networked client
	read: (requester, attrs) ->
		isOwner = _.isEqual(requester, @)
		
		# Set to the id of the entity
		attributes = {id: @get('id')}
		
		# Parse JSON if not an array
		try
			attrs = JSON.parse(attrs) unless attrs instanceof Array
		catch
			return {}
		
		for key in attrs
			# TODO : VALIDATE PERMISSION
			attributes[key] = @get(key)
		
		# Send informations to the requester
		requester.sendOwner(NESS.UPDATE, attributes) if requester.get('socket')?
	
	# Set data from a networked client (owner)
	update: (attrs) ->
		kv = {}
		
		_.each(attrs, (value, key) =>
			# TODO : FILTER N SHIT
			kv[key] = value if value?
		)
		
		@set(kv)
	
	delete: ->
		{id: @get('id')}
	
	# Run an RPC on this entity. It must have the correct method prefix (rpc)
	execute: (data) ->
		# Parse method and parameters
		method = data.method.charAt(0).toUpperCase() + data.method.slice(1)
		parameters = data.parameters
		
		# Check if the method exists
		fn = @['__' + method]
		if typeof fn is 'function'
			# Invoke method with params
			fn(parameters...)
		else
			console.log "Client sent an unsupported RPC! [#{method}]"
	
	remoteExecute: (method, parameters...) ->
		message = {}
		message['method'] = method
		message['id'] = @get('id')
		#message['parameters'] = "[\"#{parameters.join("\",\"")}\"]"
		message['parameters'] = parameters
		
		return message
	
	# Room management
	join: (roomName) ->
		# Remove if already in a room
		@leave() if @room?
		
		ness.Rooms[roomName].add @
	
	leave: ->
		# Remove ourself the zone
		@room.remove @
	
	# Parse an incoming message from this entity
	parseMessage: (action, data) ->
		switch action
			# New API
			# c
			when 'r' then @read(@, data)
			when 'u' then @update(@, data)
			# d
			when 'e' then @execute(data)
	
	# Private methods
	
	# Sort attributes by person to send it to
	filterNetworked: (attrs) ->
		# Attributes to send out to everyone
		attributes = {id: @get('id')}
		attributesOwner = {id: @get('id')}
		
		_.each(attrs, (value, key) =>
			if @mustSync(key)
				# Store attributes readable by owner only
				attributesOwner[key] = @get(key) if value.read == ness.OWNER_ONLY
				
				# Store attributes readable by everybody
				attributes[key] = @get(key) if value.read != ness.OWNER_ONLY
		)
			
		return [attributesOwner, attributes];
	
	# Send relevant updates to concerned parties
	updatePeers: (model, options) =>
		# Fetch changed attributes that requires sync
		attrs = @filterNetworked(model.changedAttributes())
		
		# Update the owner
		@sendOwner(ness.UPDATE, attrs[0]) if Object.keys(attrs[0]).length > 1
		
		# Send the new attributes to everybody
		@room.sendEveryone(ness.UPDATE, attrs[1]) if Object.keys(attrs[1]).length > 1 && @room?
	
	# Should the attribute stay in sync or not
	mustSync: (key) =>
		# TODO: CACHE SYNCABLES ON MODEL INIT
		return _.has(@networkedAttributes, key)

module.exports = Entity