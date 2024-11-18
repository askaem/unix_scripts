#!/usr/bin/bash

# This is a utility script that configures the host and patches it on an ongoing basis

##############################################################################
## GLOBAL VARIABLES
DRYRUN=false  # Indicates no actions are taken 
GHOSTMODE=true # Indicates no information is displayed on stdout
LOGFILEDIR=/var/log/custom
LOGFILE=$LOGFILEDIR/updates.log
PACKAGES=("net-tools" "gparted")
##############################################################################


##############################################################################
## FUNCTIONS
check_and_install_package() {
  local PACKAGE="$1"

  # Check if the package is installed
  if dpkg -s "$PACKAGE" >/dev/null 2>&1; then
    log "INFO" "$PACKAGE already installed"
    return 0  # true
  else
    log "INFO" "installing $PACKAGE"
    if ! $DRYRUN; then
        apt -q install -y "$PACKAGE"
    fi

    # Check again to confirm installation
    if dpkg -s "$PACKAGE" >/dev/null 2>&1; then
      log "INFO" "$PACKAGE successfully installed"
      return 0  # true
    else
      log "WARN" "$PACKAGE failed to install"
      return 1  # false
    fi
  fi
}

log() {
  local LEVEL="$1"
  local MESSAGE="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$LEVEL] $MESSAGE" >> $LOGFILE
  if ! $GHOSTMODE; then  
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LEVEL] $MESSAGE"
  fi
}
##############################################################################

##############################################################################
## EXECUTION

# Verify Log File Directory
if ! [ -d $LOGFILEDIR ]; then
    if ! $DRYRUN; then
      mkdir $LOGFILEDIR
      log "INFO" "log directory $LOGFILEDIR did not exist, created it"
    fi
fi

log "INFO" "==> starting config and patch <==" 

# First, verify the proper APT packages are all installed
for package in "${PACKAGES[@]}"; do
    check_and_install_package $package
done

num_updates=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)

log "INFO" "$num_updates packages to update"
apt list --upgradable 2>/dev/null | grep -v "Listing" >> $LOGFILE
if ! $DRYRUN; then
    apt -qq update -y && apt -qq upgrade -y 2>/dev/null >> $LOGFILE
fi
log "INFO" "update complete - validate installation"
##############################################################################
