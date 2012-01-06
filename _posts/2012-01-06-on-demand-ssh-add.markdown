---
layout: post
title: On Demand ssh-add
keywords: ssh,ssh-add,ssh-agent,on demand
description: Set ssh to only prompt for a passphrase if it isn't in your ssh-agent already, but not before you need it.
---
For many years I have been bothered by the options for using the ssh-agent
on Linux.  I finally (hope) I've reached a reasonable solution for adding
my keys to the ssh-agent.

# Background #

As many \*nix users know: SSH keys with passphrases are the way to go when
jumping from system to system.  This is the case because on your main
computer there is a program running called `ssh-agent`.  When you first
boot your computer `ssh-agent` knows nothing and doesn't do much.

The real magic happens when you tell `ssh-agent` about your SSH keys.  In
the past I've done this in one of two ways:

# Use the `ssh-add` command to add a key to the agent.
# Have the desktop environment ask for your passphrase when it loads.

Since these have the same result of adding your passphrase to `ssh-agent`
it simply becomes a matter of user experience.  Neither experience I really
enjoyed.

In the first case, my use pattern was *always*:

    $ ssh <hostname>
    Enter passphrase for key '<key>':

At which point I would curse, hit control-c, run `ssh-add`, and try sshing
into the host.  Not terrible, but not pleasant either.

The second option would pop up some graphical prompt asking for my
passphrase when starting the desktop environment.  This is also not a
terrible experience, but it's a bit annoying when I'm just sitting down and
don't want to type a long passphrase just to check my email. (I could close
it, but then I'm back in the frustrating first case.)

# What is a geek to do? #

Honestly, the OS X way of doing this isn't too bad.  If I haven't
authenticated myself to the computer when I ssh the first time OS X
recognizes that and prompts me for authentication.  At this point I'm
authenticated and any future SSH attempts will re-use that authentication.
That is to say:

# OS X automatically adds the authentication to the ssh agent*
# I'm not bothered with authentication until I need it.

* This isn't quite how OS X actually does it, the passphrase is stored in a
  keychain.  The keychain gets unlocked when I need it and serves the
  passphrase to the ssh command.

I want the same experience on Linux.

After searching for some tools to do it for me (and finding nothing), I
decide to take a stab at it.  It turns out to be very easy.  All I did was
add the following line to my `~/.bash_profile`:

    alias ssh="( ssh-add -l > /dev/null || ssh-add ) && ssh"

This just checks to see if any identities exist in the running ssh agent
(`ssh-add -l > /dev/null` returns `1` if it is empty and `0` otherwise).
If there are identities, the `||` operation is short circuited and the ssh
command is run as normal.  If the agent is empty, the `ssh-add` command
runs and asks for your passphrase as normal, adds it to the agent, (returns
0), and runs the ssh command as normal.
In both cases, any command line arguments are passed on to the final ssh command as
normal.  

If you mistype your passphrase and `ssh-add` gives up it returns `1`,
causing the `&&` operation to short circuit and the normal ssh command is
not run and you can try again.

Of course, this makes a few assumptions:

# Either your agent is empty or it has all useful keys in it.
# You're going to `ssh` before you `scp` or use any other command.

In my case both assumptions a valid.  I don't have any keys that `ssh-add`
doesn't find automatically (even if I did, I would still want to manually
add them in them to the agent--in which case I am no worse off than
before).  In the second case, I almost always ssh to a host before moving
files around or to, just so I can make sure I have the locations correct.
(Of course, as I submit this post `git` asks for my passphrase because I
haven't authenticated yet. The quick answer is to alias all commands that
need ssh key authentication with the stuff before `&&` and replace `ssh`
with the desired command.)

This also shouldn't hurt security any more than another solution.  At the
end of the day, I'm disappointed that I didn't do this a long time ago.
