module Hook
  class ExecutionError < StandardError; end

  class Runner < Struct.new(:name, :output, :err, :bindir, :echo_input, :args)
    def self.call(*args)
      new(*args).call
    end

    def call
      system command, :out => output, :err => err

      status = $?.exitstatus
      if status != 0
        raise ExecutionError, "ERROR: Command '#{name}' finished with status #{status}"
      end

      status
    end

    def command
      [echo_input, "#{bindir}/#{name} #{args}"].compact.join(" | ")
    end
  end

  class Dispatcher
    def initialize(output = $stdout, input = $stdin, err = $stderr)
      @output  = output
      @input   = input
      @err     = err

      @logsdir = "#{File.dirname(__FILE__)}/log"
      @bindir  = "#{File.dirname(__FILE__)}/bin"
      ensure_logsdir

      @echo_input = build_echo_input
      @args       = ARGV.join(" ")

      ENV['GIT_HOOKS_PPID'] = Process.ppid.to_s
    end

    def ensure_logsdir
      Dir.mkdir(@logsdir) unless Dir.exist?(@logsdir)
    end

    def build_echo_input
      content = @input.gets
      unless content.nil? || content.empty?
        "echo '#{content}'"
      end
    end

    def run(names)
      Array(names).each do |name|
        handle_error do
          prompt name
          Runner.call(name, @output, @err, @bindir, @echo_input, @args)
        end
      end
    end

    def run_background(names)
      log = File.new("#{@logsdir}/#{names.join('-')}.log", "w")
      errlog = File.new("#{@logsdir}/#{names.join('-')}.err.log", "w")

      names   = Array(names)
      runners = names.map do |name|
        Runner.new(name, log, errlog, @bindir, @echo_input, @args)
      end

      prompt names.join(", ")
      pid = defer(runners)
      prompt "running in background with PID: #{pid}"
      prompt "log file: #{log.path}"
    end
    alias_method :&, :run_background

    def defer(runners)
      pid = fork do
        handle_error do
          runners.map(&:call)
        end
      end
      Process.detach(pid)

      pid
    end

    def handle_error
      yield
    rescue ExecutionError => e
      @err.puts "!> git-hooks > #{e.message}"
      exit 1
    end

    def prompt(message)
      @output.puts ">> git-hooks > #{message}"
    end
  end
end

def run_hooks(*hooks)
  @__hook_dispatcher__ ||= Hook::Dispatcher.new

  method = :run
  names  = hooks.dup
  if [:run, :run_background, :&].include?(names.last)
    method = names.pop
  end

  @__hook_dispatcher__.send method, names
end

def run_hook(*hooks)
  run_hooks(*hooks)
end

def detach_hooks(*hooks)
  hooks = hooks + [:&]
  run_hooks(*hooks)
end

def detach_hook(*hooks)
  detach_hooks(*hooks)
end
