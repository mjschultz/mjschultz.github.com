--- 
layout: post
title: Remote Instance of Firefox via SSH -X
---
<a title="Read about the Firefox web browser" href="http://www.getfirefox.com/">Firefox</a> is a pretty decent web browser. However, it can be a bit more clever than I want it at times. For example, if I want to SSH into a remote machine and launch a instance of Firefox -- to take on the remote machine's IP address or access localhost -- I would have to close the local instance then launch the remote instance. That is annoying and unacceptable behaviour.

Luckily, the solution is fairly straightforward. Once you have SSH'd into a remote host (using <code>ssh -X</code>), you simply need to run <code>firefox -no-remote</code>.  Of course you may want to tack on <code>&gt; /dev/null</code> and an ampersand <code>&amp;</code> to ignore the output and background the task. (Thanks to <a href="http://www.theopensourcerer.com/2007/11/15/remote-firefox-over-xssh/">The Open Sourcer</a>.)

With Firefox 2.x this behaviour was somewhat undocumented, but with Firefox 3.x, running <code>firefox --help</code> from the command line shows the <code>-no-remote</code> option. It also seems that the default (i.e. <code>-remote</code>), is "documented" on Mozilla's site for <a href="http://www.mozilla.org/unix/remote.html">Remote Control of UNIX Mozilla</a>.

If you wanted to make the <code>-no-remote</code> behaviour the default when SSH'd into remote machines, you could simply add a few lines to your bash profile to alias the <code>firefox</code> command.
<pre># If we're forwarding X over SSH, make firefox execute on this machine
if [ -n "$SSH_CONNECTION" -a -n "$DISPLAY" ]; then
    alias firefox='firefox -no-remote'
fi</pre>

At least that is what I did.
