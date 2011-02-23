--- 
wordpress_id: 159
layout: post
title: ./configure &#8211;enable-study-mode
wordpress_url: http://mike.xnerd.net/2008/configure-enable-study-mode/
---
Well, I'm currently running under the assumption that I have a math test tomorrow.  Therefore I should be studying, correct?  I assure you I'll get to the point of studying soon.  First, however, I want to explain to you how I went from reading notes about birth-and-death processes to updating the ports collection on my FreeBSD box (it won't take long).

So, I begin reading my notes from the beginning of the semester.  Nothing looks too bad and I get to the third page in short time, then I start reading about birth-and-death processes.  Nothing special, but it does mean a significant change in topics so I decide to take a brief mental break to check my email.  No new messages.  Back to studying.  Wait, I want to start some music---great idea!  Let me just load up iTunes.  Hmmm, I've already listened to most of this.  I know I have some more music on my file server but how to get it to my laptop...?

Well, the easy way would be to copy over the files using something like <a href="http://www.wikipedia.org/wiki/Secure_copy" title="Secure Copy">scp</a> but I don't want to use more disk space on my (already too full) laptop.  Ok, I do have NFS set up so I can just mount the music directory and play it over the network.  Nah, UDP traffic is for wimps besides it would leave ugly links in iTunes when I leave my network tomorrow.  Thinking a few more seconds I realize I want to mount the music directory as if it were someone sharing their iTunes with me.  How hard could that be for FreeBSD?

A quick Google brings up the <a href="http://wiki.fireflymediaserver.org/FrontPage">Firefly Media Server</a> that claims  to have exactly what I'm looking for.  I just need to <code>cd /usr/ports/audio/mt-daapd &amp;&amp; make install</code>.  D'oh!  There is a vulnerability, I need to update the ports tree.  So here I am, instead of studying I'm sitting here updating the FreeBSD ports tree.  Then I get to build mt-daapd, configure it, and hope that iTunes recognizes it so I can study.
