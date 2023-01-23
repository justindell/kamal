require "mrsk/cli/base"

class Mrsk::Cli::Accessory < Mrsk::Cli::Base
  desc "boot [NAME]", "Boot accessory service on host (use NAME=all to boot all accessories)"
  def boot(name)
    if name == "all"
      MRSK.accessory_names.each { |accessory_name| boot(accessory_name) }
    else
      upload(name)

      accessory = MRSK.accessory(name)
      on(accessory.host) { execute *accessory.run }
    end
  end

  desc "upload [NAME]", "Upload accessory files to host"
  def upload(name)
    accessory = MRSK.accessory(name)
    on(accessory.host) do
      accessory.files.each do |(local, remote)|
        execute *accessory.make_directory_for(local, remote)
        upload! local, remote
      end
    end
  end

  desc "reboot [NAME]", "Reboot accessory on host (stop container, remove container, start new container)"
  def reboot(name)
    stop(name)
    remove_container(name)
    boot(name)
  end

  desc "start [NAME]", "Start existing accessory on host"
  def start(name)
    accessory = MRSK.accessory(name)
    on(accessory.host) { execute *accessory.start }
  end

  desc "stop [NAME]", "Stop accessory on host"
  def stop(name)
    accessory = MRSK.accessory(name)
    on(accessory.host) { execute *accessory.stop }
  end

  desc "restart [NAME]", "Restart accessory on host"
  def restart(name)
    stop(name)
    start(name)
  end

  desc "details [NAME]", "Display details about accessory on host"
  def details(name)
    accessory = MRSK.accessory(name)
    on(accessory.host) { puts capture_with_info(*accessory.info) }
  end

  desc "logs [NAME]", "Show log lines from accessory on host"
  option :since, aliases: "-s", desc: "Show logs since timestamp (e.g. 2013-01-02T13:23:37Z) or relative (e.g. 42m for 42 minutes)"
  option :lines, type: :numeric, aliases: "-n", desc: "Number of log lines to pull from each server"
  option :grep, aliases: "-g", desc: "Show lines with grep match only (use this to fetch specific requests by id)"
  option :follow, aliases: "-f", desc: "Follow logs on primary server (or specific host set by --hosts)"
  def logs(name)
    accessory = MRSK.accessory(name)

    grep = options[:grep]

    if options[:follow]
      run_locally do
        info "Following logs on #{accessory.host}..."
        info accessory.follow_logs(grep: grep)
        exec accessory.follow_logs(grep: grep)
      end
    else
      since = options[:since]
      lines = options[:lines]

      on(accessory.host) do
        puts capture_with_info(*accessory.logs(since: since, lines: lines, grep: grep))
      end
    end
  end

  desc "remove [NAME]", "Remove accessory container and image from host (use NAME=all to boot all accessories)"
  def remove(name)
    if name == "all"
      MRSK.accessory_names.each { |accessory_name| remove(accessory_name) }
    else
      stop(name)
      remove_container(name)
      remove_image(name)
      remove_files(name)
    end
  end

  desc "remove_container [NAME]", "Remove accessory container from host"
  def remove_container(name)
    accessory = MRSK.accessory(name)
    on(accessory.host) { execute *accessory.remove_container }
  end

  desc "remove_container [NAME]", "Remove accessory image from host"
  def remove_image(name)
    accessory = MRSK.accessory(name)
    on(accessory.host) { execute *accessory.remove_image }
  end

  desc "remove_files [NAME]", "Remove accessory directory used for uploaded files from host"
  def remove_files(name)
    accessory = MRSK.accessory(name)
    on(accessory.host) { execute *accessory.remove_files }
  end
end
