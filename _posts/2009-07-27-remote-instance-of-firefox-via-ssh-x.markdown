--- 
layout: post
title: Remote Instance of Firefox via SSH -X
---
[Firefox](http://www.getfirefox.com/ "Read about the Firefox web browser")
is a pretty decent web browser. However, it can be a bit more clever than I
want it at times. For example, if I want to SSH into a remote machine and
launch a instance of Firefox -- to take on the remote machine's IP address
or access localhost -- I would have to close the local instance then launch
the remote instance. That is annoying and unacceptable behaviour.

Luckily, the solution is fairly straightforward. Once you have SSH'd into a
remote host (using `ssh -X`), you simply need to run `firefox -no-remote`.
Of course you may want to tack on `> /dev/null` and an ampersand `&` to
ignore the output and background the task. (Thanks to [The Open
Sourcer](http://www.theopensourcerer.com/2007/11/15/remote-firefox-over-xssh/).)

With Firefox 2.x this behaviour was somewhat undocumented, but with Firefox
3.x, running `firefox --help` from the command line shows the `-no-remote`
option. It also seems that the default (i.e. `-remote`), is "documented" on
Mozilla's site for [RemoteControl of UNIX
Mozilla](http://www.mozilla.org/unix/remote.html).

If you wanted to make the `-no-remote` behaviour the default when SSH'd
into remote machines, you could simply add a few lines to your bash profile
to alias the `firefox` command.

{% highlight bash %}
# If we're forwarding X over SSH, make firefox execute on this machine
if [ -n "$SSH_CONNECTION" -a -n "$DISPLAY" ]; then
    alias firefox='firefox -no-remote'
fi
{% endhighlight %}

At least that is what I did.
