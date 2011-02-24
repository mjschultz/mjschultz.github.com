--- 
layout: post
title: Automatic backups using `cron` and `tar`
---
_This post is an import from a presentation I did in October of 2007.
Since I've made this presentation, I've stopped using my own script and
suggest you use another tool for backups.  I hear
[rdiff-backup](http://www.gnu.org/savannah-checkouts/non-gnu/rdiff-backup/)
is good.  However, I believe this is still a good introduction to `bash`
scripting, `cron`, and `tar`._

### Original Presentation ###
Although it may be less useful without the accompanying speaker, the
[original
presentation](http://dev.beyond-syntax.com/blog/backup-2007/backup.pdf) is
available.

### Source code for the shell script ###
I have made the source code (backup.sh _(I no longer have this file, sorry
-- mjs)_) available for download. In the top matter of the file describe
how to add the script to your crontab.

### Description of the script ###
For me, the best way to learn something is to take it line by line and that
is what I'm going to do below. Naturally I will combine lines which are
similar to save space. Since the target audience is someone who has never
seen a shell script, some information may seem unimportant to you.

The concatenated source code that appears on this page may not agree with
the source available for download. Odds are I decided the change was not
worth updating this page, but made available for consumption as the script.
If you notice something that is greatly different please contact me.

{% highlight bash %}
#!/bin/sh
{% endhighlight %}

Selection of a shell interpreter. This _must_ be the first line in the file
and be prefix with the 'hash-bang' (or 'sh-bang' for short).

I use `/bin/sh` since it seems to be the most universal amongst systems. It
should be noted that on many systems `/bin/sh` is that same as `/bin/bash`,
I do not know if this means the script will not work in `/bin/sh`.

{% highlight bash %}
SNAPDIR=/var/snapshots/$USER
RMT_DIR="user@hostname:~/snapshots"
RMT_OPTIONS="-i $HOME/.ssh/id_dsa"
{% endhighlight %}

Setting some simple variables. Note that there are no spaces between the
variable name, the equal sign, and the value; your script will not work
with spaces between these three items.

Here I set the snapshot directory (where snapshots should be stored) to be
`/var/snapshots/$USER`. `$USER` is a special variable that is the same as
the user running the script.

Next are `RMT_DIR` and `RMT_OPTIONS` which are quoted. Quotes simply make
sure spaces are included in the variable. Again, `$HOME` is a environmental
variable that is always a user's home directory.

{% highlight bash %}
RMT_CMD=$(which scp)
DATE=$(date +%Y%m%d)
TAR=$(which tar)
MKDIR=$(which mkdir)
CHMOD=$(which chmod)
{% endhighlight %}

This group of variables will run commands in a "sub-shell" before setting
the variable name to the value. For example `$(which scp)` will execute
`which scp` on the system and assign the value returned to `RMT_CMD`.

{% highlight bash %}
LAST_FULL=$(stat -f "%Dc %Sc" -t "%Y%m%d" ${SNAPDIR}/full-*.tar.gz \
            2> /dev/null| sort -n | tail -n1)
LAST_TS=$(echo ${LAST_FULL} | awk '{ print $1}')
LAST_DATE=$(echo ${LAST_FULL} | awk '{ print $2}')
{% endhighlight %}

In the final group of variables we use "pipes" which use the output of the
first command as the input of the second command. For `LAST_FULL` we first
`stat` files of the pattern "full-*.tar.gz" in the `${SNAPDIR}` directory.
_(N.B. `${SNAPDIR}` dereferences the `SNAPDIR` variable we set earlier. The
curly braces are not strictly necessary, however I use them when referring
to local variables.)_ For `stat` I am specifying that the output should be
of the form "<timestamp> <YYYYMMDD>", then `sort` the output
using the number in the first column, and finally, take only the last file
listed.

Once the last full snapshot time is known, we split it into two variables
(`LAST_TS` and `LAST_DATE`), again using pipes and awk.

{% highlight bash %}
if [ ! -d ${SNAPDIR} ]; then
	${MKDIR} ${SNAPDIR}
	${CHMOD} go-rwx ${SNAPDIR}
fi
{% endhighlight %}

We'll start by making sure the directory snapshots directory exists. If it
doesn't, make the directory and remove all permission from anyone not this
user.

{% highlight bash %}
function incr {
	${TAR} czf ${SNAPDIR}/incr-${DATE}.tar.gz \
	       --exclude-from $HOME/.snap-exclude \
	       --listed-incremental=${SNAPDIR}/$USER-${LAST_DATE}.snar \
	       $HOME < /dev/null 2< /dev/null

	${CHMOD} go-rwx ${SNAPDIR}/incr-${DATE}.tar.gz

	if [ "${RMT_CMD}" != "" ]; then
		${RMT_CMD} ${RMT_OPTIONS} ${SNAPDIR}/incr-${DATE}.tar.gz \
		       ${SNAPDIR}/$USER-${LAST_DATE}.snar \
		       ${RMT_DIR}
	fi
}
{% endhighlight %}

For creating an incremental backup. Using `tar`, `c`reate a g`z`ipped
`f`ile at `${SNAPDIR}/incr-${DATE}.tar.gz`. Since you may not want _all_ of
your home directory backed up, you can exclude files listed in the
`.snap-exclude` file. Now the most important part, `--listed-incremental`,
tells `tar` what the timestamps of the files were last time it executed. If
the timestamp on a file is newer than in the snar ("snapshort archive"), it
will be added to the tarball. The last argument to tar is simply the
directory to backup. `>` and `2>` redirect standard out and standard
error to `/dev/null`, thus suppressing all output.

For the sake of security, we revoke all access from the file except for the
current user.

The final step is to check of a `RMT_CMD` exists, if it does execute it.
`scp` works well for this step, as would `rsync`.

{% highlight bash %}
function full {
	${TAR} czf ${SNAPDIR}/full-${DATE}.tar.gz \
	       --exclude-from $HOME/.snap-exclude \
	       --listed-incremental=${SNAPDIR}/$USER-${DATE}.snar \
	       $HOME < /dev/null 2< /dev/null

	${CHMOD} go-rwx ${SNAPDIR}/full-${DATE}.tar.gz
	${CHMOD} go-rwx ${SNAPDIR}/$USER-${DATE}.snar

	if [ "${RMT_CMD}" != "" ]; then
		${CMT_CMD} ${RMT_OPTIONS} ${SNAPDIR}/full-${DATE}.tar.gz \
		       ${SNAPDIR}/$USER-${DATE}.snar \
		       ${RMT_DIR}
	fi
}
{% endhighlight %}

Creating a full backup is not much different than an incremental backup.
The only difference is the `--listed-incremental` file (`tar` will create a
new snapshot archive), thus starting with a fresh backup and timestamps.
The reason for this is explained in the "Recovery" section.

The rest of the function is mostly the same as an incremental backup.

{% highlight bash %}
function normal {
	# Make a full backup if no backup exists
	if [ ! -f ${SNAPDIR}/$USER-${LAST_DATE}.snar ]; then
		full;
	else
		ELAPSED=$(($(date +%s) - ${LAST_TS}))
		SNAP_FRAME=$((7 * 24 * 60 * 60 - 3600))

		# Check if it has been over a week since a full snapshot
		if [ ${ELAPSED} -gt ${SNAP_FRAME} ]; then
			# make a full snapshot
			full;
			# clean up files older than 4 weeks
			clean;
		else
			incr;
		fi

		unset ELAPSED SNAP_FRAME
	fi
}
{% endhighlight %}

Here we have the main "brain" of the program. It begins by making sure a
backup exists, if one doesn't the script makes a full backup. If at least
one full backup exists, then we find out how long it has been since the
last full backup and compare that to how frequently full backups should be
made. `SNAP_FRAME` holds the frequency in which backups should be made
(every 7 days * 24 hours / day * 60 minutes / hour * 60 seconds / minute
(minus 1 hour for time delays)). If too much time has passed, create a full
backup and clean out the old files. Otherwise just create an incremental
backup.

{% highlight bash %}
function clean {
	true
}
{% endhighlight %}

The script isn't perfect. I have yet to determine a good way to clean out
old files (one that isn't tied to either `scp` or `rsync`).

{% highlight bash %}
function usage {
	echo "usage: $0 [type]"
	echo "[type] can be one of the following:"
	echo "  normal - follow the daily incremental and weekly backup schedule"
	echo "  incr   - create a incremental backup of $HOME to ${SNAPDIR}"
	echo "  full   - create a full backup of $HOME to ${SNAPDIR}"
	echo "  clean  - cleanup backups older than one month"
	echo "  usage  - display this screen"
	echo "  --help - display this screen"

	exit 1
}
{% endhighlight %}

This simple function displays the usage information if requested. `$0` is
the script name as typed by the user.

{% highlight bash %}
case "$1" in
	'normal')
		normal;
		;;
	'incr')
		incr;
		;;
	'full')
		full;
		;;
	'clean')
		clean;
		;;
	'--help')
		usage;
		;;
	'usage')
		usage;
		;;
	*)
		normal;
		;;
esac
{% endhighlight %}

Finally, the driver of the program, a case statement which reads the first
argument (`$1`) and executes the desired function. The default operation is
to run in normal mode, but the user is able to force an incremental update,
full update, or clean out old files.

### Setting up a cronjob ###
`cron` is a simple utility that exists on almost all UNIX or UNIX-like
systems. A daemon runs every minute to see if any user has a "cronjob" that
needs to be executed, if a user does it will run it.

User level cronjobs are maintained by a program called `crontab`, to view
your current crontab type: `crontab -l`, to edit your crontab use `crontab
-e`.

I personally like to keep all my user level cronjobs in one place,
`$HOME/.cronjobs/`. This folder conatins two files: `crontab` and
`backup.sh`. `crontab` is a text file which hold what cronjobs I'd like to
have run while `backup.sh` is the file described above.

My crontab files looks something like this:

{% highlight bash %}
# User level crontab
# min hr mday month wday command
00    13  *    *     *    /path/to/home/directory/.cronjobs/backup.sh
{% endhighlight %}

Which means I backup my files everyday at precisly 1:00pm by running the
file located in `/path/to/home/directory/.cronjobs/backup.sh`. This can
then be loaded into the system cronjobs using the following command.

{% highlight bash %}
crontab < crontab
{% endhighlight %}


### Recovering the data ###
If you ever need to restore your backed up data all you need to do is find
the most recent full backup (we'll say `full-20071001.tar.gz`) and all the
incremental backups since then (in our example `incr-2007100[2-5].tar.gz`).
You'll start by extracting the full backup to the correct folder via `tar
xzf full-20071001.tar.gz`, followed by the incremental backups oldest to
newest. Effectively you are restoring your entire home folder from n-days
ago and applying the differences from each succeeding day. The commands
should go as below (where `$` is the shell prompt).

{% highlight bash %}
$ tar xzf full-20071001.tar.gz
$ tar xzf incr-20071002.tar.gz
$ tar xzf incr-20071003.tar.gz
$ tar xzf incr-20071004.tar.gz
$ tar xzf incr-20071005.tar.gz
{% endhighlight %}

After which you should have you home directory restored exactly as it
appeared at 1:00pm on October 10, 2007.
