require "yaml"
require "harness"
require "yajl"
require "digest/md5"
require "tempfile"

module CF::Harness
  module HarnessHelper
    include ColorHelpers

    def check_user_availability(user)
      begin
        puts "checking user #{user} availability, trying to login..."
        client = CF::Harness::CFSession.new(:email => user['email'],
                                             :passwd => user['passwd'],
                                             :target => @config['target'])
      rescue => e
        puts e.message
        return false
      end
      return true
    end

    def cleanup!(users=[])
      users.each do |puser|
        begin
          cleanup_user_data(puser['email'], puser['passwd'])
        rescue => e
          puts "#{e.message}"
        end
      end
    end

    def set_config(config={})
      @config = config
    end

    def get_config
      @config
    end

    def get_target
      @config['target']
    end

    def get_admin_user
      @config['admin']['email']
    end

    def get_admin_user_passwd
      @config['admin']['passwd']
    end

    def create_push_app(user, app_name, app_manifest, opts={})
      session = CF::Harness::CFSession.new(:email => user['email'],
                                            :passwd => user['passwd'],
                                            :target => @config['target'])
      # check app fisrt
      found_apps = session.apps.select do |app|
        app.name == app_name
      end

      app = found_apps ? found_apps.first : nil

      if app.nil? || opts[:update_app_if_exist]
        app = session.app(app_name)
        app.push(nil, app_manifest, opts[:check_start])
        puts "app #{app_name} created"
      else
        puts "app #{app.name} already exists"
      end
      app
    end

    def create_bind_service(user, app, service_name, service_manifest, opts={})
      raise "app is nil when binding service #{service_name}" if app.nil? && opts[:bind] 
      session = CF::Harness::CFSession.new(:email => user['email'],
                                            :passwd => user['passwd'],
                                            :target => @config['target'])
      found_services = session.services.select do |service|
        service.name == service_name
      end
      service = found_services  ? found_services.first : nil
      unless service
        service = session.service(service_name)
        service.create(service_manifest)
        puts "service #{service_name} created"
      else
        puts "service #{service_name} already exists"
      end

      if opts[:bind]
        app.bind(service, opts[:restart_app])
      end
    end

    def create_users(users=[])
      puts "need admin account to create users"
      get_admin_user
      get_admin_user_passwd

      session = nil
      begin
        session = CF::Harness::CFSession.new(:admin => true,
                                              :email => @config['admin']['email'],
                                              :passwd => @config['admin']['passwd'],
                                              :target => @config['target'],
                                              :namespace => @config['namespace'])
      rescue Exception => e
        raise RuntimeError, "#{e.to_s}\nPlease input valid admin credential to create users"
      end

      users.each do |user|
        email = user['email']
        passwd = user['passwd']
        if check_user_availability(user)
          puts "user #{email} already exists!"
          next
        else
          puts "user #{email} does not exist, will create it"
        end
        if session.v2?
          @uaa_cc_secret ||= get_uaa_cc_secret
          uaa_url = format_target(@config['target']).gsub(/\/\/\w+/, '//uaa')
          org_name = "#{email.gsub(".", "_").gsub("@","_at_")}_org"
          space_name = "cfharness_test_space"
          puts "v2: creating user #{email}"
          CCNGUserHelper.create_user(uaa_url, @uaa_cc_secret, @config['target'], @config['admin']['email'],
                                     @config['admin']['passwd'], email, passwd, org_name, space_name)
        else
          user = session.user(email, :require_namespace => false)
          user.create(passwd)
        end
        puts "create user: #{yellow(email)}"
        $stdout.flush
      end
    end

    def format_target(str)
      if str.start_with? 'http'
        str
      else
        'https://' + str
      end
    end

    def get_uaa_cc_secret
      @uaa_cc_secret ||= @config['uaa_cc_secret']
      raise RuntimeError, "You should specify the uaa_cc_secret" unless @uaa_cc_secret
      @uaa_cc_secret
    end

    private

    def cleanup_user_data(email, passwd)
      session = CF::Harness::CFSession.new(:email => email,
                                            :passwd => passwd,
                                            :target => @config['target'])
      puts yellow("Ready to clean up for test user: #{session.email}")

      apps = session.client.apps
      puts yellow("Begin to clean up apps")
      cleanup_data(apps)

      services = session.client.service_instances
      puts yellow("Begin to clean up services")
      cleanup_data(services)

      if session.v2?
        routes = session.client.routes
        puts yellow("Begin to clean up routes")
        cleanup_data(routes)

        domains = session.client.domains
        puts yellow("Begin to clean up domains")
        cleanup_data(domains)
      end

      puts yellow("Clean up work for test user: #{session.email} has been done.\n")
    end

    def cleanup_data(objs)
      if objs.empty?
        puts "no objects to cleanup"
      else
        objs.each do |obj|
          puts "deleting #{obj.class.to_s}: #{obj.name}..."
          obj.delete!
        end
      end
    end

    def check_md5(filepath)
      Digest::MD5.hexdigest(File.read(filepath))
    end

    extend self
  end
end
