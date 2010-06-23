Raggio
======

I found a need for a simple FreeRADIUS web interface, so I created one. Use it for managing User and MAC Address accounts.

Step 1
------
Get your FreeRADIUS running off of MYSQL. I used this great guide for Ubuntu 9.10: http://techtots.blogspot.com/2010/01/installing-and-configuring-freeradius.html

Step 2
------
Install ruby-1.9.1 and rubygems. There are numerous documents on this all over the web.

Step 3
------
Install the required gems:
<code>gem install dm-core dm-aggregates dm-validations dm-serializer do_mysql net-ldap rack-flash sinatra</code>

Step 4
------
Clone the git repository for this project, or download the tarball or zip file and extract the contents.

Step 5 
------
Configure the YAML files.

config/database.yml
<pre>
---
adapter:          mysql       #The database adapter you're using
hostname:         freeRADIUS  #The host on which your FreeRADIUS database lives
database:         radius      #The name of the database FreeRADIUS is using
username:         root        #The username to access your DB
password:                     #The password to access your DB
user_table:       radcheck    #The table you have FreeRADIUS configured to use for authentication -- default is radcheck
mac_table:        radcheck    #The table you have FreeRADIUS configured to use for authentication, typically the same as the user_table -- default is radcheck
mac_password:     nortel      #The password your NAS passes on to the FreeRADIUS Server when using MAC authentication
history_table:    radpostauth #The table you have FreeRADIUS configured to store authentication attempts -- default setup is radpostauth
accounting_table: radacct #The table you have FreeRADIUS configured to store accounting information -- default setup is radacct
</pre>

config/ldap.yml
<pre>
---
server:           domaincontroller1.yourdomain.lan  #FQDN of the Domain Controller you want to Authenticate with for administration
port:             389         #LDAP port that should be used -- default 389
base:             DC=yourdomain,DC=lan      #LDAP search base -- DC=yourdomain,DC=lan will search the entire LDAP structure
domain:           yourdomain.lan      #Your AD domain -- example yourdomain.lan or yourdomain.com
admin_group:      Domain Admins       #Name of the LDAP Group that the user must be a member of to log into the interface and administer it
</pre>

config/other.yml
<pre>
---
other:
  head_title:       RADIUS Management                            #Title in the Header
  dashboard_title:  RAGGIO -- SIMPLE RADIUS MANAGEMENT           #Title for the landing page
  logo_url:         /images/logo.png                             #URL for your main logo -- should be 620px wide 95px tall placed in public/images
  error_500_url:    /images/500.png                              #URL for a fun error 500 pages -- should be 250px wide placed in public/images
  
deploy:
  app_server:       appserver                                    #The hostname or IP of the application server
  app_name:         raggio                                       #The name of your applicaiton
  git_repo:         ssh://git.yourdomain.com/raggio.git          #Location of your Git repo
  deploy_path:      /var/www/apps/raggio                         #Path on the app_server where you want to deploy the application
</pre>

Step 6
------
Start the webserver
<code>ruby raggio.rb</code>

Navigate to http://localhost:4567 and login!

License
=======

Copyright (c) 2010 Daniel Westendorf

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
