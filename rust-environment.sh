######################
# SERVER BOOT SETTINGS
######################

# settings take effect every time the server boots

#maxplayers=50
#servername="Rust"

# uncomment this to enable EAC, for Linux clients this must be commented out
#ENABLE_RUST_EAC=1

#######################
# GENERATED MAP SUPPORT
#######################

# range: 1-2147483647, used to reproduce a procedural map.
# default: random seed
#     If you change this value, then a new map will be generated on next boot.
#     The old map will still persist unless `./admin-actions/regenerate-map.sh`
#     is called which deletes all maps
#seed=1

# range: unknown, used to recover a known setting from an existing map.
#salt=

# default: 3000, range: 1000-6000, map size in meters.
#worldsize=3000

####################
# CUSTOM MAP SUPPORT
####################
# If using a custom map, then generated map settings are ignored.

# When self-hosting a map for multiplayer, MAP_BASE_URL is for providing public
# IP address in the URL where clients will connect to download your map.
#MAP_BASE_URL=http://localhost:8000/

# CUSTOM_MAP_URL is for posting a link to a publicly available custom map such
# as a Dropbox download link.
#    Overrides MAP_BASE_URL
#CUSTOM_MAP_URL=https://some-url.com/some-map.map
