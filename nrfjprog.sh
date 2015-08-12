#!/usr/bin/env bash

# nrfprog - a loose shell port of nrfjprog.exe for bash

#### CONSTANTS

JLINK="JLinkExe -device nrf51822 -if swd -speed 1000"

read -d '' USAGE <<- EOF
nrfprog.sh

This is a loose shell port of the nrfjprog.exe program distributed by Nordic,
which relies on JLinkExe to interface with the JLink hardware.

usage:

nrfjprog <action> [hexfile]

where action is one of
  --reset
  --pinreset
  --erase-all
  --program
  --programs
  --rtt
EOF

GREEN="\033[32m"
RESET="\033[0m"
SCRIPT="/tmp/$(basename $0).$$.jlink"

#### FUNCTIONS

reset ()
{
    echo ""
    echo -e "${GREEN}resetting...${RESET}"
    echo ""
    echo "r"     > "$SCRIPT"
    echo "g"    >> "$SCRIPT"
    echo "exit" >> "$SCRIPT"
    $JLINK "$SCRIPT"
    rm "$SCRIPT"
}

pinreset ()
{
    # Magic incantations from
    # https://devzone.nordicsemi.com/question/18449/pin-reset-nrfjprog-p-equivalent-using-jlinkexe/
    echo ""
    echo -e "${GREEN}resetting with pin...${RESET}"
    echo ""
    echo "w4 40000544 1" > "$SCRIPT"
    echo "si 0"         >> "$SCRIPT"
    echo "tck0"         >> "$SCRIPT"
    echo "t0"           >> "$SCRIPT"
    echo "sleep 10"     >> "$SCRIPT"
    echo "t1"           >> "$SCRIPT"
    echo "exit"         >> "$SCRIPT"
    $JLINK "$SCRIPT"
    rm "$SCRIPT"
}

erase-all ()
{
    echo ""
    echo -e "${GREEN}perfoming full erase...${RESET}"
    echo ""
    echo "w4 4001e504 2"  > "$SCRIPT"
    echo "w4 4001e50c 1" >> "$SCRIPT"
    echo "sleep 100"     >> "$SCRIPT"
    echo "r"             >> "$SCRIPT"
    echo "exit"          >> "$SCRIPT"
    $JLINK "$SCRIPT"
    rm "$SCRIPT"
}

flash ()
{
    echo ""
    echo -e "${GREEN}flashing ${1}...${RESET}"
    echo ""
    echo "r"            > "$SCRIPT"
    echo "loadfile $1" >> "$SCRIPT"
    echo "r"           >> "$SCRIPT"
    echo "g"           >> "$SCRIPT"
    echo "exit"        >> "$SCRIPT"
    $JLINK "$SCRIPT"
    rm "$SCRIPT"
}

flash-softdevice ()
{
    echo ""
    echo -e "${GREEN}flashing softdevice ${HEX}...${RESET}"
    echo ""

    # Write to NVMC to enable erase, do erase all, wait for completion. reset
    echo "w4 4001e504 2"  > "$SCRIPT"
    echo "w4 4001e50c 1" >> "$SCRIPT"
    echo "sleep 100"     >> "$SCRIPT"
    echo "r"             >> "$SCRIPT"

    # Write to NVMC to enable write. Write mainpart, write UICR. Assumes device is erased.
    echo "w4 4001e504 1" >> "$SCRIPT"
    echo "loadfile $1"   >> "$SCRIPT"
    echo "r"             >> "$SCRIPT"
    echo "g"             >> "$SCRIPT"
    echo "exit"          >> "$SCRIPT"
    $JLINK "$SCRIPT"
    rm "$SCRIPT"
}

rtt ()
{
    # trap the SIGINT signal so we can clean up if the user CTRL-C's out of the
    # RTT client
    trap ctrl_c INT
    echo -e "${GREEN}Starting RTT Server...${RESET}"
    JLinkExe -device nrf51822 -if swd -speed 1000 &
    JLINK_PID=$!
    sleep 1
    echo -e "\n${GREEN}Connecting to RTT Server...${RESET}"
    #telnet localhost 19021
    JLinkRTTClient
    echo -e "\n${GREEN}Killing RTT server ($JLINK_PID)...${RESET}"
    kill $JLINK_PID
}

ctrl_c ()
{
    return
}

#### MAIN

if [ $# -eq 0 ]; then
    echo "$USAGE" >&2
    exit 1
else
    while [ "$1" ]; do
        case "$1" in
            -r | --reset) reset
                          ;;
            --pinreset)   pinreset
                          ;;
            --erase-all)  erase-all
                          ;;
            --program)    shift
                          flash "$1"
                          ;;
            --programs)   shift
                          flash-softdevice "$1"
                          ;;
            --rtt)        rtt
                          ;;
            *)            echo "unexpected option '$1'" >&2
                          exit 1
        esac
        shift
    done
fi
