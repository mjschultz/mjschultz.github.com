---
layout: post
title: Sophos Holidy Puzzle Walkthrough
keywords: base64,rot13,zip,gif,anagram,unix
description: A quick little walkthrough of how I solved the puzzles in the Sophos Holiday Puzzle challenge.
---
In case you missed the it there was a short [holiday puzzle
challenge](http://nakedsecurity.sophos.com/2011/12/19/try-the-christmas-sophospuzzle-and-win-a-lego-mindstorm/) over
at the [Sophos Naked Security blog](http://nakedsecurity.sophos.com/).
If you want to attempt solving it yourself I'd suggest going over and
checking it out now before reading on because there will be plenty of
spoilers.
There is also a more Windows centric version on [Belahzurs
Thoughts](http://belahzurs.blogspot.com/2011/12/sophospuzzle-answers.html),
if that's what you would rather see that.
Now, on with the challenges!

# Step 1 #

The only hint is: `=ImYndmbn1ieiBnLmJWdjJmZ`.

The first things I noticed about this were the `=` at the beginning and the
character set consisting of `[A-Za-z0-9]`, meaning this is likely a
reversed [Base64](http://www.wikipedia.org/wiki/Base64) encoding.
(Note that Base64 also includes `+` and `/`; they just don't appear here.)
Using [Python](http://www.python.org), these two actions are simple enough:

    >>> '=ImYndmbn1ieiBnLmJWdjJmZ'[::-1].decode('base64')
    'fbcubf.pbz-gnggbb'

That's still junk though, but now the junk looks a bit like a web address.
Each letter is probably just shifted over a little bit (i.e. `a` becomes
`n`).
The most common form of character shift is to rotate the alphabet 13
characters ("[rot13](http://www.wikipedia.org/wiki/ROT13)").
Well Python can do that as well:

    >>> 'fbcubf.pbz-gnggbb'.decode('rot13')
    u'sophos.com-tattoo'

(The preceeding `u` just means the string is in
[unicode](http://www.wikipedia.org/wiki/Unicode).)
Replace the `-` with a `/` and we've got the web address for step 2.

# Step 2 #

Visiting the [Step 2](http://sophos.com/tattoo) site gives us our second
puzzle:  a text file with some hints and the following (suspicious block of
text).

    l504b0i304140st00hbs000800ld26492n3f0496707b4rb010000290400t0027001hcg0073656i3757r26974792d616476
    6963652d6l66f722d74726w1i6t96e2d636f6d6d75746572732e67696655540900h031b44etdh4e3344ed4e75780b00010
    4f5010000041r4000000051gafao6986186b0dded84f13cbe5f3dente45dc4e786tt03a1ob4775a0b6104o83df1c74498a
    1l447f7ad0id==1cb7abd==c84f904=======..======f184=======0.===========.2==256c==d3446ffsb2d830825c0
    d320ae6fd64|  |etde2|  |83cba/       ||   _  \3c|   ____||           ||  |4h|  |54ddbf6b47asdl2063
    8n34r58be58|  |840d6|  |04th|   (----`|  |_)  |0|  |__30g`---|  |----`|  |==|  |iaderf142179334fld
    bwci6cbdfdt|  |91b52|  |6225c\   \d2aa|   _  <63|   __|328dbe|  |3d1c7|   __   |hf87ta3698hr193340
    de1f9gdf023|  `====.|  |1.----)   |014|  |_)  |3|  |____f0o87|  |e72en|  |14|  |4t8dct07cde1964dd7
    tf914o05b3e|_______||__|f|_______/6a7b|______/c5|_______|95fb|__|85oef|__|al|__|84611d43ai44acsc50
    0c154e8t7283b7fa2hsf3lc7bdnba80dca3a8c43r8t1aee241476424a9c52c8060579hdgi6r0414ablbc7wfa7ec3i27et6
    5790800013681030ahb11466a84dth81rdge35c538b34d706697a867ff5df7a706156o36e97cadden1t326306t57343718
    173t7e92=======.055ao===6371ed6==oea0f7698ea===26c862.==add==.ld=======3di=======a.======7s44493bf
    d124179/       |tb70/   \88374|  |010a6h025/   \1af2a|  \s|  |l|       \e|   ____||   _  \5822c768
    80c9b2|   (----`722/  ^  \18e9|  |bdf3n50c/  ^  \1bf3|   \|  |2|  .--.  ||  |__3dd|  |_)  |e26276r
    f0d8dd9\   \bdt66f/  /_\  \4ch|  |fc295d2/  /_\  \23f|  . `  |9|  |gi|  ||   __|2f|      /d89059c0
    e25.----)   |52r6/  _____  \34|  `====.b/  _____  \5l|  |\   |0|  '--'  ||  |____4|  |\  \====.b07
    w08|_______/0496/__/707b4\__\b|_______|/__/01000\__\0|__|2\__|9|_______/0|_______||4_|0`._____|000
    504b01021e0314000b0008i00d2t64923hf049t670h7b4b0100002904000r0g27001800000000000000000on0a48100000
    000736563757269t74792d61t6t4766963652d666f722od7472616o96e2d636f6dl6d75746572732e6769665554050i003
    1bs44ed4the75780bs000ln104f50100r000t4140000005h04b050600000g0i00010001006d000000bc01000000r00lwit

This is most likely the starting point to the puzzle and one of the hints
was that we'll need a password in this stage of the puzzle.
After a bit of thinking I figured that a [Zip
file](http://www.wikipedia.org/wiki/Zip \(file format\)) is the most likely candidate for
cross-platform password protection, but how is that block of text a Zip file?
Looking through the Wikipedia page shows that `PK` is the commonly the
first two bytes of a Zip file, it just so happens that that translates to
`504b` in [hexadecimal](http://www.wikipedia.org/wiki/Hexadecimal).
Perhaps if I strip all the non-hex characters from the text block it will
be a Zip file.
This time I'll just use the Unix
[`tr`](http://www.wikipedia.org/wiki/Tr_\(Unix\)) utility to strip non-hex
characters:

    $ tr -cd [A-Fa-f0-9] < topsecret.in > topsecret.hex

This `d`eletes the `c`ompliment of the character set `[A-Fa-f0-9]` from the
input file `topsecret.in` and outputs to `topsecret.hex`.
The next step is to convert the
[ASCII](http://www.wikipedia.org/wiki/ASCII) representation of the hex digits to
binary.
Again, I turned to Python for this:

    >>> infile = open('topsecret.hex')       # Sets up a file descriptor
    >>> line = infile.readline()             # Reads the first line from infile (the only line)
    >>> b = ''                               # An empty string we'll build on
    >>> for c in range(0, len(line), 2) :    # Go through the characters (in steps of 2)
    ...     v = int(line[c:c+2], 16)         # Convert 2 ASCII values into their actual value
    ...     b += chr(v)                      # Append the actual value to b string
    ...
    >>> infile.close()                       # Close the input file
    >>> outfile = open('topsecret.zip', 'w') # Open the output file in write mode
    >>> outfile.write(b)                     # Write the contents of b to outfile
    >>> outfile.close()                      # Close the output file

Now we've got a Zip file ready to go!
We know the password was the cipher used to get from step 1 to step 2, so
just unzip the file:

    $ unzip topsecret.zip
    [...] password: rot13
      inflating: security-advice-for-train-commuters.gif  

Open up the file and you get to see a fantastic shade of pink!

->![A beautiful shade of pink!](/static/img/2011-12-pink.gif)<-

We are probably not done quite yet, eh?
We can look at the actual contents of the file by using
[`xxd`](http://linuxcommand.org/man_pages/xxd1.html):

    $ xxd security-advice-for-train-commuters.gif > security-advice-for-train-commuters.gif.dump

Opening that dump file up in a text editor and we see "Since when was pink
a shade of gray?"
Hmmm, maybe if we convert part of the from pink to gray we'll see something
new.
From years in web development you may know that #f1bbed is a shade of pink
and that value shows up twice in the [GIF
file](http://www.wikipedia.org/wiki/Graphics Interchange Format).
I decided to change the first instance to `444444` a nice dark shade of
gray.
Now we can `r`everse the hex dump output back to the binary GIF format:

    $ xxd -r security-advice-for-train-commuters.gif.dump > final.gif

Open that file and you get a much more clear version of the clue.

->![SPY BOUNTY RECURS?](/static/img/2011-12-final.gif)<-

Probably not the final answer (it's an anagram).
(I knew it was an anagram, but I couldn't figure out what it was saying so
I emailed Paul Ducklin for a hint. -- I got stuck thinking "security" was
in it with the "?" being any character.)

The hint was in a recent article about [Lost USB
keys](http://nakedsecurity.sophos.com/2011/12/07/lost-usb-keys-have-66-percent-chance-of-malware/),
with the clue being "what is the article trying to tell you?"

Taking out "USB" from the image, it isn't too hard to determine the final
answer:

->ENCRYPT YOUR USBS<-

*I'm sure there are better tools to get to the answer, but this is how I
did it!*
