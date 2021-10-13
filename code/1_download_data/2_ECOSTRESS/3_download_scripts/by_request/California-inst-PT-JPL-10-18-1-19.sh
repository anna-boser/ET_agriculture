#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (annaboser): " username
    username=${username:-annaboser}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.10/ECOSTRESS_L1B_GEO_02920_003_20190110T150436_0601_02.h5"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.10/ECOSTRESS_L1B_GEO_02920_003_20190110T150436_0601_02.h5 -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.10/ECOSTRESS_L1B_GEO_02920_003_20190110T150436_0601_02.h5 | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.10/ECOSTRESS_L1B_GEO_02920_003_20190110T150436_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.26/ECOSTRESS_L1B_GEO_03160_003_20190126T011306_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.27/ECOSTRESS_L1B_GEO_03175_002_20190127T002130_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.27/ECOSTRESS_L1B_GEO_03175_003_20190127T002222_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.27/ECOSTRESS_L1B_GEO_03175_004_20190127T002314_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.27/ECOSTRESS_L1B_GEO_03190_002_20190127T233046_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.28/ECOSTRESS_L1B_GEO_03191_002_20190128T010658_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.28/ECOSTRESS_L1B_GEO_03191_003_20190128T010750_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.29/ECOSTRESS_L1B_GEO_03206_003_20190129T001523_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.29/ECOSTRESS_L1B_GEO_03206_004_20190129T001615_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.29/ECOSTRESS_L1B_GEO_03206_005_20190129T001707_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.29/ECOSTRESS_L1B_GEO_03206_006_20190129T001759_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.29/ECOSTRESS_L1B_GEO_03221_002_20190129T232346_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.29/ECOSTRESS_L1B_GEO_03221_003_20190129T232438_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.29/ECOSTRESS_L1B_GEO_03221_004_20190129T232530_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.29/ECOSTRESS_L1B_GEO_03221_005_20190129T232622_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.31/ECOSTRESS_L1B_GEO_03252_005_20190131T231953_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOA/ECOSTRESS/ECO1BGEO.001/2019.01.31/ECOSTRESS_L1B_GEO_03252_006_20190131T232045_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.10/ECOSTRESS_L3_ET_PT-JPL_02920_003_20190110T150436_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.26/ECOSTRESS_L3_ET_PT-JPL_03160_003_20190126T011306_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.27/ECOSTRESS_L3_ET_PT-JPL_03175_002_20190127T002130_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.27/ECOSTRESS_L3_ET_PT-JPL_03175_003_20190127T002222_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.27/ECOSTRESS_L3_ET_PT-JPL_03175_004_20190127T002314_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.27/ECOSTRESS_L3_ET_PT-JPL_03190_002_20190127T233046_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.28/ECOSTRESS_L3_ET_PT-JPL_03191_002_20190128T010658_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.28/ECOSTRESS_L3_ET_PT-JPL_03191_003_20190128T010750_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.29/ECOSTRESS_L3_ET_PT-JPL_03206_003_20190129T001523_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.29/ECOSTRESS_L3_ET_PT-JPL_03206_004_20190129T001615_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.29/ECOSTRESS_L3_ET_PT-JPL_03206_005_20190129T001707_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.29/ECOSTRESS_L3_ET_PT-JPL_03206_006_20190129T001759_0601_01.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.29/ECOSTRESS_L3_ET_PT-JPL_03221_002_20190129T232346_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.29/ECOSTRESS_L3_ET_PT-JPL_03221_003_20190129T232438_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.29/ECOSTRESS_L3_ET_PT-JPL_03221_004_20190129T232530_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.29/ECOSTRESS_L3_ET_PT-JPL_03221_005_20190129T232622_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.31/ECOSTRESS_L3_ET_PT-JPL_03252_005_20190131T231953_0601_02.h5
https://e4ftl01.cr.usgs.gov//ECOB/ECOSTRESS/ECO3ETPTJPL.001/2019.01.31/ECOSTRESS_L3_ET_PT-JPL_03252_006_20190131T232045_0601_02.h5
EDSCEOF