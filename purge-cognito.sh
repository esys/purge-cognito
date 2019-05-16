#!/bin/bash 
if [ $# -ne 1 ]; then
	echo "usage: $0 <user-pool-id>"
	exit 0
fi
 
USER_POOL_ID=$1
echo "Will purge poolID [$1]"
read -p "Continue (y/n) ? " yes 
if [ "$yes" != "y" ]; then
	exit 0
fi

CONTINUE=true
ERRORS=()
while [ "$CONTINUE" = true ]; do
	if [ -z "$TOKEN" ]; then
		JSON=`aws cognito-idp list-users  --user-pool-id ${USER_POOL_ID}`
	else
		JSON=`aws cognito-idp list-users  --user-pool-id ${USER_POOL_ID} --pagination-token ${TOKEN}`
	fi

	USERS=$(echo $JSON | jq --raw-output '.Users[] | .Username')

	for U in $USERS; do
		echo "Deleting user ${U}"
		aws cognito-idp admin-delete-user --user-pool-id ${USER_POOL_ID} --username ${U}	
		if [ $? -ne 0 ]; then
			ERRORS+=(${U})
		fi 
	done

	TOKEN=$(echo $JSON | jq --raw-output '.PaginationToken')
	echo "Next page: $TOKEN"
	if [ "$TOKEN" = "null" ]; then
		CONTINUE=false	
	fi
done

printf 'These usernames might not have been deleted:\n%s\n' "${ERRORS[@]}"
