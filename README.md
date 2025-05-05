# tuber_extended - tube.tugraz.at downloader

now with support for downloading presentation slide video track and vtt subtitles. also now supports more than only the first 100 episodes in a given lecture series (up to 2000). fallback is more robust and deduplicated now.

huge thanks to daef for creating this

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

default setting is slides and subtitles if they exist

### example without docker

to download signal processing to the current directory

login to TUBE in your browser and extract the JSESSIONID cookie through devtools (F12). put it into the 'cookie' file.

    COURSE=32dade20-36bd-4f2b-94f6-b655ff2ed74f ./tuber.sh

### example output

    [>>O<<] manual cookie mode using cookie file active - please put your JSESSIONID cookie from your browser into the file 'cookie' [>>O<<]

    Episode JSON URL: https://tube.tugraz.at/search/episode.json?limit=2000&offset=0&sid=32dade20-36bd-4f2b-94f6-b655ff2ed74f

    --- Episode #08 (shifted to April 11, 2025) from 2025-04-11
    No URL found for Presentation/Slides
    No URL found for Subtitles - This is normal for content from before 2023
    >>> Presenter URL: https://tube.tugraz.at/static/mh_default_org/engage-player/034f5b55-9ea8-44f8-baba-7bd21ee5d4ba/49d0f818-ebb4-4b1f-b9be-2ab39463d52e/block_opencast_video_uploadCkYWI2_RPReplay_Final1744362036.mp4
    downloading Presenter to 442009 Fundamentals of discretetime signals and systems LectureCourse SS/2025-04-11_08shiftedtoApril112025.mp4
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100  272M  100  272M    0     0  30.9M      0  0:00:08  0:00:08 --:--:-- 21.7M

    --- Episode # 07 from 2025-04-02
    >>> Presenter URL: https://tube.tugraz.at/static/mh_default_org/engage-player/e6c18a33-d245-4e42-9922-66290e79c140/a85ddfa4-dae0-4a05-83b6-76e2b20a6320/hsi13_Apr02_08-10-37.mp4
    >>> Presentation URL: https://tube.tugraz.at/static/mh_default_org/engage-player/e6c18a33-d245-4e42-9922-66290e79c140/2b2f7953-5acb-4e64-8525-8358863e6f78/hsi13_Apr02_08-10-37.mp4
    >>> Subtitle URL: https://tube.tugraz.at/static/mh_default_org/engage-player/e6c18a33-d245-4e42-9922-66290e79c140/1c5f3063-c0cd-4a1e-afc5-14a616be1027/__id__presenter.vtt
    downloading Presenter to 442009 Fundamentals of discretetime signals and systems LectureCourse SS/2025-04-02_07.mp4
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100  871M  100  871M    0     0  25.5M      0  0:00:34  0:00:34 --:--:-- 27.2M
    downloading Presentation to 442009 Fundamentals of discretetime signals and systems LectureCourse SS/2025-04-02_07_Slides.mp4
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100 76.3M  100 76.3M    0     0  13.9M      0  0:00:05  0:00:05 --:--:-- 13.9M
    downloading Subtitles to 442009 Fundamentals of discretetime signals and systems LectureCourse SS/2025-04-02_07.vtt
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100  118k  100  118k    0     0  89397      0  0:00:01  0:00:01 --:--:-- 89343

    --- Episode # 06 from 2025-03-26
    
    ...

## To-Do List

* give option to mux slides and video and subtitles into one file (VLC supports multi-monitor synchronous viewing that way)

* make offset and limit parameters to episode.json customizable through env variables

* allow filtering of date ranges
