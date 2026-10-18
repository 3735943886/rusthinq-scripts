# MQTT topics and prefix migration

The host's `[drivers] topic_prefix` is the only prefix setting. Drivers use
`ctx.device_topic()`; IL descriptors are retained at `<prefix>/<id>/descriptor`,
values at `<prefix>/<id>/<prop>`, commands at `<prefix>/<id>/<prop>/set`.
The descriptor's `x-mqtt` records the state and command patterns.
`il_config_common.rhai` is no longer loaded; remove old local copies.
Consumers previously listening to `il/<id>` (or a custom IL prefix) must switch
to the new descriptor topic.

## Clean retained messages before changing mappings

Changing a prefix does not move or erase messages already retained by the broker.
The scripts cannot discover previous prefixes. Use the host's durable retained
inventory and deletion API **before** changing the prefix or upgrading the old
IL descriptor mapping:

1. Keep the current host configuration and its existing inventory file. Pause
   appliance/bridge activity so old topics are not republished during cleanup.
2. Using the management API's configured authentication, send
   `POST /api/mqtt/retained/delete` with JSON `{"scope":"all"}`. This deletes
   **all retained topics owned by this host's inventory**, including descriptors
   under the old IL prefix; it does not clear unrelated broker topics.
   For selective cleanup the API also supports owner or exact-topic scopes.
3. Wait for confirmed completion. A timeout is an unknown outcome; inspect/retry
   through the host before migrating. Stop the host and change the prefix/update
   scripts. Keep the inventory and its lock files intact.
4. Restart and reconnect appliances to publish the new descriptor and values.
   Update external subscribers and publishers to the new paths.

The host can publish again while running: do not assume one deletion request
prevents future reports. Ensure old publishers are quiescent until stopped.
Do not delete the inventory file as a substitute for deleting broker messages.
If the inventory is missing, enumerate the old retained topics using a broker
client and publish an empty retained payload to each **exact topic**. MQTT
wildcards cannot be used as publish destinations. Limit this to verified topics
owned by this deployment.

See the host's [retained ownership and deletion documentation](https://github.com/3735943886/rusthinq/blob/master/docs/0.2-operations.md#retained-ownership-and-deletion)
for scope formats, durable retries and broker-specific inventory constraints.
