--- 
layout: post
title: A Quick Introduction to Makefiles
---
Today at the [Marquette Student ACM](http://acm.mscs.mu.edu/) meeting, I
gave a short [presentation
(PDF)](http://dev.beyond-syntax.com/blog/linux-dev/presentation.pdf) about
development on Linux.  Specifically using Makefiles. As promised I have
uploaded it to this site and I will give a little more information in this
post.

### Variables ###

The two main types of variables in a Makefile are "recursively expanded"
(`=`; equal to) and "simply expanded" (`:=`; set equal to---thanks
Algol). Recursively expanded is by far the most common and, realistically,
the most confusing. This form of a variable will not perform the
substitution until the last possible moment (lazy evaluation), so if you
have the line `SOURCES = ${CONFIG} demo.c`, make will remember that you use
`${CONFIG}` until it must be known.  So if the value of CONFIG changes, the
newest version of CONFIG will be used when it is evaluated.  Simple
expansion occurs when the variable is declared (eager evaluation), if
another variable (CFLAGS) is referenced in a simply expanded declaration it
will be replaced with the current value of CFLAGS.

### Targets ###

A target occurs on the left-hand side of a rule, typically this is the name
of the file you want to build. There are special cases of this, most
commonly, "clean". Usually when someone wants to "make clean" they want all
the object files generated from a previous make to be removed. However, if
you were to create a file named "clean" the rule would never execute
because the file clean is up-to-date. This can be remedied with by a PHONY
target.

{% highlight make %}
.PHONY: clean
clean:
    rm -f *.o
{% endhighlight %}

This creates a phony target that depends on clean, which tells make to ignore any files named clean.

### More on Variables ###

The important "automatic" variables are talked about in the presentation
(`$@`, `$<`, `$^`, `$+`, and `$?`). Also useful is the % expansion
variable. For example, if there was the rule `%.o: %.c` in a Makefile, this
will tell make that to make any file ending in .o will depend on the same
file ending in .c (i.e. a rule `foo.o: foo.c` automatically exists).  This
will then execute the same commands (say `gcc -m32 -Os -o foo.o foo.c`) for
all files ending in .o.  This is a perfect example of why using automatic
variables is a great idea.

Well, I think that is everything I have to say about Makefiles in a short amount of time.  If you have any questions please feel free to post in the comments.  I'll try my best to answer them promptly!

_(While most of the content here is off the top of my head, I did reference
the [GNU make](http://www.gnu.org/software/make/manual/make.html) page.
They have everything you wanted to know about make.)_
