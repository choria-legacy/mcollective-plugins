DSH Application
===============

This application provides an example of using mcollective discovery to
populate the machines list of Dancer's Shell. This is so you can execute remote
commands using SSH, but with the power of MCollective discovery.

Examples
--------

To do a concurrent ls -la on all hosts.

    mco dsh -- -c ls -la

To run df -h sequentially on all Debian hosts:

    mco dsh --wf='operatingsystem=Debian' -- -c -- ls -la

