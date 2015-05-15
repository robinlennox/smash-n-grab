smash-n-grab
============

Quickly search Windows machines for useful information

## Introduction

While Pen testing, I have found many Windows Machines ripe for the picking. But I have never had a script I can quickly use to search for certain file types on the local computer then save them locally.

So I created a script using a batch that demonstrates that even the applications shipped with Windows, Network Surveillance is possible without triggering AV!

I've been mainly working in an Windows XP and 8 environment as an Administrator.

This is a work in progress... Feedback is welcome.

## What can it do?

* Use switches!
* Search for certain files types
* Search all connected drives
* Limit search to certain size
* Gather Local Information
	* Local accounts
	* Display user account password and logon requirements
	* Return the workstation name, user name, version of Windows, network adapter, network adapter information/MAC address, Logon domain, COM Open Timeout, COM Send Count, COM Send Timeout.
	* Return the local groups on the local machine.
	* Return the local shares on the local machine.
	* Return the user accounts from the Primary Domain Controller (PDC) of the current domain
	* Display user account password and logon requirements.
	* Return the server name, version of Windows, active network adapter information/MAC address, Server hidden status, Maximum Logged On Users, Maximum open files per session, Idle session time.
	* Return the global groups on the PDC of the current domain.
	* Return the resources in the specified domain.
* Grab Netstat info
* Grab Run History
* Grab Open Document History
* Grab recent MSTSC (Terminal Client History)
* Search Registry for certain keywords
* Intrusive Options
	* Copy recently opened files

## Future

* Lookup shares on Domain Computers.
* Copy other files such as KeePass file, private keys, but not search.
* Check where lnk files originate from.
* Don't search certificates for keywords.
* Don't scan the same share more than once.
* Check root domain of FQDN. I.E. (\\filestore.myorg.internal\ to \\myorg.internal\)

## Limitations

* File/Folder character length cannot be longer that 160. (This is a Windows Limit)
* Doesn't find recent files in Windows 8.
* Doesn't find recent files for all Microsoft Office Versions.

## Issues

* Batch stops when share is password protected.
