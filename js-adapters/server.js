var ballroom = require('./ballroom');
var channel = process.argv[2] + "-RedisSUB";

ballroom.listen(channel);
ballroom.register();