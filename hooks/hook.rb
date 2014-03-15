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
      $stdout.puts `#{build_cmd(cmd, target, stdin)}`
      status = $?.exitstatus
      exit status if status != 0
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

  def build_cmd(cmd, target = nil, stdin = nil)
    runner   = "#{cmd} #{ARGV.join(' ')}"
    redirect = "echo \"#{stdin}\"" unless stdin.nil? || stdin.empty?
    command  = [redirect, runner].compact.join(' | ')

    if target == :bg || target == :background
      # run the command in background
      command = "(#{command}) &"
    end

    command
  end
end
