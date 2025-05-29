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

      def update_config_file(config_file, old_dir, new_dir)
        ruby_block "update_#{config_file}_datadir" do
          block do
            file = Chef::Util::FileEdit.new(config_file)
            file.search_file_replace(/"data_dir":\s*"#{Regexp.escape(old_dir)}"/, "\"data_dir\": \"#{new_dir}\"")
            file.write_file
          end
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
  end
end