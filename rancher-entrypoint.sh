#!/bin/sh

#
# Get current container's "number" and name.
NODE_CREATE_INDEX=`curl -s 'http://rancher-metadata/latest/self/container/create_index'`
NODE_NAME=`curl -s 'http://rancher-metadata/latest/self/container/name'`

#
# On start up we need to know whether we're the first or not.
JOIN_STRING=""
LEADER_CREATE_INDEX=${NODE_CREATE_INDEX}
LEADER_NAME=${NODE_NAME}

echo "Node Name = ${NODE_NAME}."

SIBLINGS=`curl -s 'http://rancher-metadata/latest/self/service/containers' | cut -d= -f1`
for index in ${SIBLINGS}
do
	SIBLING_CREATE_INDEX=`curl -s "http://rancher-metadata/latest/self/service/containers/${index}/create_index"`
#	SIBLING_STATE=`curl -s "http://rancher-metadata/latest/self/service/containers/${index}/state"`

	echo "Sibling Create Index = ${SIBLING_CREATE_INDEX}."
#	echo "Sibling State = ${SIBLING_STATE}."

#	if [ "${SIBLING_STATE}" = "running" -a ${SIBLING_CREATE_INDEX} -lt ${LEADER_CREATE_INDEX} ]
	if [ ${SIBLING_CREATE_INDEX} -lt ${LEADER_CREATE_INDEX} ]
	then
		LEADER_CREATE_INDEX=${SIBLING_CREATE_INDEX}
		LEADER_NAME=`curl -s "http://rancher-metadata/latest/self/service/containers/${index}/name"`

		echo "New Leader Name = ${LEADER_NAME}."
	fi
done

echo "Final Leader Name = ${LEADER_NAME}."

if [ "${LEADER_NAME}" = "${NODE_NAME}" ]
then
	echo "I'm the lead container."
else
	JOIN_STRING="--join=${LEADER_NAME}:26257"
	echo "I'm not the lead container, joining ${LEADER_NAME}."
fi

#
# Start the node.
exec /cockroach/cockroach start --insecure ${JOIN_STRING}

echo "Background cockroach process finished, shutting down node."
