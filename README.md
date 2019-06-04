# Autojump script for MTA:SA


**Welcome to the Autojump Github Repository!**

This script allows the creation of scripted vehicle jumps within the map editor itself and including them in your map. The script gets automatically added to your map when you save it so you don't have to copy files or edit your meta.xml.

## Usage
1. Add `autojump` to your map definitions (the green notebook icon on top of the map editor)
2. Create `autojumpstart` and `autojumpend` objects where you want the jump to begin and end, respectively.
3. Configure `autojumpstart`:
	* `precision`: How accurately the player should make the jump. 0 means the autojump will be performed always, and 1 means the player vehicle rotation should match exactly the autojumpstart rotation.
	* `speed`: The final speed of the jump (when the player reaches the autojumpend), 1 means full speed.
	* `duration`: The duration of the jump in seconds (2 works fine mostly).
	* **Don't forget to configure the autojumpend that corresponds to this autojumpstart**

## How to add the script to your map

This is done automatically when you save your map (**not quicksave**). A message will be shown in chatbox confirming this.

## Download
**Important:** The file name must be `autojump.zip`, change it if it's not.

[Download v1.0](https://github.com/javier2409/autojump/archive/v1.0.zip) 
