--- 
wordpress_id: 47
layout: post
title: Automatic backups using <code>cron</code> and <code>tar</code>
wordpress_url: http://www.beyond-syntax.com/?p=47
---
<em>This post is an import from a presentation I did in October of 2007.  Since I've made this presentation, I've stopped using my own script and suggest you use another tool for backups.  I hear <a href="http://www.gnu.org/savannah-checkouts/non-gnu/rdiff-backup/">rdiff-backup</a> is good.  However, I believe this is still a good introduction to <code>bash</code> scripting, <code>cron</code>, and <code>tar</code>.</em>

<!--more-->
<h3>Original Presentation</h3>
Although it may be less useful without the accompanying speaker, the <a href="http://www.beyond-syntax.com/uploads/2009/02/backup.pdf">original presentation</a> is available.
<h3>Source code for the shell script</h3>
I have made the source code (<a href="http://www.beyond-syntax.com/uploads/2009/02/backup.sh">backup.sh</a>) available for download. In the top matter of the file describe how to add the script to your crontab.
<h3>Description of the script</h3>
For me, the best way to learn something is to take it line by line and that is what I'm going to do below. Naturally I will combine lines which are similar to save space. Since the target audience is someone who has never seen a shell script, some information may seem unimportant to you.

The concatenated source code that appears on this page may not agree with the source available for download. Odds are I decided the change was not worth updating this page, but made available for consumption as the script. If you notice something that is greatly different please contact me.
<pre lang="bash">#!/bin/sh</pre>
Selection of a shell interpreter. This <em>must</em> be the first line in the file and be prefix with the 'hash-bang' (or 'sh-bang' for short).

I use <code>/bin/sh</code> since it seems to be the most universal amongst systems. It should be noted that on many systems <code>/bin/sh</code> is that same as <code>/bin/bash</code>, I do not know if this means the script will not work in <code>/bin/sh</code>.
<pre lang="bash">SNAPDIR=/var/snapshots/$USER
RMT_DIR="user@hostname:~/snapshots"
RMT_OPTIONS="-i $HOME/.ssh/id_dsa"</pre>
Setting some simple variables. Note that there are no spaces between the variable name, the equal sign, and the value; your script will not work with spaces between these three items.

Here I set the snapshot directory (where snapshots should be stored) to be <code>/var/snapshots/$USER</code>. <code>$USER</code> is a special variable that is the same as the user running the script.

Next are <code>RMT_DIR</code> and <code>RMT_OPTIONS</code> which are quoted. Quotes simply make sure spaces are included in the variable. Again, <code>$HOME</code> is a environmental variable that is always a user's home directory.
<pre lang="bash">RMT_CMD=$(which scp)
DATE=$(date +%Y%m%d)
TAR=$(which tar)
MKDIR=$(which mkdir)
CHMOD=$(which chmod)</pre>
This group of variables will run commands in a "sub-shell" before setting the variable name to the value. For example <code>$(which scp)</code> will execute <code>which scp</code> on the system and assign the value returned to <code>RMT_CMD</code>.
<pre lang="bash">LAST_FULL=$(stat -f "%Dc %Sc" -t "%Y%m%d" ${SNAPDIR}/full-*.tar.gz \
            2&gt; /dev/null| sort -n | tail -n1)
LAST_TS=$(echo ${LAST_FULL} | awk '{ print $1}')
LAST_DATE=$(echo ${LAST_FULL} | awk '{ print $2}')</pre>
In the final group of variables we use "pipes" which use the output of the first command as the input of the second command. For <code>LAST_FULL</code> we first <code>stat</code> files of the pattern "full-*.tar.gz" in the <code>${SNAPDIR}</code> directory. <em>(N.B. <code>${SNAPDIR}</code> dereferences the <code>SNAPDIR</code> variable we set earlier. The curly braces are not strictly necessary, however I use them when referring to local variables.)</em> For <code>stat</code> I am specifying that the output should be of the form "&lt;timestamp&gt; &lt;YYYYMMDD&gt;", then <code>sort</code> the output using the number in the first column, and finally, take only the last file listed.

Once the last full snapshot time is known, we split it into two variables (<code>LAST_TS</code> and <code>LAST_DATE</code>), again using pipes and awk.
<pre lang="bash">if [ ! -d ${SNAPDIR} ]; then
	${MKDIR} ${SNAPDIR}
	${CHMOD} go-rwx ${SNAPDIR}
fi</pre>
We'll start by making sure the directory snapshots directory exists. If it doesn't, make the directory and remove all permission from anyone not this user.
<pre lang="bash">function incr {
	${TAR} czf ${SNAPDIR}/incr-${DATE}.tar.gz \
	       --exclude-from $HOME/.snap-exclude \
	       --listed-incremental=${SNAPDIR}/$USER-${LAST_DATE}.snar \
	       $HOME &lt; /dev/null 2&lt; /dev/null

	${CHMOD} go-rwx ${SNAPDIR}/incr-${DATE}.tar.gz

	if [ "${RMT_CMD}" != "" ]; then
		${RMT_CMD} ${RMT_OPTIONS} ${SNAPDIR}/incr-${DATE}.tar.gz \
		       ${SNAPDIR}/$USER-${LAST_DATE}.snar \
		       ${RMT_DIR}
	fi
}</pre>
For creating an incremental backup. Using <code>tar</code>, <code>c</code>reate a g<code>z</code>ipped <code>f</code>ile at <code>${SNAPDIR}/incr-${DATE}.tar.gz</code>. Since you may not want <em>all</em> of your home directory backed up, you can exclude files listed in the <code>.snap-exclude</code> file. Now the most important part, <code>--listed-incremental</code>, tells <code>tar</code> what the timestamps of the files were last time it executed. If the timestamp on a file is newer than in the snar ("snapshort archive"), it will be added to the tarball. The last argument to tar is simply the directory to backup. <code>&gt;</code> and <code>2&gt;</code> redirect standard out and standard error to <code>/dev/null</code>, thus suppressing all output.

For the sake of security, we revoke all access from the file except for the current user.

The final step is to check of a <code>RMT_CMD</code> exists, if it does execute it. <code>scp</code> works well for this step, as would <code>rsync</code>.
<pre lang="bash">function full {
	${TAR} czf ${SNAPDIR}/full-${DATE}.tar.gz \
	       --exclude-from $HOME/.snap-exclude \
	       --listed-incremental=${SNAPDIR}/$USER-${DATE}.snar \
	       $HOME &lt; /dev/null 2&lt; /dev/null

	${CHMOD} go-rwx ${SNAPDIR}/full-${DATE}.tar.gz
	${CHMOD} go-rwx ${SNAPDIR}/$USER-${DATE}.snar

	if [ "${RMT_CMD}" != "" ]; then
		${CMT_CMD} ${RMT_OPTIONS} ${SNAPDIR}/full-${DATE}.tar.gz \
		       ${SNAPDIR}/$USER-${DATE}.snar \
		       ${RMT_DIR}
	fi
}</pre>
Creating a full backup is not much different than an incremental backup. The only difference is the <code>--listed-incremental</code> file (<code>tar</code> will create a new snapshot archive), thus starting with a fresh backup and timestamps. The reason for this is explained in the "Recovery" section.

The rest of the function is mostly the same as an incremental backup.
<pre lang="bash">function normal {
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
}</pre>
Here we have the main "brain" of the program. It begins by making sure a backup exists, if one doesn't the script makes a full backup. If at least one full backup exists, then we find out how long it has been since the last full backup and compare that to how frequently full backups should be made. <code>SNAP_FRAME</code> holds the frequency in which backups should be made (every 7 days * 24 hours / day * 60 minutes / hour * 60 seconds / minute (minus 1 hour for time delays)). If too much time has passed, create a full backup and clean out the old files. Otherwise just create an incremental backup.
<pre lang="bash">function clean {
	true
}</pre>
The script isn't perfect. I have yet to determine a good way to clean out old files (one that isn't tied to either <code>scp</code> or <code>rsync</code>).
<pre lang="bash">function usage {
	echo "usage: $0 [type]"
	echo "[type] can be one of the following:"
	echo "  normal - follow the daily incremental and weekly backup schedule"
	echo "  incr   - create a incremental backup of $HOME to ${SNAPDIR}"
	echo "  full   - create a full backup of $HOME to ${SNAPDIR}"
	echo "  clean  - cleanup backups older than one month"
	echo "  usage  - display this screen"
	echo "  --help - display this screen"

	exit 1
}</pre>
This simple function displays the usage information if requested. <code>$0</code> is the script name as typed by the user.
<pre lang="bash">case "$1" in
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
esac</pre>
Finally, the driver of the program, a case statement which reads the first argument (<code>$1</code>) and executes the desired function. The default operation is to run in normal mode, but the user is able to force an incremental update, full update, or clean out old files.
<h3>Setting up a cronjob</h3>
<code>cron</code> is a simple utility that exists on almost all UNIX or UNIX-like systems. A daemon runs every minute to see if any user has a "cronjob" that needs to be executed, if a user does it will run it.

User level cronjobs are maintained by a program called <code>crontab</code>, to view your current crontab type: <code>crontab -l</code>, to edit your crontab use <code>crontab -e</code>.

I personally like to keep all my user level cronjobs in one place, <code>$HOME/.cronjobs/</code>. This folder conatins two files: <code>crontab</code> and <code>backup.sh</code>. <code>crontab</code> is a text file which hold what cronjobs I'd like to have run while <code>backup.sh</code> is the file described above.

My crontab files looks something like this:
<pre lang="bash"># User level crontab
# min hr mday month wday command
00    13  *    *     *    /path/to/home/directory/.cronjobs/backup.sh</pre>
Which means I backup my files everyday at precisly 1:00pm by running the file located in <code>/path/to/home/directory/.cronjobs/backup.sh</code>. This can then be loaded into the system cronjobs using the following command.
<pre lang="bash">crontab &lt; crontab</pre>
<h3>Recovering the data</h3>
If you ever need to restore your backed up data all you need to do is find the most recent full backup (we'll say <code>full-20071001.tar.gz</code>) and all the incremental backups since then (in our example <code>incr-2007100[2-5].tar.gz</code>). You'll start by extracting the full backup to the correct folder via <code>tar xzf full-20071001.tar.gz</code>, followed by the incremental backups oldest to newest. Effectively you are restoring your entire home folder from n-days ago and applying the differences from each succeeding day. The commands should go as below (where <code>$</code> is the shell prompt).
<pre lang="bash">$ tar xzf full-20071001.tar.gz
$ tar xzf incr-20071002.tar.gz
$ tar xzf incr-20071003.tar.gz
$ tar xzf incr-20071004.tar.gz
$ tar xzf incr-20071005.tar.gz</pre>
After which you should have you home directory restored exactly as it appeared at 1:00pm on October 10, 2007.

Attachment: <a href="http://www.beyond-syntax.com/uploads/2009/02/backup.pdf">Automatic backups using <code>cron</code> and <code>tar</code></a> (PDF)
Attachment: <a href="http://dev.beyond-syntax.com/scripts/backup.sh">backup.sh</a> (Shell script)
