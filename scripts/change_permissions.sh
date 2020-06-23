#!/bin/bash
chmod -R 777 /var/www/html/WordPress

### IMPORTANT
# This script updated permissions on the /tmp/WordPress folder so that anyone can write to it. This is required
# so that WordPress can write to its database during Step 5: Update and Redeploy Your WordPress Application. After
# the WordPress application is set up, run the following command to update permissions to a more secure setting:
# chmod -R 755 /var/www/html/WordPress
