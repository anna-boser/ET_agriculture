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
    echo "https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/57f3cacc-d32b-4b5b-a716-99ed7db8910e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019010150436_aid0001.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/57f3cacc-d32b-4b5b-a716-99ed7db8910e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019010150436_aid0001.tif -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/57f3cacc-d32b-4b5b-a716-99ed7db8910e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019010150436_aid0001.tif | tail -1)
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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/57f3cacc-d32b-4b5b-a716-99ed7db8910e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019010150436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/ee2c06e9-b278-424b-99b9-953b3ea678fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019026011306_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/68ced4c9-0924-483a-b08a-f8e4bb1d101e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019027002130_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/065dbc56-ab01-4513-9c72-2bb4d6dfdcea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019027002222_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/1e08d659-af52-4eb1-b15d-5971a3b97bc4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019027002314_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/e6110fa1-650a-49bc-89c2-3324b90b615e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019028010658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/8ee51070-4b23-499d-8e90-a39f8f8ebe4b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019028010750_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/74ffa3b0-3a85-4d08-8d60-e398225c6433/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019029001615_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/84451e75-6ca2-450a-af81-93913ca91dcc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019029232438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/1143edd5-d508-4876-b257-dfc615ee75e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019029232530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/4967b922-74f5-4d29-978f-31fefc5592b6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019026011306_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/ab639efe-2f57-4ebd-b251-161d3e302515/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019027002130_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/6d3d7b3d-f9ef-402e-b421-874050034162/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019027002222_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/28b46443-fed2-4579-85a8-30a324d9e4a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019027002314_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/d0b0faa7-4a00-469e-9045-a44378b87249/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019028010658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/de80b158-d124-4fdc-8dab-aded726ba2d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019028010750_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/85f172a6-9366-4215-96a7-6f6dd6d58890/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019029001615_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/de57ae67-09d9-4daa-8809-98e66d469b6c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019029232438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/1fa3b1e6-d3dc-4e6b-a4bd-4505a5437389/d7cc29fd-9d96-479e-a714-46e2f0f35c2e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019029232530_aid0001.tif
EDSCEOF