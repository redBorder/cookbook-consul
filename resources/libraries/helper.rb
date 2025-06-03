module Consul
  module Helper
    def migrate_consul_config(config_file, old_dir, new_dir)
      service 'consul' do
        action :stop
      end

      execute "copy_consul_data_from_#{old_dir}_to_#{new_dir}" do
        command "cp -a #{old_dir}/. #{new_dir}/"
        only_if { ::Dir.exist?(old_dir) && !Dir.empty?(old_dir) }
      end

      ruby_block "update_#{config_file}_datadir" do
        block do
          file = Chef::Util::FileEdit.new(config_file)
          file.search_file_replace(/"data_dir":\s*"#{Regexp.escape(old_dir)}"/, "\"data_dir\": \"#{new_dir}\"")
          file.write_file
        end
      end

      service 'consul' do
        action :start
      end

      directory old_dir do
        action :delete
        only_if { ::Dir.exist?(new_dir) && !Dir.empty?(new_dir) }
        recursive true
      end
    end

    def get_server_count
      server_count = `serf members -tag consul=ready -format=json | jq -r '.members[].addr | split(":")[0]' | wc -l`.to_i
      server_count.zero? ? 1 : server_count
    end

    def get_server_list
      `serf members -tag consul=ready -format=json | jq -r '.members[].addr | split(":")[0]'`.split("\n").sort
    end
  end
end
