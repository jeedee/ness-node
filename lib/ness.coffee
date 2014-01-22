# Clients
module.exports.Clients = []

# Rooms
module.exports.Rooms = {}
		
# Entity and Zone base classes
module.exports.Entity = require('./Entity')
module.exports.Room = require('./Room')
		
# Models to be used for new clients & zones
module.exports.Models = {Client: require('./Entity'), Room: require('./Room')}
		
# Sync constants
module.exports.OWNER_ONLY = 0
module.exports.EVERYONE = 1

# OP constants
module.exports.CREATE = 'c'
module.exports.READ = 'r'
module.exports.UPDATE = 'u'
module.exports.DELETE = 'd'
module.exports.EXECUTE = 'e'
		
# Server itself
module.exports.Server = require('./Server')
