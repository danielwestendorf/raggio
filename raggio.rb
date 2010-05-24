require 'rubygems'
require 'sinatra'
require 'yaml'
require 'lib/active_directory_user'
require 'models'
require 'rack-flash'

enable :sessions
use Rack::Flash

config = YAML::load(File.read(File.dirname(__FILE__) + '/config/other.yml'))
set :head_title, config["other"]["head_title"]
set :dashboard_title, config["other"]["dashboard_title"]
set :logo, config['other']['logo_url']
set :error_img, config['other']['error_500_url']


#don't require login to access these resources
whitelist = [
	"/", #route
	"/login", #route
	"/logout", #route
	"/images", #asset
	"/stale", #asset
	"/js", #asset
	"/css", #asset
	"/favicon.ico" #asset
]

before do
	split = request.path.split("/")
	split.empty? ? path = "/" : path = "/" + split[1] #grab the path being requested
	if !whitelist.include?(path) && !session[:username] #if the path isn't whitelisted and there isn't a username session variable do the following
		session[:request_path] = request.path #remember where the user wants to go, if they login with the next request we'll take them there
		flash[:error] = "You are required to log in before you can proceed"
		redirect "/"
	elsif session[:request_path] && session[:username] && !whitelist.include?(path) #if it isn't white listed and the user is logged in and there was a previously requested path, redirect them to that path.
		path = session[:request_path]
		session[:request_path] = nil
		redirect path
	end
end

helpers do
	
	def format(date)
		date.strftime("%m/%d/%Y @ %I:%M%p") #format for date and time
	end
	
	def expire_format(date)
		date.strftime("%m/%d/%Y") if date #format just for date
	end
	
	def error_header(count)
		if count > 1
			"There were #{count} errors detected"
		else
			"There was #{count} error detected"
		end
	end
	
	def error_messages_for(model) #create error message content, along with jQuery function to highlight error fields.
		if model.errors.length > 0
			html = "<div class=\"error_messages\"><div class=\"error_messages_header\">#{error_header(model.errors.count)}</div><ul>"
			js = "<script type=\"text/javascript\">$(document).ready(function() {"
			model.errors.each_key do |key| 
				html += ("<li>- #{model.errors[key][0]}</li>")
				key.to_s.split("_").each do |split_key|
					js += "$('.#{split_key}').addClass('errors');"
				end
			end
			html += "</ul></div>"
			js += "})</script>"
			html += js
		end
	end
	
end

get '/' do
	@title = settings.dashboard_title
	erb :index
end

get '/dashboard' do
	@title = "DASHBOARD"
	@updated_accounts = User.all(:order => [:updated_at.desc], :limit => 10)
	@recent_authentications = repository(:default).adapter.select('(SELECT id, username, authdate FROM (SELECT id, username, authdate FROM ' + settings.history_table + ' GROUP BY username ORDER BY authdate DESC) AS A LIMIT 20)') #Get the latest record for the top 20 authentication attempts on the radius server **this will break when the History table is not called radpostauth**
	erb :dashboard
end

get '/stale' do #find stale accounts from teh dashboard view
	params[:stale_cutoff].nil? ? stale_cutoff = 60 : stale_cutoff = params[:stale_cutoff].to_i #if a blank form is sent, insert 60
	users = User.all
	@old_accounts = User.all(:limit => 2).clear #don't know how to create a Datamapper collection? This will work for now.
	users.each do |u|
		last_contact = Accounting.all(:username => u.username, :order => [:acctstarttime.desc]).first #find the accounts last hit on the server
		@old_accounts << last_contact if last_contact && last_contact.acctstarttime <= DateTime.now - stale_cutoff #if the last hit is older than the stale_cutoff, add it to the olde accounts array
	end
	@old_accounts.to_json
end

post "/login" do
	user = ActiveDirectoryUser.authenticate(params[:username], params[:password]) #attempt to authenticate
	if !user.nil? && user.member_of?(settings.admin_group)
		flash[:notice] = "Login Successful"
		session[:username] = params[:username]
		redirect "/dashboard"
	else
		flash[:error] = "Login Failed"
		redirect "/"
	end
end

get "/logout" do
	session[:username] = nil
	flash[:notice] = "Successfully logged out"
	redirect "/"
end

post "/search" do
	searchString = "%" + params[:search].gsub(/:/, "-") + "%"
	@results = MacAddress.all(:username.like => searchString)
	q2 = MacAddress.all(:comment.like => searchString)
	q2.each {|u| @results << u unless @results.include?(u)}
	q2 = MacAddress.all(:created_by.like => searchString)
	q2.each {|u| @results << u unless @results.include?(u)}
	q2 = MacAddress.all(:user.like => searchString)
	q2.each {|u| @results << u unless @results.include?(u)}
	@title = "#{@results.length} SEARCH RESULTS"
	flash[:notice] = "#{@results.length} results found when searching \"#{params[:search]}\""
	erb :search
end

not_found do
	erb :not_found
end

error do
	erb :error_500
end

require 'user.rb'
require 'mac_address.rb'
