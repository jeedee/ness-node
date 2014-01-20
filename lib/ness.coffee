module.exports = (port=8080) ->
	clients = []
	
	OWNER_ONLY = 'o'
	EVERYONE = 'e'

	module.exports.OWNER_ONLY = OWNER_ONLY
	module.exports.EVERYONE = EVERYONE

	# Server
	server = new (require('ws').Server)({port: 8080});
	
	# Handle new connection
	server.on 'connection', (client) ->
		clients << client
	
	# Exports
	return {
		Server: server
		Entity: require('./Entity')
		Zone: require('./Zone')
	}