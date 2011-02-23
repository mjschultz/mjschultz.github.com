--- 
wordpress_id: 19
layout: post
title: A Quick Introduction to Makefiles
wordpress_url: http://www.beyond-syntax.com/?p=19
---
Today at the <a href="http://acm.mscs.mu.edu/">Marquette Student ACM</a> meeting, I gave a short <a href="http://www.beyond-syntax.com/uploads/2009/02/linux-dev.pdf">presentation</a> (PDF) about development on Linux.Â  Specifically using Makefiles.Â  As promised I have uploaded it to this site and I will give a little more information in this post.

<!--more-->

<strong>Variables</strong>

The two main types of variables in a Makefile are ``recursively expanded'' (<code>=</code>; equal to) and ``simply expanded'' (<code>:=</code>; set equal to---thanks Algol).Â  Recursively expanded is by far the most common and, realistically, the most confusing.Â  This form of a variable will not perform the substitution until the last possible moment (lazy evaluation), so if you have the line <code>SOURCES = ${CONFIG} demo.c</code>, make will remember that you use <code>${CONFIG}</code> until it must be known.  So if the value of CONFIG changes, the newest version of CONFIG will be used when it is evaluated.  Simple expansion occurs when the variable is declared (eager evaluation), if another variable (CFLAGS) is referenced in a simply expanded declaration it will be replaced with the current value of CFLAGS.

<strong>Targets</strong>

A target occurs on the left-hand side of a rule, typically this is the name of the file you want to build.Â  There are special cases of this, most commonly, ``clean.''Â  Usually when someone wants to `make clean' they want all the object files generated from a previous make to be removed.Â  However, if you were to create a file named `clean' the rule would never execute because the file clean is up-to-date.Â  This can be remedied with by a PHONY target.
<pre lang="make">.PHONY: clean
clean:
    rm -f *.o</pre>
This creates a phony target that depends on clean, which tells make to ignore any files named clean.

<strong>More on Variables</strong>

The important ``automatic'' variables are talked about in the presentation (<code>$@</code>, <code>$&lt;</code>, <code>$^</code>, <code>$+</code>, and <code>$?</code>).Â  Also useful is the % expansion variable.Â  For example, if there was the rule <code>%.o: %.c</code> in a Makefile, this will tell make that to make any file ending in .o will depend on the same file ending in .c (i.e. a rule <code>foo.o: foo.c</code> automatically exists).  This will then execute the same commands (say <code>gcc -m32 -Os -o foo.o foo.c</code>) for all files ending in .o.  This is a perfect example of why using automatic variables is a great idea.

Well, I think that is everything I have to say about Makefiles in a short amount of time.  If you have any questions please feel free to post in the comments.  I'll try my best to answer them promptly!

<em>(While most of the content here is off the top of my head, I did reference the <a href="http://www.gnu.org/software/make/manual/make.html">GNU make</a> page.  They have everything you wanted to know about make.)</em>

Attachment: <a href="http://www.beyond-syntax.com/uploads/2009/02/linux-dev.pdf">Software Development using GNU/Linux</a> (PDF)<em><a href="http://www.beyond-syntax.com/uploads/2009/02/linux-dev.pdf">
</a></em>
