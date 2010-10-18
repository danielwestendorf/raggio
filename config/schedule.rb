require 'yaml'
config = YAML::load(File.read(File.dirname(__FILE__) + '/config/other.yml'))

set :path, '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin'
every 1.day, :at => '12:00 am' do
	command "/usr/local/bin/ruby #{config['deploy']['deploy_path']}/current/lib/cleanup.rb >> #{config['deploy']['deploy_path']}/current/log/cleanup.log"
end
