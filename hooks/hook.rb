class Hook < Struct.new(:type, :hooks, :basedir)
  def initialize(type, hooks, basedir = nil)
    super(type, hooks, basedir || File.dirname(__FILE__))
  end

  def call
    ENV['GIT_HOOKS_PPID'] = Process.ppid.to_s

    hooks.each do |hook|
      cmd = "#{basedir}/#{type}.d/#{hook}"
      $stdout.puts ">> git-hooks > #{type} > #{hook}"
      $stdout.puts `#{cmd} #{ARGV.join(' ')}`
      status = $?.exitstatus
      exit status if status != 0
    end
  end
end
