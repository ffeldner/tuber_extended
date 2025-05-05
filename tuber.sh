#!/bin/bash

: "${USER:=user}"
: "${PASS:=pass}"
: "${COURSE:=0bcae57f-740a-4033-b560-e9747ee80d78}"
: "${QUALITY_PRESENTER:=high}"
: "${QUALITY_PRESENTATION:=high}"
: "${FALLBACK_RESOLUTION:=1280x720}"
: "${NOPRESENTATIONSLIDES:=1}"
: "${NOSUBTITLES:=0}"

if [[ $NOSUBTITLES == 1 ]] ; then
	echo "Subtitle Download disabled..."
fi
if [[ $NOPRESENTATIONSLIDES == 1 ]] ; then
	echo "Presentation/Slides Download disabled..."
fi

CURL="curl -L -c cookies -b cookies"
CURL_STDOUT="$CURL -s -o -"
TUBE="https://tube.tugraz.at"
INITURL="$TUBE/Shibboleth.sso/Login?target=/paella/ui/index.html"
EPIURL="$TUBE/search/episode.json?limit=2000&offset=0&sid=$COURSE"

RESPONSE=$($CURL_STDOUT -L -c cookies -b cookies -s -o - ${INITURL})
if [[ ! $RESPONSE =~ "Welcome to TU Graz TUbe" ]] ; then
	echo logging in
	LOGINURL="https://sso.tugraz.at$(echo "$RESPONSE" | htmlq --attribute action 'form[name=form1]')"
	RESPONSE=$($CURL_STDOUT --data-urlencode lang="de" --data-urlencode _eventId_proceed="" --data-urlencode j_username="${USER}" --data-urlencode j_password="${PASS}" ${LOGINURL})
	if [[ ! $RESPONSE =~ "Welcome to TU Graz TUbe" ]] ; then
		echo sso logon failed
		exit 23
	fi
fi
echo logged in
echo $EPIURL
$CURL -s -o episodes.json "$EPIURL"

SERIESTITLE="$(cat episodes.json | jq -c "[.[\"search-results\"].result[].mediapackage| {seriestitle: .seriestitle}] | unique[0] | .seriestitle"| tr -d '[:punct:]')"

mkdir -p "$SERIESTITLE"

cat episodes.json | jq -c "
	.[\"search-results\"]
	.result[]
	.mediapackage
	| {

		date: .start,
		title: .title,
		presenter: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presenter\/delivery\")
			| select(.tags.tag[]==\"$QUALITY_PRESENTER\" or .tags.tag[]==\"1080p-quality\")
			| .url],
		presentation: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presentation\/delivery\")
			| select(.tags.tag[]==\"$QUALITY_PRESENTATION\" or .tags.tag[]==\"1080p-quality\")
			| .url],
		fallback_presenter: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presenter\/delivery\")
			| select(.video.resolution==\"$FALLBACK_RESOLUTION\" or .tags.tag[]==\"720p-quality\")
			| .url],
		fallback_presentation: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presentation\/delivery\")
			| select(.video.resolution==\"$FALLBACK_RESOLUTION\" or .tags.tag[]==\"720p-quality\")
			| .url],
		vtt: [ .attachments.attachment[]
			| select(.mimetype==\"text\/vtt\")
			| .url]
	}" |
		while read episode
do
	DATE="$(echo "$episode" | jq -r .date)"
	TITLE="$(echo "$episode" | jq -r .title)"
	FN="$SERIESTITLE/${DATE:0:10}_$(echo "$TITLE" | tr -dc 'a-zA-Z0-9' ).mp4"
	FNS="$SERIESTITLE/${DATE:0:10}_$(echo "$TITLE" | tr -dc 'a-zA-Z0-9' )_Slides.mp4"
	FNV="$SERIESTITLE/${DATE:0:10}_$(echo "$TITLE" | tr -dc 'a-zA-Z0-9' ).vtt"
	URLPER="$(echo "$episode" | jq -r .presenter[0])"
	URLPION="$(echo "$episode" | jq -r .presentation[0])"
	URLVTT="$(echo "$episode" | jq -r .vtt[0])"

	echo -e "\n--- Episode $TITLE from ${DATE:0:10}"

	if [[ "$URLPER" == "null" ]] ; then
		URLPER="$(echo "$episode" | jq -r .fallback_presenter[0])"
		if [ "$URLPER" != "null" ] ; then
			echo "Falling back to medium quality for Presenter"
		else
			echo "No URL found for Presenter"
		fi
	fi
	if [[ $NOPRESENTATIONSLIDES == 0 && "$URLPION" == "null" ]] ; then
		URLPION="$(echo "$episode" | jq -r .fallback_presentation[0])"
		if [ "$URLPION" != "null" ] ; then
			echo "Falling back to medium quality for Presentation/Slides"
		else
			echo "No URL found for Presentation/Slides"
		fi
	fi
	if [[ $NOSUBTITLES == 0 && "$URLVTT" == "null" ]] ; then
		echo "No URL found for Subtitles - This is normal for content from before 2023"
	fi
  echo "Presenter URL: " $URLPER" | Presentation URL: " $URLPION" | Subtitle URL: " $URLVTT
  if [[ "$URLPER" != "null" ]] ; then
    if [[ ! -f "$FN" ]] ; then
      echo "downloading Presenter to $FN"
      $CURL -C - -o "$FN.part" "$URLPER"
      mv "$FN"{.part,}
    fi
  fi
  if [[ $NOPRESENTATIONSLIDES == 0 && "$URLPION" != "null" ]] ; then
    if [[ ! -f "$FNS" ]] ; then
      echo "downloading Presentation to $FNS"
      $CURL -C - -o "$FNS.part" "$URLPION"
      mv "$FNS"{.part,}
    fi
  fi
  if [[ $NOSUBTITLES == 0 && "$URLVTT" != "null" ]] ; then
    if [[ ! -f "$FNV" ]] ; then
      echo "downloading Subtitles to $FNV"
      $CURL -C - -o "$FNV.part" "$URLVTT"
      mv "$FNV"{.part,}
    fi
  fi
done
