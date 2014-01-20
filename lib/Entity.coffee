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
		
		# Send the UUID to the owner
		@sendOwner('id', @get('id'))
		
		# Bind network update on change
		@on('change', @_updateNetwork)
	
	sendOwner: (id, data) ->
		message = {}
		message[id] = data
		@get('socket').send JSON.stringify message
	
	# Networked GET/SET
	setNetworked: (attrs) ->
		_.each(attrs, (value, key) =>
			# TODO : FILTER N SHIT
			@set(key, value) if value?
		)	
		
	getNetworked: (requester, attrs) ->
		isOwner = _.isEqual(requester, @)
		
		attributes = {id: @get('id')}
		
		_.each(attrs, (value, key) =>
			# TODO : VALIDATE PERMISSION
			attributes[key] = @get(key)
		)
		
		# Send informations to the requester
		requester.sendOwner('get', attributes) if requester.get('socket')?
	
	# Room management
	join: (roomName) ->
		console.log 'join this thang'
		ness.Rooms[roomName].add @

	leave: ->
		# Remove ourself the zone
		@room.remove @
	
	# Action
	actionRequest: (action, data) ->
		action = action.charAt(0).toUpperCase() + action.slice(1)
		
		fn = @['action' + action]
		if typeof fn is 'function'
			fn(data)
		else
			console.log "Client sent an unsupported RPC! #{action}"
	
	# Status sync
	networkSync: (requester=null) ->
		# Is owner?
		isOwner = _.isEqual(requester, @)
		
		# Get the proper attributes
		attrs = @_filterNetworked(@networkedAttributes)
		
		if isOwner then _.extend(attrs[0], attrs[1]) else attrs[1]

	# Private methods
	
	# Sort attributes by person to send it to
	_filterNetworked: (attrs) ->
		# Attributes to send out to everyone
		attributes = {id: @get('id')}
		attributesOwner = {id: @get('id')}
		
		_.each(attrs, (value, key) =>
			if @_mustSync(key)
				console.log value.read
				
				# Store attributes readable by owner only
				attributesOwner[key] = @get(key) if value.read == ness.OWNER_ONLY
				
				# Store attributes readable by everybody
				attributes[key] = @get(key) if value.read != ness.OWNER_ONLY
		)
		
		console.log attributesOwner
			
		return [attributesOwner, attributes];
	
	# Send relevant updates to concerned parties
	_updateNetwork: (model, options) =>
		# Fetch changed attributes that requires sync
		attrs = @_filterNetworked(model.changedAttributes())
		
		# Update the owner
		@sendOwner('get', attrs[0]) if Object.keys(attrs[0]).length > 1
		
		# Trigger sync event
		@room.sendEveryone('get', attrs[1]) if Object.keys(attrs[1]).length > 1 && @zone?
	
	# Should the attribute stay in sync or not
	_mustSync: (key) =>
		# TODO: CACHE SYNCABLES ON MODEL INIT
		return _.has(@networkedAttributes, key)
		
module.exports = Entity