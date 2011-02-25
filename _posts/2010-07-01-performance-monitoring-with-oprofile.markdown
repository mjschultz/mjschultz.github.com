--- 
layout: post
title: Performance Monitoring with OProfile
---
[oprofile](http://oprofile.sourceforge.net/ "oprofile home page") is a low
overhead, open-source tool that hooks into Linux and can keep track of CPU
event monitoring information.  This is a fairly general statement and for
this post I'll be using the Intel Penryn microarchitecture, which should
have similar event counters to most recent Intel processors.  You can get
the canonical list of event counters from Intel's own documentation in
Chapter 30, Performance Monitoring, of Volume 3B, System Programming Guide
(available from [Intel's
site](http://www.intel.com/products/processor/manuals/ "Intel 64 and IA-32 Architectures Software Developer's Manuals")).  Alternatively, the Japan
Advanced Institute of Science and Technology have an [interactive
version](http://www.jaist.ac.jp/iscenter-new/mpc/altix/altixdata/opt/intel/vtune/doc/users_guide/mergedProjects/analyzer_ec/mergedProjects/reference_olh/index.htm) with all the events for most Intel processors.

### Event Counters ###
If you are unaware, almost every processor manufactured in recent history
has some collection of event counters that are incremented when some
processor event occurs.  These events can range from clock cycles ticking
by, instructions being retired, thermal thresholds being passed, or second
level cache misses.

So far, I've only really used the CPU clock cycles, level 1 cache line
replacement, and instructions retired event counters.  Your needs might not
match mine, so venture over to the Programmer Manual when you need
something else!

#### Event Ratios ####
Related to the event counters are event ratios.  These simple ratios can
help you find specific performance issues in your program.  For example, if
your program does a lot of memory accesses, the processor may need to
replaced cache lines frequently.  But cache line replacements are naturally
occurring in programs, how do we find excessive?  Simple!  We can just use
the ratio of L1 cache replacements to the number of instructions retired.
Then we'll have an idea of how many times per instruction an L1 cache line
is replaced.


### Using `oprofile` ###
First, you'll have to be running Linux, then you'll want to install the
"oprofile" package.  Since this software installs kernel modules for
monitoring, you'll also need root/sudo access to allow the module to be
loaded and unloaded for monitoring sessions.  Here,  I'll be running as a
user and using the `sudo` command when needed.


#### `opcontrol` ####
`opcontrol` is main program that lets you interact with the kernel.  If you
need a down-and-dirty list of the events available for monitoring,
`opcontrol --list-events` will show you all the event counters at your
disposal.

On my processor, the default event to monitor is CPU_CLK_UNHALTED which
will tell me where the processor spent most of the time executing.  If you
want to monitor different events, you can specify what event(s) to monitor
at the command line. The `separate` flag simply tells the profiler to
separate traces for each individual CPU (there are other separation levels,
but we won't use them here).

{% highlight bash %}
$ sudo opcontrol --event L1D_REPL:10000 --event INST_RETIRED:10000 --separate=cpu
{% endhighlight %}

The `:10000` after each counter simply specifies what the trigger threshold
is for raising processor exception.  In other words, every 10,000
instructions retired the processor raises an exception that the oprofile
daemon will catch and then increment the sample counter for that event.
So, if you see that oprofile has 1 sample of the INST_RETIRED counter then
the processor has seen 10,000 such events.

Now that we have the event counters configured, we can start the
monitoring.

{% highlight bash %}
$ sudo opcontrol --start
{% endhighlight %}

Since the system is doing other activities, it is best if what you want to
monitor can monopolize the system for the while.  In my case I build a
simple program that purposefully causes the L1 cache to have a lot of
misses ([`l1thrash` source
code](http://dev.beyond-syntax.com/l1thrash/l1thrash.c)).  I'll also set
the program to execute on one processor (CPU 1).

{% highlight bash %}
$ taskset 02 ./l1thrash
{% endhighlight %}

After it finishes executing, stop oprofile from running and save the
profile session on the disk.

{% highlight bash %}
$ sudo opcontrol --stop
$ sudo opcontrol --save l1thrash
{% endhighlight %}

Now we have our profile saved to disk and we can view it with `opreport`.

#### `opreport` ####
Finally, we get to see how the program handled!  Since we were smart and
saved our profile to a session, we'll have to specify that at the command
line.  You might want to pipe the output to less since it can be long at
times.  On my eight core system the output looks ugly.

{% highlight bash %}
$ opreport session:l1thrash
CPU: Core 2, speed 2494.04 MHz (estimated)
Counted L1D_REPL events (Cache lines allocated in the L1 data cache) with a unit mask of 0x0f (No unit mask) count 10000
Samples on CPU 0
Samples on CPU 1
Samples on CPU 2
Samples on CPU 3
Samples on CPU 4
Samples on CPU 5
Samples on CPU 6
Samples on CPU 7
    cpu:0|            cpu:1|            cpu:2|            cpu:3|            cpu:4|            cpu:5|            cpu:6|            cpu:7|
  samples|      %|  samples|      %|  samples|      %|  samples|      %|  samples|      %|  samples|      %|  samples|      %|  samples|      %|
------------------------------------------------------------------------------------------------------------------------------------------------
      541 95.7522      2969  0.9630       301 92.6154       484 69.9422       797 92.6744       707 88.2647       675 90.3614       707 89.8348 vmlinux
        7  1.2389        21  0.0068         6  1.8462         6  0.8671         9  1.0465         6  0.7491         6  0.8032         5  0.6353 oprofile
        6  1.0619         3 9.7e-04         6  1.8462         1  0.1445         3  0.3488         2  0.2497         1  0.1339         4  0.5083 nf_ses_watch
        5  0.8850        16  0.0052         6  1.8462         7  1.0116        25  2.9070        23  2.8714        30  4.0161        27  3.4307 libc-2.5.so
        3  0.5310         2 6.5e-04         1  0.3077         1  0.1445         2  0.2326         4  0.4994         0       0         1  0.1271 libpython2.4.so.1.0
        1  0.1770         0       0         0       0         0       0         0       0         0       0         0       0         0       0 e1000e
        1  0.1770         0       0         0       0         0       0         0       0         0       0         0       0         0       0 irqbalance
        1  0.1770         1 3.2e-04         1  0.3077         0       0         0       0         0       0         0       0         0       0 sshd
        0       0         2 6.5e-04         0       0         0       0         6  0.6977         8  0.9988         8  1.0710        18  2.2872 bash
        0       0         0       0         0       0         0       0         1  0.1163         0       0         0       0         1  0.1271 gawk
        0       0         0       0         0       0         3  0.4335         1  0.1163         2  0.2497         1  0.1339         0       0 bnx2
        0       0         0       0         3  0.9231         0       0         0       0         0       0         0       0         0       0 ehci_hcd
        0       0    305283 99.0179         0       0         0       0         1  0.1163         4  0.4994         1  0.1339         2  0.2541 l1thrash
        0       0        10  0.0032         0       0         0       0        14  1.6279        12  1.4981        19  2.5435        13  1.6518 ld-2.5.so
        0       0         3 9.7e-04         0       0         0       0         1  0.1163         1  0.1248         2  0.2677         2  0.2541 libcrypto.so.0.9.8b
        0       0         0       0         1  0.3077         0       0         0       0         0       0         0       0         0       0 libm-2.5.so
        0       0         0       0         0       0         0       0         0       0         0       0         1  0.1339         0       0 libpthread-2.5.so
        0       0         0       0         0       0         0       0         0       0         0       0         1  0.1339         0       0 syslogd
        0       0         0       0         0       0         0       0         0       0         1  0.1248         0       0         0       0 which
        0       0         0       0         0       0         1  0.1445         0       0         0       0         0       0         0       0 libcups.so.2
        0       0         0       0         0       0         0       0         0       0         0       0         2  0.2677         0       0 libusb-0.1.so.4.4.4
        0       0         0       0         0       0       189 27.3121         0       0        30  3.7453         0       0         7  0.8895 oprofiled
        0       0         1 3.2e-04         0       0         0       0         0       0         1  0.1248         0       0         0       0 cupsd
{% endhighlight %}

You may notice that the columns try to be sorted in descending order by the
number of samples taken for a specific process.  However, on CPU 1 (where
we ran `l1thrash`) the sorted order isn't close to correct.  Luckily, we
know that the bulk of our program only ran on CPU 1, so we can reissue the
`opreport` command specifying that we only care about that processor.

{% highlight bash %}
$ opreport session:l1thrash cpu:1
CPU: Core 2, speed 2494.04 MHz (estimated)
Counted INST_RETIRED.ANY_P events (number of instructions retired) with a unit mask of 0x00 (No unit mask) count 10000
Counted L1D_REPL events (Cache lines allocated in the L1 data cache) with a unit mask of 0x0f (No unit mask) count 10000
INST_RETIRED:1...|   L1D_REPL:10000|
  samples|      %|  samples|      %|
------------------------------------
  1834500 91.0882    305283 99.0179 l1thrash
   154499  7.6713      2969  0.9630 vmlinux
    21655  1.0752        21  0.0068 oprofile
     2176  0.1080        16  0.0052 libc-2.5.so
      442  0.0219        10  0.0032 ld-2.5.so
      435  0.0216         2 6.5e-04 bash
      108  0.0054         3 9.7e-04 libcrypto.so.0.9.8b
       47  0.0023         3 9.7e-04 nf_ses_watch
       43  0.0021         1 3.2e-04 sshd
       35  0.0017         2 6.5e-04 libpython2.4.so.1.0
       10 5.0e-04         0       0 libavahi-common.so.3.4.3
       10 5.0e-04         1 3.2e-04 cupsd
        9 4.5e-04         0       0 libcups.so.2
        7 3.5e-04         0       0 bnx2
        3 1.5e-04         0       0 libavahi-core.so.4.0.5
        1 5.0e-05         0       0 libpthread-2.5.so
        1 5.0e-05         0       0 timemodule.so
{% endhighlight %}

That looks better!  Since we've narrowed down the output to one CPU, we now
get to see both events that we monitored too.  You can see that the
majority of the time was spent in our `l1thrash` program, but how did it
do?

We know that the number of samples is the number of times that the event
counter on the processor hit 10,000 for both counters.  So, we find that
our `l1thrash` program caused (305,283)(10,000) = 3,052,830,000 level 1 cache
replacements and retired (1,834,500)(10,000) = 18,345,000,000 instructions.
Egads!  Is that good or bad?  Well, now we can throw in our ratio
calculation for the L1 data cache miss:

->![L1_{miss}=\frac{L1D\_REPL}{INST\_RETIRED}=\frac{305283}{834500}=\sim
16.6%](/static/latex/2010-07-miss_ratio.png)<-

That seems pretty bad to me!  We can also see that the Linux kernel
(`vmlinux`) had a ratio of 2,969:154,499 or about 1.9%, that is
a fairly typical miss ratio.

### A Second Example ###
This is a real example of a program I am actively trying to improve.  The
program is a kernel module (`nf_ses_watch`) designed to intercept packets
at a decent rate, it is not performing well.  Here I'll use the default
CPU_CLK_UNHALTED event monitor to see where the processor spends most of
its time.

{% highlight bash %}
$ # I've already loaded the kernel module and started my packet generator
$ sudo opcontrol --event default
$ sudo opcontrol --start
$ # I'll wait about 30 seconds so there are enough samples to be meaningful
$ sudo opcontrol --stop
$ sudo opcontrol --save bombard
{% endhighlight %}

Now I have my saved session and can look at the profile.  I've also taken
the time to set the interrupt affinity of the Ethernet device to a specific
processor (CPU 7), so now we can see if all the time was spent in my code
of Linux code.

{% highlight bash %}
$ opreport session:bombard cpu:7
CPU: Core 2, speed 2494.04 MHz (estimated)
Counted CPU_CLK_UNHALTED events (Clock cycles when not halted) with a unit mask of 0x00 (Unhalted core cycles) count 10000
CPU_CLK_UNHALT...|
	samples|      %|
------------------
	737746 86.6169 nf_ses_watch
	88183 10.3533 vmlinux
	16810  1.9736 e1000e
		3680  0.4321 oprofiled
		2594  0.3046 oprofile
		1578  0.1853 libc-2.5.so
		900  0.1057 bash
		78  0.0092 ld-2.5.so
		52  0.0061 ophelp
		26  0.0031 libavahi-common.so.3.4.3
		22  0.0026 libavahi-core.so.4.0.5
		13  0.0015 gawk
		9  0.0011 libcrypto.so.0.9.8b
		9  0.0011 libpython2.4.so.1.0
		9  0.0011 sshd
		8 9.4e-04 bnx2
		4 4.7e-04 libpthread-2.5.so
		3 3.5e-04 grep
		2 2.3e-04 ipv6
		2 2.3e-04 auditd
		1 1.2e-04 cat
		1 1.2e-04 libdl-2.5.so
		1 1.2e-04 libm-2.5.so
		1 1.2e-04 libpcre.so.0.0.1
		1 1.2e-04 dirname
		1 1.2e-04 automount
{% endhighlight %}

Wow!  Over 86% of the time we were executing code in the `nf_ses_watch`
kernel module (my code)!  Let's see if we can dig a little deeper.  First,
oprofile has already done the work for us and tracks the specific symbol
name within a piece of code that was active when the sample was taken with
the `--symbols` option (this results in a very long list of kernel
symbols).  But, in the case of a kernel module, `opreport` doesn't know
where to find the symbol names so we have to tell it where the kernel
module lives with `--image-path`.

{% highlight bash %}
$ opreport session:bombard cpu:7 --symbols --image-path ~/nf_ses_watch/kmod | head
warning: /bnx2 could not be found.
warning: /e1000e could not be found.
warning: /ipv6 could not be found.
warning: /oprofile could not be found.
warning: /sbin/auditd could not be read.
CPU: Core 2, speed 2494.04 MHz (estimated)
Counted CPU_CLK_UNHALTED events (Clock cycles when not halted) with a unit mask of 0x00 (Unhalted core cycles) count 10000
warning: could not check that the binary file /home/mjschultz/mon/module/kmod/nf_ses_watch.ko has not been modified since the profile was taken. Results may be inaccurate.
samples  %        image name               app name                 symbol name
733996   86.1767  nf_ses_watch.ko          nf_ses_watch             do_rip_entry
16810     1.9736  e1000e                   e1000e                   (no symbols)
10308     1.2102  vmlinux                  vmlinux                  rb_get_reader_page
9785      1.1488  vmlinux                  vmlinux                  read_hpet
8701      1.0216  vmlinux                  vmlinux                  ring_buffer_consume
3606      0.4234  vmlinux                  vmlinux                  netif_receive_skb
3530      0.4144  vmlinux                  vmlinux                  kfree
{% endhighlight %}

_(I've piped the output through `head` to keep it reasonable.)_ We can see
the real dirt here!  By a huge margin, the `do_rip_entry` symbol in my
`nf_ses_watch` module executes more than the Ethernet driver that is
handling the raw packets.  So that is where I'll be looking when I try to
resolve my bug.

### Conclusions ###
If you are looking to optimize your program, oprofile is a great tool to
use.  The default event monitor (CPU clock cycles on most processors), can
give you an idea of what part of your program is using most of the
processor time.  Once you know that, you can focus your efforts on reducing
the number of cycles spent in that function.  But don't forget about all
those other events too.  If you have a memory intensive application, maybe
you could reduce the memory contention and get an effective speedup with
almost no refactoring!

_(I've tried my best to be accurate with this information and I welcome any
explicit corrections or clarifications.)_
