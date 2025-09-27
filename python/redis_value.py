import redis

# Connect to the Redis cluster
redis_client = redis.StrictRedis(host='sessions.egiiw5.ng.0001.euw1.cache.amazonaws.com', port=6379, decode_responses=True)

key = "dpo-enc-scb"

# Check if the key exists
if redis_client.exists(key):
    value = redis_client.get(key)
    print(f"The value for '{key}' is: {value}")
else:
    print(f"The key '{key}' does not exist.")
