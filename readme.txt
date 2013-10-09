###############################################################################################
#                                                                                             #
# The Wireless Attack Toolkit (WAT) is a quick and easy to use bash script for setting        #
# up a malicious access point. The goal of this tool is to be able to quickly demo this       #
# type of attack on Backtrack 5r3.This tool does not currently include SSL traffic capture    #
# as SSLStrip seems to be having issues in a fully updated Backtrack 5r3 environment. I will  #
# add this in later once it works.                                                            #
#                                                                                             #
###############################################################################################

v0.1 - 9.12.2013                                                                            #

The purpose of this tool is to assist in demoing a rouge AP attack against clients. 
This tool is currently in an Alpha stage. 
Expect additional development as time permits.

>>>Built for fully patched BT5r3 VM with Alpha USB wireless card.<<<

Currently integrated tools:

+Driftnet
+URLSnarf
+DSniff
+Airbase-ng
+Ferret / Hamster
+Wireshark