require "cfoundry"

module CF::Harness
  class Service
    attr_reader :name, :instance

    def initialize(service, session)
      @instance = service
      @session = session
      @log = @session.log
      @name = @instance.name
    end

    def inspect
      "#<CF::Harness::Service '#@name'>"
    end

    # service manifest example
    #{:vendor=>"mysql", :version=>"5.1"}
    def create(service_manifest)
      service_manifest[:provider] ||= "core"
      services = @session.client.services
      services.reject! { |s| s.label != service_manifest[:vendor] } if service_manifest[:vendor]
      services.reject! { |s| s.provider != service_manifest[:provider] } if service_manifest[:provider]
      services.reject! { |s| s.version != service_manifest[:version] } if service_manifest[:version]

      service = services.first
      # if more than 1 services are matched, raise exception
      if services.size > 1
        service_list = []
        services.each {|s| service_list << "#{s.label}, #{s.provider}, #{s.version}"}
        @log.error("can't match the unique service using manifest: #{service_manifest}," +
                   " matched services:#{service_list}")
        raise RuntimeError, "can't match the unique service using manifest: #{service_manifest}," +
                            " matched services:#{service_list}"
      end
      @log.debug("Prepare to create service: #{@instance.name}")
      begin
        if service_manifest[:plan]
          plan = service_manifest[:plan]
        else
          raise RuntimeError, "you must specify plan in service manifest"
        end
        if @session.v2?
          plans = service.service_plans.select { |p| p.name == plan}
          if plans.size == 0
            plan_list = []
            service.service_plans.each {|p| plan_list << p.name}
            @log.error("can't find service plan #{plan}, supported plans: #{plan_list}")
            raise RuntimeError, "can't find service plan #{plan}, supported plans: #{plan_list}"
          end
          plan = plans.first
          @instance.service_plan = plan
          @instance.space = @session.current_space
          instance_info = "#{service.label} #{service.version} " +
              "#{service.provider}"
        else
          @instance.type = service.type
          @instance.vendor = service.label
          @instance.version = service.version
          @instance.tier = plan
          instance_info = "#{@instance.vendor} #{@instance.version} #{@instance.tier}"
        end

        @log.info("Create Service (#{instance_info}): #{@instance.name}")
        @instance.create!
      rescue Exception => e
        @log.error("Fail to create service (#{instance_info}):" +
                       " #{@instance.name}\n#{e.to_s}")
        raise RuntimeError, "Fail to create service (#{instance_info}):" +
            " #{@instance.name}\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def delete
      if @instance.exists?
        if @session.v2?
          plan = @instance.service_plan
          service = plan.service
          instance_info = "#{service.label} #{service.version} #{plan.name} #{service.provider}"
        else
          instance_info = "#{@instance.vendor} #{@instance.version} #{@instance.tier}"
        end
        @log.info("Delete Service (#{instance_info}): #{@instance.name}")
        begin
          @instance.delete!
        rescue Exception => e
          @log.error("Fail to delete service (#{instance_info}): #{@instance.name}\n#{e.to_s}")
          raise RuntimeError, "Fail to delete service (#{instance_info}): #{@instance.name}\n#{e.to_s}\n#{@session.print_client_logs}"
        end
      end
    end

    def check_service_manifest(service_manifest)
        # if :provider is not set, 'core' is default value
    end
  end
end
