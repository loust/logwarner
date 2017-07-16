#!/bin/bash

################### USAGE ###################
#                                           #
#    logwarner.sh 7 whitelist.file          #
#                 ^       ^                 #
#       IP location       whitelist file    #
#                                           #
#############################################

#############################################
############### VERSION 2.1 ################# 
#############################################
# TODO Add parameter functionality          #
#   ie. make it so, if $2 is not def, then  #
#       create a new whitelist via `ed`     #
#############################################

## In some Operating Systems, awk displays the position at 7.
## Check what yours is.
iploc=$1
idloc=$(expr $iploc - $1)

## This will get the IP address depending on the location you
## set and then cut the first character, reverse, cut the first character
## reverse. Thus, removing the ( and ) characters.
whou=$(who -u | awk "{print \$$iploc}" | cut -c2- | rev | cut -c2- | rev)

# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
# https://www.linuxjournal.com/content/validating-ip-address-bash-script
function valid_ip() {
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


## Main loop. Go forever!
echo -n Scanning
while true; do
    ## Reduce infinite cycle
    sleep 1
    ## Boolean to find if an IP is detected
    detected=0

    ## get the IP addresses ONLY and put them into a file
    for ip in $whou; do
        # put valid IP in a file
        if valid_ip $ip; then
            echo $ip >> ./iplist.ips
            #echo $whoid >> ./idlist.ids
        else
            echo -n :
        fi
    done

    # read contents from both files
    while IFS='' read -r ipsFile || [[ -n "$ipsFile" ]]; do
        for filterIP in $ipsFile; do
            while IFS='' read -r whitelistFile || [[ -n "$whitelistFile" ]]; do
                for whitelist in $whitelistFile; do
                    # compare both in 2 loops
                    if [[ "$filterIP" == "$whitelist" ]]; then
                        detected=0
                        echo -n .
                        break
                    else
                        detected=1
                        break
                    fi
                done
            done < $2
        done
    done < iplist.ips

    ## Detected message
    ## Alternatively, you can make it so it just warns and not kills
    if [[ detected -eq 1 ]]; then
        echo -n " >> " Kicking $filterIP " << "
        kill $(who -u | grep $filterIP | awk "{print \$$idloc}")
    fi

    ## Truncate file
    $(> ./iplist.ips)
done
