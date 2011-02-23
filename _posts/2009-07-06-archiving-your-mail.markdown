--- 
wordpress_id: 67
layout: post
title: Archiving your Mail
wordpress_url: http://www.beyond-syntax.com/?p=67
---
For those that don't know, I use <a href="http://www.mutt.org/">mutt</a> for my email needs.  This provides several niceties such as stripping out all the various formatting people like to include in their emails (fonts, graphics, etc), a keyboard driven interface, and, well, it just sucks less that most mail clients.

With mutt I choose to download all my email via POP3 to a local machine where I can read it when I get around to it (rigorous, isn't it).  After I read a message and deem it complete I move it to a folder named after the sender (or possibly a group) where I can <code>grep</code> the files and read them at a later date.

However, after a while these files pile up and I need to periodically compress and archive them.  This, of course, gets annoying and frequently forgotten.  To solve this I needed a script that could parse messages in a number of mail formats, find a date, and determine if it is beyond some threshold at which point it should be archived.  These requirements brought me to <a href="http://archivemail.sourceforge.net/">archivemail</a>.  Archivemail supports several input formats (IMAP, mh, mbox, Maildir), archives the messages, and outputs a single mbox formatted file (that can be compresses).  While I'm not a huge fan of the mbox format I can easily deal with it for archived mail.

<!--more-->

Archivemail has several perks that fit my requirements quite well.  First, it was easy to get (packages availables on OS X, Fedora, Debian, and Ubuntu), this probably stems from the fact that it is written in python and can easily run on almost any system.  Next, it provides several useful command line options, I personally have a cronjob that archives four message folders every 30 days (logwatches and mail lists) and archives other messages after 180 days.  This is simply done with the <code>--days</code> command line switch.  I also specify a directory to dump all the archived messages into so they don't clutter up my mail directory.  Depending on how you handle you mail there are also options to not archive unread messages or only archive messages older than some fixed date.

For those interested, here is my script that I run as a weekly cronjob to archive and compress my mail messages:
<pre>ARCMAIL="/usr/bin/archivemail --quiet --output-dir=$HOME/mail/archive/"

$ARCMAIL --days  30 $HOME/mail/logwatch \
                    $HOME/mail/netflix  \
                    $HOME/mail/amazon   \
                    $HOME/mail/dreamhost

$ARCMAIL --days 180 $HOME/mail/*</pre>
Fairly straightforward, eh?

To search through an archive you can just change into the <code>archive/</code> directory and execute a <code>gunzip -c &lt;filename&gt; | grep &lt;word&gt;</code>. Alternatively, you can use mutt's built in search and run <code>gunzip &lt;filename&gt;.gz ; mutt -f &lt;filename&gt;</code>.
