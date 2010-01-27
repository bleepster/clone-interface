Background
==========
I was in a situation where I had to simulate PPPoE connections. Each connection
required a unique MAC Address. However, I only had one PC. These scripts answered
that *desperate* need.

Dependencies
============
* netgraph(3)

Platform
========
* FreeBSD

Usage
=====
    # ./clone_if.sh <interface> <max number of clones> <bridge name>
    # ./kill_clones.sh <bridge name>
