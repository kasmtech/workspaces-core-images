# Attempt to set the username to the kasm username
USERNAME=${KASM_USER:-default}
# Make the username posix compliant
USERNAME=$(echo "$USERNAME" | sed -r 's#[^a-zA-Z0-9\._\-]#_#g')
if ! echo "$USERNAME" | grep -qP "^[a-zA-Z0-9_\.][a-zA-Z0-9_\-\.]*"; then
    USERNAME="default"
fi
export PS1="$USERNAME:\w\$ "