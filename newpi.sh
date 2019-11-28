#! /usr/bin/env bash

USERNAME='pi'
REBOOT_WAIT_SECS=5

while getopts ":H:nqU:i:r:" opt; do
  case ${opt} in
    H ) HOSTNAME="${OPTARG}" ;;
    n ) DRY_RUN=1 ;;
    q ) QUIET=1 ;;
    U ) USERNAME="${OPTARG}" ;;
    i ) IP_ADDRESS="${OPTARG}" ;;
    r ) REBOOT_WAIT_SECS="${OPTARG}" ;;
    \? ) echo "Invalid Option: -$OPTARG" 1>&2 && exit 1 ;;
    : ) echo "Invalid Option: -$OPTARG requires an argument" 1>&2 && exit 1 ;;
  esac
done
shift $((OPTIND -1))

#####################################################

step=1
function say() {
  if [[ "$QUIET" != 1 ]]; then
    echo ""
    echo "#####################################"
    echo "##  ${step}. $1"
    echo "#####################################"
    echo ""
    let "step++"
  fi
}

# n. Set the hostname
say "Setting hostname"

HOSTNAME_FILE='/etc/hostname'
HOSTS_FILE='/etc/hosts'

REPLACED_HOSTS_CONTENT=$(sed s/$(hostname)/"$HOSTNAME"/g < "$HOSTS_FILE")

if [[ "$DRY_RUN" == 1 ]]; then
  echo "Would set ${HOSTNAME_FILE} content to ${HOSTNAME}"
  echo "Would replace ${HOSTS_FILE} content with:"
  echo "$REPLACED_HOSTS_CONTENT"
else
  echo "$HOSTNAME" > "$HOSTNAME_FILE"
  echo "$REPLACED_HOSTS_CONTENT" > "$HOSTS_FILE"
  echo "done"
fi

# n. Set aliases
say "Setting aliases"

if [[ "$DRY_RUN" == 1 ]]; then
    echo "Would write aliases to '/home/${USERNAME}/.bash_aliases'"
else
  cat > "/home/${USERNAME}/.bash_aliases" <<EOF
alias rp='source ~/.profile'
alias ll='ls -lA --color'
EOF
  echo "done"
fi

# n. Set variables
say "Setting variables"

if [[ "$DRY_RUN" == 1 ]]; then
  echo "Would write variables to '/home/${USERNAME}/.bash_variables'"
  echo "Would add 'source ~/.bash_variables' to '/home/${USERNAME}/.bash_variables'"
else
  echo "source ~/.bash_variables" >> "/home/${USERNAME}/.bashrc"
  cat > "/home/${USERNAME}/.bash_variables" <<EOF
export PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\n> "
export PS2="\[\033[1;33m\]→ \[\033[m\]"
EOF
  echo "done"
fi

# n. Set network
say "Configuring network settings"

DHCPCD_CONF_FILE='/etc/dhcpcd.conf'
NETWORK_CONFIG="interface eth0\nstatic ip_address=${IP_ADDRESS}/24\nstatic routers=192.168.1.1\nstatic domain_name_servers=192.168.1.7"

if [[ "$DRY_RUN" == 1 ]]; then
  echo "Would add the following to ${DHCPCD_CONF_FILE}:"
  echo -e "$NETWORK_CONFIG"
else
  echo -e "$NETWORK_CONFIG" >> "$DHCPCD_CONF_FILE"
  echo "done"
fi

# n. Install packages
say "Installing packages"

if [[ "$DRY_RUN" == 1 ]]; then
  echo "Would update apt and install packages."
else
    apt-get update -y
    apt-get install -y \
      curl \
      wget \
      vim \
      git \
      dnsutils
fi

# n. Reboot
say "Rebooting in ${REBOOT_WAIT_SECS} seconds"

if [[ "$DRY_RUN" == 1 ]]; then
  echo "Would run: sleep ${REBOOT_WAIT_SECS} && reboot"
else
  sleep "$REBOOT_WAIT_SECS" && reboot
fi
