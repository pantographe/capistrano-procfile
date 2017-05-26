namespace :procfile do
  task :set_host_properties do
    roles(:all).each do |host|
      on host do
        p = host.properties
        p.number_of_cpus = capture("grep -c processor /proc/cpuinfo").to_i
        p.memory   = (capture("awk '/MemTotal/ {print $2}' /proc/meminfo").to_i / 1024).round
        p.hostname = capture("hostname").strip
      end
    end
  end
end
