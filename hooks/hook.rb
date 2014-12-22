module Hook
  class ExecutionError < StandardError
    attr_reader :exitstatus

    def initialize(message, exitstatus)
      @exitstatus = exitstatus
      super message
    end
  end

  class Runner
    def self.call(*args)
      new(*args).call
    end

    def initialize(name, command, content, output, err)
      @name    = name
      @command = command
      @content = content
      @output  = output
      @err     = err
    end

    def call
      copy_input do |input|
        system @command, :in => input, :out => @output, :err => @err
      end

      status = $?.exitstatus
      if status != 0
        error = ExecutionError.new(
          "ERROR: Command '#{@name}' finished with status #{status}",
          status
        )

        raise error
      end

      status
    end

    def copy_input
      IO.pipe do |reader, writer|
        writer.write @content
        writer.close
        yield reader
      end
    end
  end

  class Dispatcher
    def initialize(output = $stdout, input = $stdin, err = $stderr)
      @output = output
      @input  = input
      @err    = err

      @logsdir = "#{File.dirname(__FILE__)}/log"
      @bindir  = "#{File.dirname(__FILE__)}/bin"
      Dir.mkdir(@logsdir) unless Dir.exist?(@logsdir)

      @content = @input.read
      @args    = ARGV.join(" ")

      ENV["GIT_HOOKS_PPID"] = Process.ppid.to_s
    end

    def run(names)
      Array(names).each do |name|
        handle_error do
          prompt name
          Runner.call(name, command(name), @content, @output, @err)
        end
      end
    end

    def run_background(names)
      log    = "#{@logsdir}/#{names.join("-")}.log"
      errlog = "#{@logsdir}/#{names.join("-")}.err.log"

      names   = Array(names)
      runners = names.map do |name|
        Runner.new(name, command(name), @content, log, errlog)
      end

      prompt names.join(" && ")
      pid = defer(runners)
      prompt "running in background with PID: #{pid}"
      prompt "log file: #{log}"
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
      exit e.exitstatus
    end

    def command(name)
      "#{@bindir}/#{name} #{@args}"
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
