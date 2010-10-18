#this clean up task will be run via a cron job every night at 2400
require 'rubygems'
require File.dirname(__FILE__) + './models'

users = User.all(:expiration_date.lt => DateTime.now)

if users.length > 0
  users.each do |user|
	  user.destroy!
	  puts "Hosed the account #{user.username}" 
  end
else
  puts "No account to expire"
end
