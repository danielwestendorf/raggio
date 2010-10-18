load 'deploy' if respond_to?(:namespace) # cap2 differentiator
require 'yaml'

config = YAML::load(File.read(File.dirname(__FILE__) + '/config/other.yml'))

default_run_options[:pty] = true

set :application, config['deploy']['app_name'] 
set :domain, config['deploy']['app_server']
set :deploy_to, config['deploy']['deploy_path']
set :use_sudo, true

set :scm, :git
set :repository, config['deploy']['git_repo']

server domain, :app
after "deploy:symlink", "deploy:copy_configs"
after "deploy:copy_configs", "deploy:copy_images"
after "deploy", "deploy:restart"

namespace :deploy do
  task :restart do
    run "touch #{current_path}/tmp/restart.txt" 
  end
  
  desc "Copy the real config YML files to the server"
  task :copy_configs, :roles => :app do
    File.exists?("config/database.yml") ? put(File.read("config/database.yml"), "#{current_path}/config/database.yml") : logger.important("config/database.yml is missing!")
    File.exists?("config/ldap.yml") ? put(File.read("config/ldap.yml"), "#{current_path}/config/ldap.yml") : logger.important("config/ldap.yml is missing!")
    File.exists?("config/other.yml") ? put(File.read("config/other.yml"), "#{current_path}/config/other.yml") : logger.important("config/other.yml is missing!")
  end

  desc "Copy custom images to the server"
  task :copy_images, :roles => :app do
    logo = config['other']['logo_url']
    error_img = config['other']['error_500_url']
    File.exists?("public#{logo}") && logo != "/images/logo.png" ? put(File.read("public#{logo}"), "#{current_path}/public#{logo}") : logger.important("Custom logo was not uploaded")
    File.exists?("public#{error_img}") && logo != "/images/500.png" ?  put(File.read("public#{error_img}"), "#{current_path}/public#{error_img}") : logger.important("Custom error image was not uploaded")
  end
end
