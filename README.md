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

You can generate many hooks for one kind of hook. For example, if you want to generate two different hooks for the `pre-commit` stage, you can generate them with:

```sh
$ hooks/generate pre-commit no-ascii-names skip-nocommit
>> git-hooks > creating hook > hooks/pre-commit
>> git-hooks > creating hooks directory > hooks/pre-commit.d
>> git-hooks > creating hook > hooks/pre-commit.d/no-ascii-names
>> git-hooks > creating hook > hooks/pre-commit.d/skip-nocommit
```

You will have a `pre-commit` hook that runs each of the named scripts inside the `pre-commit.d` dir. Those scripts can be any of any kind (`bash`, `python`, etc).

The new hook sets a environment variable called `GIT_HOOKS_PPID` with the original `git` command `pid`. That can be useful to check the original command run.

Check the default hook `pre-push` to check how this works.

Then, you can run `git init` in any new or existing repo to copy the data.

### pre-push

The default hook given in the repo is a hook to prevent a force push against some blacklisted branches (`master` and `production` by default).

This hook is a small modified version of the original hook from @neerajdotname in this blog post: [Do Not Allow Force Push to Master](http://blog.bigbinary.com/2013/09/19/do-not-allow-force-pusht-to-master.html).
