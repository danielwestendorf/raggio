require 'dm-core'
require 'dm-validations'
require 'digest/md5'
require 'dm-aggregates'
require 'dm-serializer'

CONFIG = YAML::load(File.read(File.dirname(__FILE__) + '/config/database.yml'))
set :history_table, CONFIG['history_table']

DataMapper.setup(:default, "#{CONFIG['adapter']}://#{CONFIG['username']}:#{CONFIG['password']}@#{CONFIG['hostname']}/#{CONFIG['database']}")

class User
	include DataMapper::Resource
	
	property :id,								Serial, :key => true
	property :username, 				String, :index => :unique
	property :user,							String, :index => :unique
	property :attribute,				String, :default => "MD5-Password"
	property :op,								String, :default => ":="
	property :value, 						String
	property :expiration_date,	DateTime
	property :updated_at,				DateTime
	property :created_by,				String, :index => :unique
	property :comment,					Text, :lazy => false, :index => :unique
	property :mac_address,			Boolean, :default => false, :index => :unique
	
	storage_names[:default] = CONFIG['user_table']
	attr_accessor :password, :repassword
	
	before :save do
		@value = Digest::MD5.hexdigest(@password)
		@username.downcase!
	end
	
	before :destroy do
		Accounting.all(:username => self.username).each {|a| a.destroy}
		History.all(:username => self.username).each {|h| h.destroy}
	end
	
	def expiration_date=(new_expiration_date)
		attribute_set(:expiration_date, DateTime.strptime(new_expiration_date, "%m/%d/%Y")) if new_expiration_date.class == String && !new_expiration_date.empty? && new_expiration_date.match(/\d{1,2}\/\d{1,2}\/\d{4}$/)
	end
	
	validates_is_unique :username, :message => "There is already a user with that username"
	validates_present :username, :message => "A username is required"
	validates_with_method :password_repassword
	validates_with_method :expiration
	validates_length :password, :min => 6, :message => "The password needs at least 6 characters", :if => Proc.new {|u| u.new? || ( !u.new? && u.password.length != 0)}
	
	private
	
	def password_repassword
		!self.new? && @password.length < 1 || @password == @repassword ? true : [false, "The passwords for this user do not match"]
	end
	
	def expiration
		@expiration_date && @expiration_date > (DateTime.now - 1) ? true : [false, "The expire date is in the past"]
	end
	
end

class MacAddress
	include DataMapper::Resource
	
	property :id,								Serial, :key => true
	property :username, 				String
	property :user,							String
	property :attribute,				String, :default => "Cleartext-Password"
	property :op,								String, :default => ":="
	property :value, 						String
	property :expiration_date,	DateTime
	property :updated_at,				DateTime
	property :created_by,				String
	property :comment,					Text, :lazy => false
	property :mac_address,			Boolean, :default => true
	
	storage_names[:default] = CONFIG['mac_table']
	
	before :save do
		self.value = CONFIG['mac_password']
	end

	before :destroy do
		Accounting.all(:username => self.username).each {|a| a.destroy}
		History.all(:username => self.username).each {|h| h.destroy}
	end
	
	def username=(new_username)
    attribute_set(:username, new_username.gsub(/:/, "-").downcase) if !new_username.empty?
  end

  def username
    @username.gsub(/\-/, ":").upcase if @username
  end

	def expiration_date=(new_expiration_date)
		attribute_set(:expiration_date, DateTime.strptime(new_expiration_date, "%m/%d/%Y")) if new_expiration_date.class == String && !new_expiration_date.empty? && new_expiration_date.match(/\d{1,2}\/\d{1,2}\/\d{4}$/)
	end
	
	validates_present :username, :message => "A MAC Address is required"
	validates_present :user, :message => "You must specify the name of the person who this account belongs to"
	validates_with_method :expiration
  validates_with_method :validate_username_unique
  validates_with_method :validate_username_format

	private

  def validate_username_format
    @username.match(/^([0-9a-f]{2}([-]|$)){6}$/i) != nil ? true : [false, "Mac Address is not in the correct format"]
  end
	
	def validate_username_unique
    username = @username.downcase.gsub(/:/, "-")
    v = MacAddress.count(:username => username)
    v > 0 ? [false, "There is already and entry for that Mac Address"] : true
  end

	def expiration
		@expiration_date && @expiration_date > (DateTime.now - 1) ? true : [false, "The expire date is in the past"]
	end
end

class History
	include DataMapper::Resource
	
	property :id,								Serial, :key => true
	property :username, 				String, :index => :unique
	property :pass,							String
	property :reply,						String
	property :authdate,					String
	
	storage_names[:default] = CONFIG['history_table']
	
	def username
		@username.gsub!(/\-/, ":")
		if @username.scan(/:/).length > 0
			return @username.upcase
		else
			return @username
		end
	end
end


class Accounting
	include DataMapper::Resource
	
	property :radacctid,						Serial, :key => true
	property :username,							String, :index => :unique
	property :nasipaddress,					String
	property :acctstarttime,				DateTime
	property :acctsessiontime,			Integer
	property :acctinputoctets,			Integer
	property :acctoutputoctets, 		Integer
	property :calledstationid,			String
	property :callingstationid,			String
	property :framedipaddress,			String
	property :nas,									String
	
	attr_accessor :nas
	
	def callingstationid
		@callingstationid.gsub!(/\-/, ":")
		if @callingstationid.scan(/:/).length > 0
			return @callingstationid.upcase
		else
			return @callingstationid
		end
	end
	
	def calledstationid
		return "Unknown" if @calledstationid.length < 1
		split = @calledstationid.split(":")
		split[0].gsub!(/\-/, ":")
		@calledstationid = split[1] + " @ " + split[0] if split.length > 1
		if @calledstationid.scan(/:/).length > 0
			return @calledstationid.upcase
		else
			return @calledstationid
		end
	end
	
	def nas
		return "Unknown" if @nasipaddress.empty?
		h = Socket.getaddrinfo(@nasipaddress, nil)
		unless h[0].empty? && h[0][2].empty?
			return h[0][2]
		else
			return "Unknown"
		end
	end
	
	def download
		case @acctoutputoctets
			when 0..1024 then return @acctoutputoctets.to_s + "B"
			when 1025..1048576 then return (@acctoutputoctets / 1024).to_s + "KB"
			when 1048576..1073741824 then return (@acctoutputoctets / 1024 / 1024).to_s + "MB"
			when 1073741824..1099511627776 then return (@acctoutputoctets / 1024 / 1024 / 1024).to_s + "GB"
		end
	end
	
	def upload
		case @acctinputoctets
			when 0..1024 then return @acctinputoctets.to_s + "B"
			when 1025..1048576 then return (@acctinputoctets / 1024).to_s + "KB"
			when 1048576..1073741824 then return (@acctinputoctets / 1024 / 1024).to_s + "MB"
			when 1073741824..1099511627776 then return (@acctinputoctets / 1024 / 1024 / 1024).to_s + "GB"
		end
	end
	
	def total_transfered
		total = @acctinputoctets + @acctoutputoctets
		case total
			when 0..1024 then return total.to_s + "B"
			when 1025..1048576 then return (total / 1024).to_s + "KB"
			when 1048576..1073741824 then return (total / 1024 / 1024).to_s + "MB"
			when 1073741824..1099511627776 then return (total / 1024 / 1024 / 1024).to_s + "GB"
		end
	end

	def active
		return Time.at(@acctsessiontime).gmtime.strftime('%R:%S')
	end
	
	storage_names[:default] = CONFIG['accounting_table']
end

DataMapper.auto_upgrade!
