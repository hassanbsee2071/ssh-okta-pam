#!/bin/bash
SYSTEM_USERS="root|ssm-user|sync|nologin|false|ubuntu"
echo "Checking if there are non sudo users....."
non_sudo_users=$(comm -23 <(cat /etc/passwd | grep -Eiv "$SYSTEM_USERS" | cut -d: -f1 | sort) <(getent group sudo | cut -d: -f4 | tr ',' '\n' | sort))
if [[ -z $non_sudo_users ]]; then
  echo "Could not find any non-sudo users."
else
  for user in $non_sudo_users
  do
    echo "Processing User: $user"
    userdel $user --force
    rm -rf /home/${user}
    echo "User ${user} Deleted.."
  done
fi

echo " "
echo " "
echo " "
echo "Checking if there are sudo users....."
sudo_users=$(getent group sudo | cut -d: -f4 | tr ',' '\n' | grep -Eiv "$SYSTEM_USERS")

if [[ -z $sudo_users ]]; then
  echo "Could not find any sudo users."
else
  for user in $sudo_users
  do
    echo "Processing user: $user"
    userdel $user --force
    echo "User ${user} Deleted.."
  done
fi


