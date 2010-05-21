require File.dirname(__FILE__) + '/../raggio.rb'
require 'spec'
require 'rack/test'
require 'spec/autorun'
require 'spec/interop/test'

set :environment, :test

describe 'raggio' do
	include Rack::Test::Methods
	
	def app
		@app ||= Sinatra::Application
	end
	
	def session
		last_request.env['rack.session']
	end
	
	it "should show the splash page" do
		get '/'
		assert last_response.should be_ok
	end
	
	it "should redirect back to root if not logged in" do
		get "/users"
		follow_redirect!
		
		assert_equal "http://example.org/", last_request.url
		assert last_response.body.include?("required to log in")
		assert !last_response.body.include?("Login Successful")
	end
	
	it "should allow a login with my dwestendorf" do
		post "/login", {:username => "srvcnoc", :password => "pfuhl4g"}
		follow_redirect!
		
		assert session[:username] != nil
	end
	
	it "should not allow invalid user to log in" do
		post "/login", {:username => "sophos", :password => "sophos"}
		assert session[:username] == nil
	end
	
	it "should return at least one search value" do
		post "/search", {:search => " "}
		assert !last_response.body.include?("0 results found when searching")
	end
	
end
