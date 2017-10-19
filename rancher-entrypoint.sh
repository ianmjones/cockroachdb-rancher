#!/bin/bash

#
# Get current container's name.
NODE_NAME=`curl -s 'http://rancher-metadata/latest/self/container/name'`
echo "Node Name = ${NODE_NAME}."

#
# Wait between 1 to 10 seconds in the hope that at least one container "wins" and becomes the leader when they all start at the same time.
WAIT_TIME=$(( ( RANDOM % 10 )  + 1 ))
echo "Waiting for ${WAIT_TIME} seconds before attempting to start..."
sleep ${WAIT_TIME}
echo "...starting up."


#
# On start up we need to know whether we can join already running nodes.
JOIN_STRING=""


SIBLINGS=`curl -s 'http://rancher-metadata/latest/self/service/containers' | cut -d= -f1`
for index in ${SIBLINGS}
do
	SIBLING_NAME=`curl -s "http://rancher-metadata/latest/self/service/containers/${index}/name"`
	SIBLING_STATE=`curl -s "http://rancher-metadata/latest/self/service/containers/${index}/state"`

	echo "Sibling Name = ${SIBLING_NAME}."
	echo "Sibling State = ${SIBLING_STATE}."

	if [ "${SIBLING_STATE}" = "running" -a "${SIBLING_NAME}" != "${NODE_NAME}" ]
	then
		JOIN_STRING="${JOIN_STRING} --join=${SIBLING_NAME}:26257"
	fi
done

if [ -z "${JOIN_STRING}" ]
then
	echo "I'm the first container."
else
	echo "I'm not the first container, using join params: ${JOIN_STRING}."
fi

#
# Start the node.
exec /cockroach/cockroach start --insecure --store=/cockroach/cockroach-data/${NODE_NAME} ${JOIN_STRING}

echo "Background cockroach process finished, shutting down node."
