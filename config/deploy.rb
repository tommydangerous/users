require "mina/bundler"
require "mina/rails"
require "mina/git"
require "mina/rvm"

set :app_name, ""

#                                                                         Config
# ==============================================================================

set :rails_env, "production"

set :identity_file, "/Users/tommydangerous/.ssh/aws_west_1.pem"
set :user,          "ubuntu"
set :domain,        "54.153.105.214"

set :deploy_to,  "/var/www/#{app_name}"
set :app_dir,    "#{deploy_to}/current"
set :shared_dir, "#{deploy_to}/shared"

set :repository, "https://github.com/tommydangerous/#{app_name}.git"
set :branch,     "master"

# Manually create these paths in shared/ (eg: shared/config/database.yml)
# in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, %w{.env log config/database.yml config/secrets.yml}
set :keep_releases, 5

set :ssh_options, "-A"

#                                                                            RVM
# ==============================================================================
task :environment do
  invoke :"rvm:use[2.2.0]"
end

#                                                                      Provision
# ==============================================================================
task :provision do
  # queue %{
  #   echo "-----> Installing packages"
  #   #{echo_cmd %[sudo apt-get -y update]}
  #   #{echo_cmd %[sudo apt-get -y install build-essential git-core imagemagick libpq-dev libreadline-dev libssl-dev nginx nodejs postgresql-client]}
  # }

  # queue %{
  #   echo "-----> Installing rbenv"
  #   #{echo_cmd %[#{cmd_exists("rbenv")} || git clone git://github.com/sstephenson/rbenv.git ~/.rbenv]}
  #   #{echo_cmd %[#{cmd_exists("rbenv")} || git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build]}
  #   #{echo_cmd %[#{cmd_exists("rbenv")} || git clone git://github.com/dcarley/rbenv-sudo.git ~/.rbenv/plugins/rbenv-sudo]}
  #   #{echo_cmd %[#{cmd_exists("rbenv")} || echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc]}
  #   #{echo_cmd %[#{cmd_exists("rbenv")} || echo 'eval "$(rbenv init -)"' >> ~/.bashrc]}
  #   #{echo_cmd %[#{cmd_exists("rbenv")} || source ~/.bashrc]}
  # }

  # invoke "rbenv:load"

  # queue %{
  #   echo "-----> Installing ruby"
  #   #{echo_cmd %[rbenv install #{ruby_version}]}
  #   #{echo_cmd %[rbenv global #{ruby_version}]}
  # }

  # queue %{
  #   echo "-----> Installing gems"
  #   #{echo_cmd %[gem install bundle eye --no-ri --no-rdoc]}
  # }

  queue %{
    echo "-----> Configuring nginx"
    #{echo_cmd %[sudo rm -f /etc/nginx/sites-enabled/default]}
    #{echo_cmd %[sudo ln -sf #{app_path}/config/nginx.conf /etc/nginx/sites-enabled/]}
    #{echo_cmd %[sudo /etc/init.d/nginx restart]}
  }
end

#                                                                     Setup task
# ==============================================================================
# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  %w{config log pids sockets}.each do |folder|
    queue! %[mkdir -p "#{shared_dir}/#{folder}"]
    queue! %[chmod g+rx,u+rwx "#{shared_dir}/#{folder}"]
  end

  %w{.env config/database.yml config/secrets.yml}.each do |file|
    queue! %[touch "#{shared_dir}/#{file}"]
    queue  %[echo "-----> Be sure to edit 'shared/#{file}'."]
  end
end

#                                                                    Deploy task
# ==============================================================================
desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke "git:clone"
    invoke "deploy:link_shared_paths"
    invoke "bundle:install"
    invoke "rails:db_migrate"
    # invoke "rails:assets_precompile"

    to :launch do
      invoke :"unicorn:restart"
    end
  end
end

#                                                                        Unicorn
# ==============================================================================
namespace :unicorn do
  set :unicorn_pid, "#{shared_dir}/pids/unicorn.pid"
  set :start_unicorn, %{
    cd #{app_dir}
    bundle exec unicorn -c #{app_dir}/config/unicorn.rb -E #{rails_env} -D
  }

#                                                                     Start task
# ------------------------------------------------------------------------------
  desc "Start unicorn"
  task :start => :environment do
    queue "echo \"-----> Start Unicorn\""
    queue! start_unicorn
  end

#                                                                      Stop task
# ------------------------------------------------------------------------------
  desc "Stop unicorn"
  task :stop do
    queue "echo \"-----> Stop Unicorn\""
    queue! %{
      test -s "#{unicorn_pid}" && kill -QUIT `cat "#{unicorn_pid}"` && echo "Stop OK" && exit 0
      echo >&2 "Not running"
    }
  end

#                                                                   Restart task
# ------------------------------------------------------------------------------
  desc "Restart unicorn using 'upgrade'"
  task :restart => :environment do
    invoke "unicorn:stop"
    invoke "unicorn:start"
  end
end
