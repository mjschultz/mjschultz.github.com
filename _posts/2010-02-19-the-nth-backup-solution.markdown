--- 
wordpress_id: 147
layout: post
title: The nth Backup Solution
wordpress_url: http://www.beyond-syntax.com/?p=147
---
In the past, I had developed my own <a href="http://www.beyond-syntax.com/2007/10/automatic-backups-using-cron-and-tar/">backup solution</a>.Â  Unfortunately, over time it didn't work out (mainly from changing systems, moving, using a laptop instead of a desktop, and maintaining it).Â  However, I still like the idea of incremental backups as well as a mirrored version of my files (it saves space and lets me keep a history going back some number of days).

<!--more-->Now that I'm somewhat settled (and a little wiser), I decided to once more try my hand at a solid backup plan.Â  This was mainly motivated by a recent reinstall of my wife's system (no lost data, just operating system upgrade).Â  Since I don't have vast amounts of time on my hands, I didn't want to forward port my old solution to get it to work on Linux and Mac OS X, so I looked for new solutions.Â  I recalled <a href="http://www.mscs.mu.edu/~brylow/">my advisor</a> from Marquette mentioning <a href="http://rdiff-backup.nongnu.org/">rdiff-backup</a> as what he put on his wife's machine during her dissertation days.

As it turns out, rdiff-backup does most of what I wanted out of my backup solution and, in fact, does it a little better.Â  The main issue I had with my system was that it would periodically (monthly) take a snapshot of my home directory, after that it would periodically (weekly) build incremental diffs based off that snapshot.Â  What this boils down to is that, if a catastrophic failure happens I would roll back to the most recent snapshot, then progress forward in time to the most recent incremental file.Â  Not bad, but if you want better-than-weekly granularity it could be a lot of work.Â  Obviously, I had scripted this part, but still it is wasted time.Â  With rdiff-backup, it would be a single copy operation to restore to the most recent version.Â  If you wanted older versions you could roll back through the incremental diffs (again, it is automated).

The other feature that I needed was the ability to remove backups/incremental data older than some time frame (monthly).Â  Again, rdiff-backup gives me this ability at the command line.Â  Other bonuses include the fact that it is cross-platform (via macports or most Linux repositories), written in Python, and not maintained by me!

With the basic service in place, it was time to make it automated.Â  Again, linked off rdiff-backup's page is an article on <a href="http://arctic.org/~dean/rdiff-backup/unattended.html">how to do unattended backups</a>.Â  Besides the typical unattended SSH-keypair-without-a-passphrase and protecting-the-account steps, it introduced me to a new trick (which for some reason, despite having the knowledge on how to do it, never put together) using SSH config.
<pre>Host athena-backup
	Hostname athena.olympus
	User backups
	IdentityFile ~/.ssh/backups_rsa
	Compression yes
	Protocol 2</pre>
Now, if I try to <code>ssh athena-backup</code>, it'll automatically use the correct identity file and user name which saves me from having to specify it on the command line (which you can't typically do with wrapper functionality).Â  More importantly, it doesn't break normal SSHing onto that host since we made it a special host (that's the part I never put together, even though I knew it was possible).

The next issue I never took that time to think about before was my having moved from desktop to laptop (thereby making 1:00am backups worthless sense the laptop isn't always on).Â  Because rdiff-backup does a roll-back model instead of my roll-forward model, I decided to do hourly backups to my home machine, thus I'll likely catch at least one of these a day.Â  But I'm not always at home!Â  Getting around that is trivial, I'll just ping the backup server before trying.Â  If it doesn't respond, I don't backup.  This is done through:
<pre>ping -c1 -t1 $SERVER &gt; /dev/null 2&gt;&amp;1</pre>
where <code>$SERVER</code> is just the name of the backup server.Â  It pings the host once with a timeout of 1 second, if it succeeds the backup continues; otherwise the script exits.

Of course, setting up the cronjob is as simple as:
<pre>0 */1 * * * $HOME/.crontab/rdiff-backup.sh</pre>
Hopefully this time around the backup solution is more robust than before.

Attachment: <a href="http://dev.beyond-syntax.com/scripts/rdiff-backup.sh">rdiff-backup.sh</a>
