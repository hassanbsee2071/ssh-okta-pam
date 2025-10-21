#!/bin/bash

Color_Off='\033[0m'       # Text Reset
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
Magenta='\e[95m'          # Magenta
# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White
ly_start='\033[33;5;7m'   # Light Yello Start
ly_end='\033[0m'          # Light Yello end
lg_start='\033[32;5;7m'  # Green text with blinking
lg_end='\033[0m'
# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White


# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

###############################################################################################################################################
###############################################################################################################################################
# EMAIL_REGEX="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$"
# EMAIL_REGEX="^[a-zA-Z0-9._%+-]+@syed.com$"
EMAIL_REGEX="^[a-z0-9._%+-]+@syed.com$"
FILE_DIRECTORY="$HOME/.sso"
FILE_PATH="$HOME/.sso/okta-email.txt"
email=""

if [ -d $FILE_DIRECTORY ] && [ -f $FILE_PATH ] && [ -s "$FILE_PATH" ] && [ ! -z $(grep '[^[:space:]]' $FILE_PATH) ]; then
    email=$(cat $HOME/.sso/okta-email.txt)    
else
    while :
    do
        echo ""
        echo -e ${BICyan}"Please enter your email address in lowercase ..."
        echo ""

        read -p 'Email Address: ' email
            if [[ ! $email =~ $EMAIL_REGEX ]]
            then
                echo -e ${LIGHTBLUE}'Please enter correct email address...'
            else
                mkdir -p $FILE_DIRECTORY
                touch $FILE_PATH
                echo "$email" > $FILE_PATH
                
                break
            fi

    done
fi

echo -e ${BIBlue}"Your email address is: $email"
USER=$(echo $email | cut -d "@" -f 1 | tr '[:upper:]' '[:lower:]')
HOST="10.218.115.91"
echo ""

echo -e ${BIBlue}".........."
CMD="ssh ${USER}@${HOST} cat /home/${USER}/password.txt"
OKTA_REGEX="https://sso\.syed\.com[^[:space:]]*"

$CMD 2>&1 | while IFS= read -r line; do
    trimming=$(echo "$line" | sed '/226/d' 2>/dev/null)
    printf '%s\n' "$trimming"
    if [[ "$line" =~ $OKTA_REGEX ]]; then
    okta_url="${BASH_REMATCH[0]}"
    echo -e ${BPurple}"[INFO] Detected Okta URL: $okta_url"

    # Open browser (macOS: open, Linux: xdg-open)
    if command -v open >/dev/null 2>&1; then
      open "$okta_url" >/dev/null 2>&1 &
    elif command -v xdg-open >/dev/null 2>&1; then
      xdg-open "$okta_url" >/dev/null 2>&1 &
    else
      echo "[WARN] No browser open command found."
    fi
  fi

done