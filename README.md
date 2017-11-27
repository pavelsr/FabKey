# FabKey

Completely opensource Arduino-based access control system for FabLabs/Hackerspaces/any public space wants
cheap access control
Support Wiegand readers with keypad too (like Smartec ST-PR160EK)
Based on software Ardiuno interrupts and timers.
Easy control it via web browser or Telegram bot
Backend is based on Perl.

## Features

* Two Wiegand readers: one with keypad for entrance and one without keypad for exit
* One door relay
* Multiple pins for alarms
* Support of 7 and 8 bit
* keypad code both (universal way of detecting end of transmission)
* Email or(and) Telegram notifications and alarms
* Universal (tested at Arduino Duemilanove + OrangePi but can work with any Arduino and single board linux computer)
* highly configurable code

## Possible configuration  

1. Single-board computer only. Use pigpio or WiringPi libraties for working with Wiegand protocol and control relays. This comfiguration strongly needs optoisolation cause diodes can't save SoC from damage by static electricity from Wiegand readers.
2. Arduino-only (Arduino Yun or Arduino Uno + Ethernet shield).
3. Single-board computer + Arduino or Arduino-based board. Database of users can be stored in Arduino (if not so much users) or in single-board computer.

For more information please check [wiki](https://github.com/FabLab61/FabKey/wiki)


## Running

The simplest way is to run from dockerizing

```
curl -sSL https://get.docker.com | sh # install docker if not installed
cd data # go to dir where you want to place SQLite database
docker run -v ${PWD}:/fabkey/data db.pl -a deploy_db -d data/skud.db
docker run -v ${PWD}:/fabkey/data db.pl -a demo_data -d data/skud.db
docker run -d --name fabkey -e "FABKEY_BOT_TOKEN=<paste_your_token_here>" -e "FABKEY_DBI=dbi:SQLite:dbname=data/skud.db" --privileged -v ${PWD}:/fabkey/data pavelsr/fabkey
```

## config.json Example

```
{
 "FABKEY_BOT_TOKEN": "441592632:AAEACcNg6CXM_As4-zg4m68WrChis547ixt",
 "DBI": "dbi:SQLite:dbname=skud.db",
 "GPIO_MODE": "bcm",
 "DEFAULT_TIMEOUT_SEC": 3,
 "PERMSISSIONS_MODE": "allow",
 "TG_MESSAGE_ACTUALITY_SEC": 30,
 "MAIN_SRV_URL" : "http://127.0.0.1:3010"
}
```


## Managing database



### WebUI and API

Feature is in development :)

Since web ui is not ready yet, now you can use following options to manage database content from browser or terminal (ncurses-based guis)

### [sqlite-web](https://github.com/coleifer/sqlite-web)

For now the best option


### [sqlcrush](https://github.com/coffeeandscripts/sqlcrush)

I have no succeed with this, but you can try

```
sudo apt-get install postgresql libpq-dev
sudo pip install sqlcrush
sqlcrush -t sqlite -d skud.db
```

when editing a database I have a `CRITICAL FAILURE...` [github issue](https://github.com/coffeeandscripts/sqlcrush/issues/7)

### [sqlectron](https://sqlectron.github.io/) (for MySQL and PostgreSQL only now)

```
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt install nodejs

```




## Installation

Check the [wiki](https://github.com/FabLab61/FabKey/wiki)
