class Hook < Struct.new(:config, :basedir)
  def initialize(config, basedir = nil)
    super(config, basedir || File.dirname(__FILE__))
  end

  def call
    ENV['GIT_HOOKS_PPID'] = Process.ppid.to_s
    stdin = $stdin.gets

    hooks.each do |type, conf|
      hook, target = conf[0], conf[1]
      cmd = "#{basedir}/#{type}.d/#{hook}"
      $stdout.puts ">> git-hooks > #{type} > #{hook}"
      if target == :bg || target == :background
        pid = defer(cmd)
        $stdout.puts ">> running in background with PID: #{pid}"
      else
        $stdout.puts `#{build_cmd(cmd, stdin)}`
        status = $?.exitstatus
        exit status if status != 0
      end
    end
  end

  def hooks
    config.reduce({}) do |acc, (type, hooks)|
      hooks.each do |hook|
        acc[type] = Array(hook)
      end

      acc
    end
  end

  def build_cmd(cmd, stdin = nil)
    runner   = "#{cmd} #{ARGV.join(' ')}"
    redirect = "echo \"#{stdin}\"" unless stdin.nil? || stdin.empty?

    [redirect, runner].compact.join(' | ')
  end

  def defer(cmd)
    pid = fork { exec(cmd) }
    Process.detach(pid)

    pid
  end
end
