Backbone = require('backbone')
_ = require('underscore')

class Entity extends Backbone.Model
	
	# [KEY] : [SYNC: TRUE/FALSE, READ: OWNER_ONLY, WRITE: OWNER_ONLY]
	networkedAttributes: {}
	zone = null
	
	initialize: ->
		super
		
		# Send the UID to the owner
		@get('socket').emit('self', {id: @get('id')})
		
		# Bind network update on change
		@on('change', @_updateNetwork)
	
	# Networked GET/SET
	setNetworked: (attrs) ->
		_.each(attrs, (value, key) =>
			# TODO : FILTER N SHIT
			@set(key, value) if value?
		)	
		
	getNetworked: (attrs) ->
		isOwner = _.isEqual(socket, @get('socket'))
		
		attributes = {id: @get('id')}
		
		_.each(attrs, (value, key) =>
			# TODO : VALIDATE PERMISSION
			attributes[key] = @get(key)
		)
		
		# Send informations to the requester
		socket.emit('get', attributes) if socket?
	
	# Zone management
	join: (zone) ->
		zone.add @

	leave: ->
		# Remove ourself the zone
		@zone.remove @
	
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
		@zone.sendEveryone('get', attrs[1]) if Object.keys(attrs[1]).length > 1
	
	# Should the attribute stay in sync or not
	_mustSync: (key) =>
		# TODO: CACHE SYNCABLES ON MODEL INIT
		return _.has(@networkedAttributes, key)
		

