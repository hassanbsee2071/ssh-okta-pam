#!/bin/bash


USERNAME="${PAM_USER}"
SYSTEM_USER="ubuntu"
FILE_PATH="/tmp/$USERNAME"
ADMIN_GROUP="devops"
if [ -f $FILE_PATH ] && [ -s "$FILE_PATH" ] && [ ! -z $(grep '[^[:space:]]' $FILE_PATH) ] && [ "$USERNAME" != "$SYSTEM_USER" ]; then

    TOKEN=$(cat /tmp/$USERNAME)
    PAYLOAD=$(echo $TOKEN | cut -d'.' -f2)
    FULL_EMAIL=$(echo $PAYLOAD | base64 -d 2>/dev/null | jq -r '.preferred_username')
    OKTA_GROUP=$(echo $PAYLOAD | base64 -d 2>/dev/null | jq -r --arg ADMIN_GROUP "$ADMIN_GROUP" '.groups[] | select(. == $ADMIN_GROUP)')
    OKTA_USER=$(echo $FULL_EMAIL | cut -d "@" -f 1 | tr '[:upper:]' '[:lower:]')
    if [[ "$USERNAME" == "$OKTA_USER" ]]; then
            if ! id "$USERNAME" &>/dev/null; then
                STRING=$USERNAME-Arr@y
                PASSWORD=$(echo -n "$STRING" | md5sum | head -c 20)
                if [[ -n $OKTA_GROUP ]]; then
                    echo "A sudo user has been detected"
                    useradd -G sudo -m -d /home/${USERNAME} -s /bin/bash "$USERNAME"
                    if [ -d "/home/${USERNAME}" ]; then
                         echo "User directory already exists. Assigning required permissions."
                         ID=$(id -u ${USERNAME})
                         chown -R $ID:$ID /home/${USERNAME}
                    else
                       echo "A new user directory has been created."

                    fi
                else
                    echo "A non-sudo user has been detected"
                    useradd -m -d /home/${USERNAME} -s /bin/bash "$USERNAME"
                fi
                
                echo "$USERNAME:$PASSWORD" | chpasswd
                echo "Your temporary SSH password is: $PASSWORD" > /home/${USERNAME}/password.txt
                chown "$USERNAME":"$USERNAME" /home/${USERNAME}/password.txt
                chmod 600 /home/${USERNAME}/password.txt
                echo
                echo "***************************************************"
                echo "  Welcome, ${USERNAME}"
                echo "  Your temporary SSH password is: ${PASSWORD}"
                echo "***************************************************"
                echo
            else 
               echo "User already exists..."
            fi
            exit 0
    else 
        echo "Unable to create user. Please use your Syed SSO email address."
        exit 1
    fi


elif [ "$USERNAME" = "$SYSTEM_USER" ]; then
   echo "PAM user is $USERNAME. Allowing access"

else 
   echo "Unable to create user. Please use your Syed SSO email address."
   exit 1
fi

