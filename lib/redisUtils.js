redis=require("redis");
async=require("async");

redis.RedisClient.prototype.delPattern = function(key, callback) {
    var redis = this
    callback=callback||function(){}
    redis.keys(key, function(err, rows) {
        async.each(rows, function(row, callbackDelete) {
            redis.del(row, callbackDelete)
        }, callback)
    });
};