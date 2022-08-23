#!/bin/bash
echo -e "Docker image built $(cat /.version), starting $(basename ${BASH_SOURCE[0]}) $@"

# We need this user mask to allow groups & other to have full access to avoid permission denied
# on folder mapped outside of the docker container
umask 000

# Trick to run the script in current session context to allow the exposure of any export environment variable to the current shell session
# This method treat the source on these files as an extension of the current script as include
. <(cat `dirname $0`/*configure-env*)

. <( cat /usr/local/bin/*-functions.sh )

# Run parts execute each individual script in its own shell session, any export constant with the script will not get expose to current shell session
run-parts --regex=configure-app `dirname $0`

# Inherit the scripts from wpdev/pipeline container
run-parts --regex=configure-app /usr/local/bin

if [[ -n "$1" ]]; then
	case "$1" in
		start-wp)
			shift
			bash /usr/local/bin/start.sh $@
			;;
		init-wp)
			shift
			bash /pmc-dev/bin/init-wp $@
			;;
		shell)
			shift
			/bin/bash $@
			;;
# Do not add any further commands after this line
		*)
			cmd=$1
			shift
			$cmd $@
		;;
	esac
fi
