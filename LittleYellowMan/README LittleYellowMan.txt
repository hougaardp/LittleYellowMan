Ingame Commands:
/lym move
- Shows icon to move it around
- Move it by holding shift and drag it
- Type /lym move again to hide the icon

/lym <number value 0-100>
- The number value is the percent durability loss needed to trigger the icon
- Default value is 60%

/lym 101
- Simulates gear durability below threshold for testing the icon without having damaged gear
- Use the command and activate a trigger by enter and then leaving combat to test the addon
- Reload the game to reset the value

/lym size
Prints the current size and usage.

/lym size <number value 16-512>
- Sets the size for the icon. Minimum 16, maximum 512.
- Default value is 200
- The icon will appear for 2 seconds so you can see the change.

/lym size reset
- Resets size to the default value

/run LittleYellowManFrame:Show()
- Force-shows the icon. It stays visible until you hide it or reload.

/run LittleYellowManFrame:Hide()
- Hides it again.

/lym sound test
- Plays the sound once so you can hear it.

/lym sound off
- Mutes the alert (saved between sessions).

/lym sound on
Turns it back on.
