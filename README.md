# ExtendedTrafficLights
Extended Traffic Lights for FlightGear

## About
Make other multiplayer pilots easier to see. Just like FSX. See them up to 50nm away.

![Example](https://i.imgur.com/vxOi25X.jpg)

![Example](https://i.imgur.com/acbB1sI.jpg)

### Requirements

FlightGear 2017.x version.

### Install Procedures

Unzip extended_traffic_lights folder to any place you want. e.g C:\Users\USERNAME\Documents\FlightGear\Addons\extended_traffic_lights

Then add this command line to your FlightGear Shortcut :

--addon="C:\Users\USERNAME\Documents\FlightGear\Addons\extended_traffic_lights"

Note that this command line must have the correct path to the extended_traffic_lights folder.
Do not know how to set command lines? Check here: http://wiki.flightgear.org/Command_line

### Dealing with errors

This addon is not compatible with RESET option for now. Sorry.

### Configurations

This addon is enabled by default. If you want it to start disabled you can :

To enable or disable it go to extended_traffic_lights folder and open config.xml. Find defaultON line.

```<defaultON>0</defaultON>```

Change defaultON value ( 1 for yes and 0 for no ). Restart your simulator. Done.

### Using
Open addon dialog by pressing menubar Multiplayer > Entended Traffic Lights.
Enable / Disable the addon from the dialog.
Enable / Disable the label with info from the dialog (not implemented yet)

### TODO

Label showing informations about the pilot.

![Example](https://i.imgur.com/3ULqaaA.jpg)