# FreePBX on Docker

FreePBX container image for running a complete Asterisk server.

With this container you can create a telephony system in your office or house with integration among various office branches and integration to external VOIP providers with features such as call recording and IVR (interactive voice response) Menus.

### Image includes

 * Debian 9 Stretch with NodeJS 12
 * PHP 5.6
 * Legacy Debian Jessie MySQL ODBC Connector
 * Asterisk 15.7.2
 * Freepbx-14.0-latest
 * Opensource G729 v1.0.4
 * Modules: IVR, Time Conditions, Backup, Recording
 * Automatic backup script
 * Container size: approx 2.3GB

### Run FreePBX image

* Run ```docker-compose up -d```

* Open web admin panel at your raspberry pi's ip-address