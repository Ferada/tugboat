module Tugboat
  module Middleware
    # Check if the client has set-up configuration yet.
    class ListDroplets < Base
      def call(env)
        ocean = env["ocean"]

        cache_enabled = env["user_cache_enabled"] || env["config"].cache_enabled

        file_name = '.tugboat.cache'

        @path = ENV["TUGBOAT_CACHE_PATH"] || File.join(File.expand_path("~"), file_name)

        require 'yaml'

        write_file = false
        if cache_enabled
          begin
            droplet_list = YAML.load_file(@path)
          rescue Errno::ENOENT
            droplet_list = ocean.droplets.list.droplets
            write_file = true
          end
        else
          droplet_list = ocean.droplets.list.droplets
          write_file = true
        end

        if write_file
          File.open(@path, File::RDWR|File::TRUNC|File::CREAT, 0600) do |file|
            file.write droplet_list.to_yaml
          end
        end

        if droplet_list.empty?
          say "You don't appear to have any droplets.", :red
          say "Try creating one with #{GREEN}\`tugboat create\`#{CLEAR}"
        else
          droplet_list.each do |droplet|

            if droplet.private_ip_address
              private_ip = ", privateip: #{droplet.private_ip_address}"
            end

            if droplet.status == "active"
              status_color = GREEN
            else
              status_color = RED
            end

            say "#{droplet.name} (ip: #{droplet.ip_address}#{private_ip}, status: #{status_color}#{droplet.status}#{CLEAR}, region: #{droplet.region_id}, id: #{droplet.id})"
          end
        end

        @app.call(env)
      end
    end
  end
end

