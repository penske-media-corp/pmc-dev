#!/bin/bash

rm -f ${SSH_AUTH_SOCK}
/usr/bin/ssh-agent -d -a ${SSH_AUTH_SOCK} &
agent=$!
/usr/local/bin/ssh-key-import &
wait "$agent"
