# edict CLI - command line interface to edict.pl

## What?

A little command line program which displays dictionary entries for a given
word. It can also optionally play back the pronounciation of the word.

The usage looks like this:

    -▶ dict cwaniak
    cwaniak                     -- dodger
    cwaniak                     -- sly dog
    cwaniak; spryciarz          -- fox
    cwaniak; spryciarz          -- shark
    cwaniak; spryciarz          -- sharpie
    cwaniak; spryciarz          -- smart aleck
    cwaniak; spryciarz          -- smart-ass
    cwaniak; spryciarz          -- smoothie
    cwaniak; spryciarz          -- wise-ass
    cwaniak; spryciarz; mądrala -- smartie-pants
    cwaniak; spryciarz; mądrala -- smarty-pants

## How?

First and foremost, you need to download and install
[Chicken Scheme](http://code.call-cc.org/). It should work out of the box on any
Unix-like system. It may be harder to setup on Windows (pre-Windows 10), but I'm
not familiar with Windows development and can't help you, sorry.

Then you need to install dependencies with `chicken-install`:

    for pkg in http-client html-parser sxpath args clojurian utf8; do
        chicken-install $pkg
    done

Then you can run the program using Chicken interpreter like this:

    csi -w -s dict.scm word

or you can compile the program to a self-contained, native binary:

    csc dict.scm && ./dict word

The compiled binary cuts the startup time roughly in half:

    -▶ time csi -s dict.scm word
    ...
    csi -s dict.scm word  0,15s user 0,01s system 57% cpu 0,291 total

    -▶ time ./dict word
    ...
    ./dict word  0,04s user 0,01s system 26% cpu 0,180 total

which is nice for a CLI program.

## Why?

As a programmer I have a terminal open at all times, switching to it and typing
a short command is much faster than doing the same inside a browser.

Also, it was a nice excercise I did to familiarize myself with Chicken Scheme,
which I heard many good things about. Turns out it is quite good: both
interpreter and compiler are quite fast and the number of packages (called eggs)
is sufficient. I chose Chicken over Racket for this project specifically because
of AOT compilation which cuts down the startup time: for short-lived processes
it generally results in better user experience than JIT.

## TODO

* pronounciation playback code is currently broken
* pronounciation playback should be configurable, as it currently hardcodes
  mpg123 invocation
