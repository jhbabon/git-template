# GIT Template dir

This project include some scripts for a git repository, specially some useful git hooks.

## Install

To use the repo, clone in and set it as the template directory for [git-init](http://git-scm.com/docs/git-init).

For example, you can do that in the `~/.gitconfig` file:

```gitconfig
[init]
  templatedir = /path/to/cloned/repo/git-template
```

## Hooks

You can run many scripts for one kind of hook. For example, if you want to run two different scripts for the `pre-commit` hook, you can generate the hook with:

```
$ hooks/generate pre-commit no-ascii-names no-commit
>> git-hooks > creating hook > hooks/pre-commit
>> git-hooks > creating hooks directory > hooks/bin
>> git-hooks > creating hook > hooks/bin/no-ascii-names
>> git-hooks > creating hook > hooks/bin/no-commit
```

You will have a `pre-commit` hook that runs each of the named scripts inside the `bin` directory by default. Those scripts can be of any kind (`bash`, `python`, etc).

Inside the file `.git/hooks/pre-commit` you will see something like this:

```ruby
#!/usr/bin/env ruby

require File.expand_path("hook", File.dirname(__FILE__))

# Call #run_hooks with the name of the scripts that will be
# executed when this hook is called. Add :& as the last argument
# to run the scripts in background. Each hook will run in order.
#
# All the scripts must be in the directory:
#
#     hooks/bin/
#
#
# Example:
#
#    # background scripts, they don't stop the execution
#    # of the git command
#    run_hooks "bundler", "ctags", :&
#    # you also can use the #detach_hooks method
#    detach_hooks "bundler", "ctags"
#
#    # normal hook
#    run_hook "no-commit"

run_hooks "no-ascii-names", "no-commit"
```

Note that you can run scripts in background. This is useful when you want to perform some tasks that doesn't need to stop the execution of the git command, like generating tags (e.g: with ctags), or setting up the dependencies (e.g: with bundler). This background processes will log any output to `.git/hooks/log/`.

The new hook sets an environment variable called `GIT_HOOKS_PPID` with the original `git` command `pid`. That can be useful to check the original command run.

You can run `git init` in any new or existing repo to copy the data.

### no-commit

The hook `no-commit` prevents any commit in which the changes the flags `NOCOMMIT`, `NO-COMMIT`, `NO_COMMIT` are present. It is useful if you made temporary changes in the code and you don't want to commit for whatever reason (changes for development in your machine, etc).

This hook is set in the `pre-commit` hook.

### stop-force

This script prevents a force push against some blacklisted branches (`master` and `production` by default). Is a small modified version of the original hook from @neerajdotname in this blog post: [Do Not Allow Force Push to Master](http://blog.bigbinary.com/2013/09/19/do-not-allow-force-pusht-to-master.html).

The script is set in the `pre-push` hook.

### ctags

Original script from the original post by @tpope [Effortless Ctags with Git](http://tbaggery.com/2011/08/08/effortless-ctags-with-git.html). This script is executed in the hooks: `post-commit`, `post-checkout` and `post-merge`

### bundler

The script checks the dependencies of your ruby app and install whatever is missing. Also performs a cleanup. Is not enabled by default, it depends more in the project you are working on.
