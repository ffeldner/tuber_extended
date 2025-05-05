#!/bin/bash

: "${USER:=user}"
: "${PASS:=pass}"
: "${COURSE:=32dade20-36bd-4f2b-94f6-b655ff2ed74f}"
: "${QUALITY_PRESENTER:=high}"
: "${QUALITY_PRESENTATION:=high}"
: "${FALLBACK_ACTIVE:=1}"
: "${NOPRESENTATIONSLIDES:=0}"
: "${NOSUBTITLES:=0}"

: "${MANUALCOOKIES:=1}"

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

if [[ ! $MANUALCOOKIES == 1 ]] ; then
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
else
	echo "[>>O<<] manual cookie mode using cookie file active - please put your JSESSIONID cookie from your browser into the file 'cookie' [>>O<<]"
fi

echo -e "\nEpisode JSON URL: "$EPIURL
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
		fallback1_presenter: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presenter\/delivery\")
			| select(.tags.tag[]==\"medium\" or .tags.tag[]==\"720p-quality\")
			| .url],
		fallback1_presentation: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presentation\/delivery\")
			| select(.tags.tag[]==\"medium\" or .tags.tag[]==\"720p-quality\")
			| .url],
		fallback2_presenter: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presenter\/delivery\")
			| select(.tags.tag[]==\"low\")
			| .url],
		fallback2_presentation: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presentation\/delivery\")
			| select(.tags.tag[]==\"low\")
			| .url],
		fallback1_presenter_resolution: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presenter\/delivery\")
			| select(.tags.tag[]==\"medium\" or .tags.tag[]==\"720p-quality\")
			| .video.resolution],
		fallback1_presentation_resolution: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presentation\/delivery\")
			| select(.tags.tag[]==\"medium\" or .tags.tag[]==\"720p-quality\")
			| .video.resolution],
		fallback2_presenter_resolution: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presenter\/delivery\")
			| select(.tags.tag[]==\"low\")
			| .video.resolution],
		fallback2_presentation_resolution: [ .media.track[]
			| select(.mimetype==\"video\/mp4\")
			| select(.type==\"presentation\/delivery\")
			| select(.tags.tag[]==\"low\")
			| .video.resolution],
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
		RES1=($(echo "$episode" | jq -r .fallback1_presenter_resolution[0] | sed 's/x/ /g'))
		RES2=($(echo "$episode" | jq -r .fallback2_presenter_resolution[0] | sed 's/x/ /g'))
		if [[ $RES1 != "null" && $RES2 != "null" ]] ; then
			if [ $((${RES1[0]} * ${RES1[1]})) -gt $((${RES2[0]} * ${RES2[1]})) ] ; then
				URLPER="$(echo "$episode" | jq -r .fallback1_presenter[0])"
			else
				URLPER="$(echo "$episode" | jq -r .fallback2_presenter[0])"
				echo "Whoops, medium and low are inverted"
			fi
		else
			URLPION="$(echo "$episode" | jq -r .fallback1_presentation[0])"
		fi
		if [ "$URLPER" != "null" ] ; then
			echo "Falling back to medium quality for Presenter"
		else
			echo "No URL found for Presenter"
		fi
	fi
	if [[ $NOPRESENTATIONSLIDES == 0 && "$URLPION" == "null" ]] ; then
		RES1P=($(echo "$episode" | jq -r .fallback1_presentation_resolution[0] | sed 's/x/ /g'))
		RES2P=($(echo "$episode" | jq -r .fallback2_presentation_resolution[0] | sed 's/x/ /g'))
		if [[ $RES1P != "null" && $RES2P != "null" ]] ; then
			if [ $((${RES1P[0]} * ${RES1P[1]})) -gt $((${RES2P[0]} * ${RES2P[1]})) ] ; then
				URLPION="$(echo "$episode" | jq -r .fallback1_presentation[0])"
			else
				URLPION="$(echo "$episode" | jq -r .fallback2_presentation[0])"
				echo "Whoops, medium and low are inverted"
			fi
		else
			URLPION="$(echo "$episode" | jq -r .fallback1_presentation[0])"
		fi
		if [ "$URLPION" != "null" ] ; then
			echo "Falling back to medium quality for Presentation/Slides"
		else
			echo "No URL found for Presentation/Slides"
		fi
	fi
	if [[ $NOSUBTITLES == 0 && "$URLVTT" == "null" ]] ; then
		echo "No URL found for Subtitles - This is normal for content from before 2023"
	fi
	if [[ $URLPER != "null" ]] ; then
		echo ">>> Presenter URL: "$URLPER
	fi
	if [[ $URLPION != "null" ]] ; then
		echo ">>> Presentation URL: "$URLPION
	fi
	if [[ $URLVTT != "null" ]] ; then
		echo ">>> Subtitle URL: "$URLVTT
	fi
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
