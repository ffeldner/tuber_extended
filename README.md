# tuber_extended - tube.tugraz.at downloader

now with support for downloading presentation slide video track and vtt subtitles. also now supports more than only the first 100 episodes in a given lecture series (up to 2000). fallback is more robust and deduplicated now.

huge thanks to daev for creating this

## requirements

the download script is written using bash syntax
and expects [jq](https://stedolan.github.io/jq/), [htmlq](https://github.com/mgdm/htmlq) and [curl](https://curl.se/) on the PATH.

## docker

if you want to use tuber without polluting your PATH you might want to use the docker container.

## using it to download

tuber expects some environment variables:

* USER and PASS contain the credentials to logon to tube.tugraz.at
* COURSE contains the course-uuid to download

you can also set the following additional environment variables:
NOPRESENTATIONSLIDES and NOSUBTITLES to 0 or 1 respectively to control the download of the presentation/slides video file as well as the subtitles that are present in newer lectures in vtt format.

default setting is no slides but subtitles when existant

### example without docker

to download analysis 1 to the current directory

    USER=your_user PASS=your_pass COURSE=4636c0b6-71a8-45f1-bc6a-ea850f46175e /path/to/tuber.sh
