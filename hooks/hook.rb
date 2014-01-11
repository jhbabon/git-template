class Hook < Struct.new(:type, :hooks, :basedir)
  def initialize(type, hooks, basedir = nil)
    super(type, hooks, basedir || File.dirname(__FILE__))
  end

  def call
    ENV['GIT_HOOKS_PPID'] = Process.ppid.to_s
    stdin = $stdin.gets

    hooks.each do |hook|
      cmd = "#{basedir}/#{type}.d/#{hook}"
      $stdout.puts ">> git-hooks > #{type} > #{hook}"
      $stdout.puts `#{build_cmd(cmd, stdin)}`
      status = $?.exitstatus
      exit status if status != 0
    end
  end

  def build_cmd(cmd, stdin = nil)
    runner   = "#{cmd} #{ARGV.join(' ')}"
    redirect = "echo \"#{stdin}\"" unless stdin.nil? || stdin.empty?

    [redirect, runner].compact.join(' | ')
  end
end
