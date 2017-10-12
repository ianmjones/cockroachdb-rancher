#!/bin/sh

#
# Get current container's "number" and name.
NODE_INDEX=`curl -s 'http://rancher-metadata/latest/self/container/service_index'`
NODE_NAME=`curl -s 'http://rancher-metadata/latest/self/container/name'`
NODE_SERVICE=`curl -s 'http://rancher-metadata/latest/self/container/service_name'`
NODE_STACK=`curl -s 'http://rancher-metadata/latest/self/container/stack_name'`

#
# On start up we need to know whether we're the first or not.
LEADER_NAME=`curl -s 'http://rancher-metadata/latest/self/service/containers/0/name'`
echo "Leader name is ${LEADER_NAME}."

JOIN_STRING=""
if [ "${NODE_NAME}" = "${LEADER_NAME}" ]
then
	echo "I'm the lead container."
else
	echo "I'm not the lead container."
	JOIN_STRING="--join=${LEADER_NAME}:26257"
fi

#
# Start the node.
exec /cockroach/cockroach start --insecure ${JOIN_STRING}

echo "Background cockroach process finished, shutting down node."
