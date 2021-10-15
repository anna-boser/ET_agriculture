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
    echo "https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ed3d486e-0903-484c-a961-588987968e8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019032222727_aid0001.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ed3d486e-0903-484c-a961-588987968e8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019032222727_aid0001.tif -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ed3d486e-0903-484c-a961-588987968e8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019032222727_aid0001.tif | tail -1)
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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/aaa1095a-3e97-4ef4-81a0-b6befc92d9e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020153222952_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/267dca00-c60f-458f-b643-b98e4c489ccd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020153223044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d589edf9-2fad-40b9-b56c-43a7d26ee92b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020154214240_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7c164833-8302-4f15-83a7-c2ef7c16114f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020155205452_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/161b34d7-bcea-4882-9b76-d538c5840f7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020156032359_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2f806b35-165e-4c93-aa5e-ff1ed52ca997/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020156200614_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ce1bdedb-8a93-4035-b8ec-a99947eb9669/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020156200706_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0e35aeb0-f670-4563-b976-b8839814fffe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020156214356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e76aee4d-5fbd-40c2-8870-5cf6bc50a39e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020157205516_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1d46aa7c-6536-4afc-ab05-af61bccdf35a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020157205608_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/19b6a0f1-f88b-4f6b-88ae-99f8b1f306c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020158200712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/39c58850-0784-4435-821b-2dde3e61e6d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020159191919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c8421c97-dd2a-419c-bb38-c023fe3bdd0c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020159192010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a0650882-2388-4f4c-944c-e34b1d4252af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020160014926_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/35cf63f6-3a0c-4cb3-817c-5a37b012a320/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020160183141_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5353a95a-f91d-40a8-89e3-ad60dc3d2259/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020160183233_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/3214e3c7-9a5a-4c63-961a-770fe07b1f53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020160200919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b89e7d6b-53b1-4b57-a461-5134b09f13fe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020161023856_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/fb9e9422-d254-45de-b833-17efacd4bf48/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020161023948_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ba9bba98-11a7-412d-a154-b9848185ec15/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020161024040_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/20568803-1352-462f-bac4-e2c6d1ca890a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020162015111_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7e50100a-6e1a-4328-b1ad-b86ab2fae12b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020162015203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/988202ee-2806-41df-b4aa-3d45cd2b9729/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020162015255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/594b620b-b8fa-4bb5-b426-cebd297a75d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020163010213_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2b6afb55-81f4-44f0-a30d-ebd1916c7672/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020163010305_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8c23a2ae-b91e-4f4a-ae34-de01e1d09d41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020163010357_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/41b17508-3e4b-4cc4-8477-ec725f5191f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020163174534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f7dc71b1-a7b3-47df-9a7b-bf8c8887a8ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020165010429_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/24784849-4239-4a92-a3da-1cb1fe7ff5c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020165010521_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/768666b6-cd33-43a6-87e8-ad0ec9cb0c73/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020165010613_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a0ca46c4-8338-49c4-9b54-e4f49527f2e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020165174600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/54ab21cd-0d10-49db-9415-5cf85fd168f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020166001540_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a5d3bf9d-e791-47da-8ede-3518e9d2a36e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020166001632_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/619c28af-4cf6-494a-8c63-aa02545312b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020166001724_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4eb19bd4-fc41-4ee9-ad53-a5528949298b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020166001816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7d89d94a-2824-4a23-ab92-f146c00c581e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020166165756_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c84f865f-0ad8-4efe-8a25-5bdfe1ce6254/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020166232732_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d9372402-5def-40a4-ba67-fb60792d304f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020166232824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/fd885ce2-aba3-4e73-ac82-f9e565b7a6b4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020167161002_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5aa9d1e2-442a-4c6e-a508-80b3b1c7d341/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020167161054_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4c863b0f-c76b-4214-aa32-b4684c118264/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020168152221_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a989a1bc-ba0a-4bc3-8e79-4f0630b19b8e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020168152313_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d6ea75b3-a756-48c9-9c95-7ad267a2d2d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020168170004_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2916e702-7bdf-4ef3-9a08-9608c6ea483e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020168232922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/bf80cd8f-c565-4926-8ea7-2a9bbabd4b88/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020168233014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f204a508-1250-4a4e-8f81-e8f3e0237cf7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020168233106_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/321907b0-af66-4ff9-a162-47463605104d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020169161210_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a9d7ad41-0e97-4d9d-9180-f3d291dab36c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020169224053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/fd9d735d-479e-44a4-b6d5-4a425638e8df/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020169224145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/50c90af0-8e2d-4172-9c42-3179cdd1e875/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020169224237_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/63f3f39d-01c7-4ecd-b097-fb6824a39e4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020169224329_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6c6f9fd4-4021-4ea6-8bd8-39df96a90b6a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020170152315_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d374b7c2-3f67-4227-9fd0-77afeb3ba16b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020170152407_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e5e1768a-59a3-47ec-ba51-1d740df20823/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020170215317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c0f57734-fc0a-4779-a1af-e73a082e29b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020171143523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/12edd55b-1434-4221-894e-0b4f1dbed63a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020172134740_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/930acdcb-ab3e-4500-abb7-78db81e9d8cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020172134832_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5e2fe7a6-4d96-4f5e-8453-114d600c066e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020172152428_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/083e141f-4426-41bc-ae52-1e059eed2c5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020172152520_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/36c19cf7-1872-4fa0-902c-3a467a09194f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020172215445_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a6bc9204-3163-431d-9112-67f046c79dc5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020172215537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4a794bcc-6ff0-4d42-97cc-c0874e9bca37/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020172215629_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/76fce3bf-fee2-4410-8940-64609f233a92/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020173143637_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6d270cf5-2f71-42d4-99c8-7b80acdc5859/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020173143729_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2c712650-e67b-412d-aadf-e0c3b9694085/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020173210737_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ab7aac00-1843-4c41-b250-2bab5f6427bd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020173210829_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0b1a84c4-35d1-42cc-ab89-4a2a9c20f4f8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020173210921_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e23d6e2e-a2f2-4435-a26f-bcfba88a3e47/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020174134831_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f399ffe0-9feb-492a-9f42-20bee6f81af3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020174134923_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f09f7f7e-28ac-4b84-8742-49013ef4bb76/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020174201834_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7d47deb8-f500-4bab-b90c-2ba08d6b9185/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020175130041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/261042bc-9c1e-41f8-aff5-ba23480a0d5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020175130133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/61a04af9-1248-4044-b836-c4e437df5163/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020176135041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8200ff86-4bde-4113-b86a-d8038e1aaab9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020176202003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a28fa0e9-fb0b-4d93-b9f7-acdcd3333280/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020176202055_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0256b63d-4961-4c1a-baa9-69c88a344ebf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020176202147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c20a4a15-abe8-4dc7-b569-74ab685d1583/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020177130156_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/91b85d20-cb0b-46ca-b90f-28947fd400d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020177130248_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8f2ec06d-e42d-4836-9296-4b26e8a7ac9a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020177193205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0207434d-a59e-47b1-8633-a959170185d6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020177193257_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6d744279-4f29-4918-9e97-b5b0920d3f30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020177193349_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f7f848c5-6aea-4304-b8db-431a77f766a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020177193441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b90be100-b993-452a-9f58-26261a46327a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020178184357_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9bc7ac66-1b96-47e9-b62f-c7a7014de8b8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020180184511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9713ca30-a436-47d7-9637-4d1f86b5c2ed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020180184603_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6817b3c9-b6e1-431f-ad98-61aa9ff5618f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020180184655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/80b9a8f1-7e54-4b23-b98a-94dcf0061edc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020186153423_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f23c3397-fcaf-4be1-877a-aeab80412521/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020186153515_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9e37be19-e8eb-4b9f-89c0-60c8bb1c7972/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020190140118_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/060f429a-c538-4b0e-9913-4d8d52cec282/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020192140248_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9c82e0a6-de55-4c30-a5fb-117bf43757fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020192140339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1a1a2d19-5201-4567-8b40-3b98921f0b19/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020192140431_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/110c3acf-c5d6-4508-9713-af52205af582/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020192140523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4587984d-1819-4df1-9403-ea673769fa77/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020202024702_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d62dc21a-0554-4c4b-aa0d-788202ccfbe1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020203015918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/be369142-6069-4975-89e5-99bdeab02a6b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020203020010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7cb72d7d-81f7-4c77-9ae8-59d54453b729/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020205015955_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c49bc397-de01-44c2-8efc-0197ea23c1c1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020205020047_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/032c7f9e-6d1e-4675-9854-3d81ba2add79/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020206011211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2c72c18d-8f0a-4343-84e3-4ccf8b2c0ec1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020206011303_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/070af69b-a26e-425a-8dc3-ac6c26e30b36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020207002428_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/60c53279-c2ee-47eb-a3a1-3e39298146cc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020207002520_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0d129896-c5c4-4af6-ad4f-dd0fe57c19b3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020207233655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e82ebc34-69b8-448f-9e88-0d441e2a284e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020208011413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/44d771a2-b567-40ad-83a0-b3a97dc31394/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020209002512_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c230f71d-e987-4f0e-b7c7-b2c40078de28/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020209002604_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/188022f3-ce26-4d2e-96ad-1cedd5f6af9f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020209233715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e65fa7b1-0610-44ab-a587-eafdd87dfa32/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020209233807_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4be2a2b7-a586-4eed-86e6-5b524849739c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020210224933_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/19220600-43b1-4ebb-ba9f-415626379469/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020210225025_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ec56abb0-b11d-4e41-9f55-1844ee2121b3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020211220207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d6097f07-aca3-48f4-9af2-10a0da11bd7f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020211233834_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cc939aaa-cfdd-44c5-b998-d156055a1708/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020211233926_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9dceb900-a133-4783-bf4b-a8485ed54253/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020212225053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a229b0f9-5f98-45eb-9299-ffd19edd7d1e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020212225145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/59c3f6ab-4b8a-4971-a967-04edb321434a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020213220318_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/40bb609c-4daa-4ebd-940a-7fe456f291b5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020213220410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ed212711-eec7-4b62-bb77-c88078d0a897/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020214211556_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/789ebd82-e20d-45fb-9e30-b8c68bbf5c39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020215220513_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/be0b8e95-3542-4cee-974c-4e786762e03b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020215220605_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ced8b211-3f7b-45a4-8bdb-bc1d976f3bf5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020216211724_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ba7a094a-d4fe-422e-8512-7ffb4a005eaa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020217202950_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/62957cea-a18b-4921-a61c-fb479845fd96/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020217203042_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/460fe3df-f2a0-44c9-9e2d-c18e49e26948/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020218030005_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7df47029-9ad7-4590-b689-734cbd74bbf8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020218194227_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/83b77e8f-279c-44a2-9d10-7910fd3362a3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020219203139_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5e6c6b84-8403-426e-ab00-9e4b5aa12ec7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020219203231_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7c147409-fc85-4fb0-b3c6-69d3ef7a7d68/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020220030142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/950f9e9e-c5c1-49ce-b353-bca04c6ec484/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020220194402_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/3db67a2f-435b-4009-9205-eeeba66043ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020220194454_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5eb9c2ff-320b-4dc1-b012-80216d6d77a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020221185624_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b5931a0b-2d7d-4c6e-83d9-dedb6e32e0e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020221185716_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/417daaef-2e91-4527-92a2-0da64d6781f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020222012634_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1f58891c-4e14-4ff7-b005-66fc98808717/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020222180903_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1c45fbd7-3c15-4586-a560-b5ba5a89e6f8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020223021718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/943a7367-9453-4aa0-81eb-fca71b7ea8ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020223185807_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/fa40c0f2-3a29-4aee-b983-59f4651c853b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020224012901_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cf74d989-f361-48b3-96c1-368fc6a3cc0e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020224012953_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/23132d7c-2241-4fce-9440-ce09c4f32999/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020224013045_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/559734e8-6885-497a-8f02-c597e16944b6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020224181030_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b5436804-ca78-4537-a1cb-28f437bdcbe6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020224181122_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ccf45dac-3e4a-4bdc-8c2f-9a63b8eb7a3a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020225004006_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/3e04ddac-53ad-4516-a02c-deab9bc20076/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020225004058_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/945c6da0-a935-4c15-9cde-5314623e1e15/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020225004150_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f9a848f1-2fd5-4513-bdc4-1e217375e388/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020225004242_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/879ef228-3ae8-4f98-981e-5649af23cbe0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020225172251_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/755e66e7-ca44-4de8-b37b-1b398f65462d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020225172343_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/47803e13-4a12-4d5a-9a95-f90012d6ffc7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020225235300_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/556b6d14-0348-41f7-ae4e-99fcf5655196/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020226163526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ffb19bb5-443e-4ada-8ec7-10525e907526/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020227172432_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/80156a8c-bdcb-4ac1-b2c9-b7102211972d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020227172524_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5aefc8c7-4bee-4b34-84d1-3a24c87fd75e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020227235433_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e260ec93-4385-4579-a4e1-beb513c57059/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020227235525_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f9d39fd2-4b9a-4a16-b28d-ec76ecf81e3d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020227235617_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8e6bb3fd-3654-4038-a1ac-61b80e6d2a06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020227235709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/878b6336-0b52-467b-80db-fb641196510f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020228163654_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a3bc634b-8706-4076-a63a-97cd91a4ff5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020228230630_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c3e6fd05-308a-4d73-9abe-4a49c6ea0ef3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020228230722_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/39913ff4-a45a-4bd1-86ac-87a22de1d991/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020228230813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7019263d-a55d-403a-b80f-78d92218ba74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020229155005_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/70b35b4a-c72f-4221-ba98-ec95623498d5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020230150150_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cca0ee26-841e-4330-9474-1bf889733ece/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020231155057_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d0ec05cb-20c4-4552-8ad1-b27a84d5bf8d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020231155149_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f01acb95-85c4-4c07-a959-8fba5d53c386/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020231222149_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/77123df1-a153-4435-b52f-600054876ee3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020232213255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a10fdcd0-ac89-498d-ac21-d0cfddb50a19/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020232213347_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/62e2b073-f165-4018-a359-ce9a0c443f74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020232213439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/94ede07b-f992-4f71-8f4f-43d0e964dba3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020232213530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/15b1ae9d-ccd2-495a-8275-acfc2796ee0c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020234132814_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5c8c6585-5357-484b-bdba-8320478e0ca8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020235204812_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9af3abe4-999e-4190-9b13-c9458f744ff5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020235204904_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/55fefc39-f3a1-45e4-acde-31a27c827b5e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020236132948_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c959592c-e3e2-466e-955f-cbd76ebbbf3e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020236133040_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9bea9ec9-2b69-48b9-ad97-41c45e19327a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020236195907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5461905b-c416-4eb8-809a-ad8793d7b3f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020236195959_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f5e0090e-7712-4db8-9a86-ae70bfce6573/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020236200051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b755e659-36f2-4c86-ae3a-f0b4282d8d14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020236200143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5910a0da-cd66-425e-a84a-c9516e6d64a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020237191207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0baf5523-2c70-445f-9ae4-a4f455ce784c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020238200249_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1c1c3683-7345-4107-ac80-add19015925e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020239191309_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b4cd9250-c06f-4cb0-971c-fdad845114d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020239191401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4f183de2-feec-4357-9042-0d6f6cd8d493/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020239191453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ff9c8c8e-cb2d-45e6-8d14-99ea8de082bd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020239191545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0ee466fa-0c23-4eff-8a58-94a985349562/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020239191637_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/12a7c9c4-5e76-4a8a-86b6-0606f63861bf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020240182626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1e8711c6-8243-4d49-bc3f-967f3f55e017/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020240182718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/84edc558-5a53-4aff-9c0f-d782f988886b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020240182810_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/94a54230-d81d-49fd-ba10-300f6be6bf43/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020241173826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cf917b68-b244-48e6-b906-9d3320f782b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020244165231_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a8ea5857-4249-4707-8353-54851c9c8d65/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020246165515_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/16e632b0-5015-407a-ac29-8d317ad335ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020247160610_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2d2964e9-ac0a-47bf-9189-c56b4d40482d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020247160702_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f7957480-f35d-4157-940a-6de18e4d3f4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020247160754_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/79512af1-a528-45e0-b816-a66a8879ec9a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020247160846_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cbe62137-acec-4497-9fc1-673a694569a0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020250152115_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/29026a28-81db-4839-ad5b-e85e4c38c0c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020251143222_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cda8b441-e1f5-442a-9bb1-cd0df6f78861/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020251143314_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5a51ba3e-ae4f-401f-b931-69781b5303a2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020251143406_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/bbaefc39-57e4-40a1-b476-a046f94ecc06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020252134555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ba11e80c-11cd-477b-ae63-b84ef25e8ef2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020252134647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f291f4c2-6e44-445d-90b5-da2187c289e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020265014818_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5285cfaf-0c00-4d21-a36c-2bf646b3d400/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020266010103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/eecdd21e-e5a2-4abb-b2c6-f153b7b75cd2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020268010243_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a90544ef-69b5-47ba-8217-976801c26b3a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020268010335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e0279cad-4f8e-4e5b-bd73-5468143d16d5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020269001530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/94c2662f-9966-4a9e-aea1-ec601f33e2b0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020269001622_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8f0d5399-cdd2-45b7-9466-25dc29352b16/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020269232816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/af45b545-e85c-4650-94ab-55ca343f1c8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020269232908_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ea8679f0-e95d-4530-8ad6-dff8fc736760/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020270224116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/91ef5b4b-db09-446a-8ae6-36d074887c0f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020271001814_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f341a21c-4ab1-4af0-8863-4e8069b07711/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020271001906_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d9c37d93-7b32-421b-8838-bf4022e4c29d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020271233006_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/bb504234-790e-46e0-80a9-231cc1e0cc72/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020271233150_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2d7f092d-97b7-4831-9dfe-1eddca325387/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020272224329_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/683eb6ec-6a73-4be4-836d-9985d9516d06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020272224421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0d99280f-84f2-490b-958c-20ed6375e3e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020273215616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5dbdf77c-f828-4ccb-b449-16d722e8b35b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020273215708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/077ab3dc-db1f-446c-a8c4-dd568904d0e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020274210913_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/54880517-265f-44f7-8c1f-5831da54ab5a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020274224534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6434b0f4-1428-4412-b411-e578e65f3327/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020274224626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/105e6040-6502-401a-bd18-069c8aba2153/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020153222952_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/26e0e713-6406-4e87-878b-bf40a436c1a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020153223044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/197aea82-978a-4cc5-80cf-307a154fda17/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020154214240_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/01637430-58bb-4858-b254-9a6277feb2f6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020155205452_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8dab0aa6-15b5-4104-89bc-9ff91c94787a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020156032359_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6bf6c520-af74-4cfa-be8e-a6beac0a003a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020156200614_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/19fec430-b2b4-4178-8601-79664b7a411e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020156200706_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/23cd0053-5a4c-4624-8af3-70d9d7b4a9bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020156214356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/07b0a78e-0588-4c25-8ac2-d564d061450b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020157205516_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/13fcb73e-b368-4b84-90b3-8585df4c60d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020157205608_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ba8c0df2-f18a-4e1d-bd03-6aab0b76b8bf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020158200712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d0f259df-efae-4a01-a806-91d475a8ff27/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020159191919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1a4e8081-cff7-4a07-8230-1c08dee3ad3f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020159192010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/079b9769-7e46-499f-a732-667c9c512904/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020160014926_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6e8d0268-b77f-4bd8-a5c8-a5a6d3069e4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020160183141_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f7f1883a-404f-4c91-84a6-9e991c72c291/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020160183233_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4c961f95-6688-4ebb-822d-1f9d9781ab25/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020160200919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/06b8b09f-2b00-4080-83f6-7d9011768d53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020161023856_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f2603008-2ebc-4d59-82b5-b1f8ead87ecb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020161023948_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b88274a9-5a7c-43d4-bbd3-b74c3f72970e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020161024040_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/55b89d61-8cc8-40a5-a02a-43189c10f81a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020162015111_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/91c5ae21-752d-42fe-9825-52d0141a4983/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020162015203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/adaaef4b-ac0b-4c92-9bcc-3416d561c60b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020162015255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/22fbca55-fcb7-4cbe-a150-a8db25e082e7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020163010213_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4cbd5c44-5f5b-4940-b56c-0a03f39073f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020163010305_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/01de10cc-4b6a-4815-8876-195467516af6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020163010357_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b232faf7-09eb-4931-8754-44e9baea7e4f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020163174534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/3b40e51a-48e2-4a8f-b8fd-c1672161109a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020165010429_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a112b0ab-b927-437d-b544-038675ee6501/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020165010521_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f775d10d-f784-4ce1-a4eb-33ff719f0b90/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020165010613_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/70e8ce5a-1000-4d04-9df2-4c812ec0464b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020165174600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/db068b60-38cb-4595-9791-b20b5460c2be/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020166001540_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9230ba1d-1dd5-42c4-a16a-5f0df4176e48/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020166001632_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8f1c8bb5-6114-437a-9359-0d74e7d28a81/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020166001724_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/bdd77706-884c-457f-9ff4-8fc9ef39e37b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020166001816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/918bdea1-e064-465c-a626-3d53f159b59e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020166165756_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7b41a4e0-d18b-4884-83ed-4d2f1090305d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020166232732_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/82ff50ee-646f-4bb8-95fb-04e32bfe264f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020166232824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/fbe1a49f-66c4-41f8-9526-57a1a772b094/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020167161002_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6054a06c-d0ca-4bb8-b57f-313c49c46c96/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020167161054_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0b0a2b4e-adeb-453f-a306-f3259dbb3718/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020168152221_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b6394832-1565-4e45-8beb-5216bd4f3507/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020168152313_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f45e9212-bf4f-4ab7-ba0c-215ab84d2c48/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020168170004_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/606a1e32-f712-4ab6-a87e-970a02790341/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020168232922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/81d98154-3128-45fb-b288-6adb7ef2c534/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020168233014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/304a6e24-aecc-4a26-9200-bcb239ad8ab8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020168233106_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/713b64a2-bc43-4324-914c-548e080ddbd4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020169161210_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0990ff4e-1aa8-4817-b5f6-5aeed8f9cee4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020169224053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4db237b0-d8f9-4385-8859-3a3031cf8b08/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020169224145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/df62c36a-bf97-4b40-8c6a-6cbc700e2013/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020169224237_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0adc699e-3906-4d44-92ec-46eabff98e24/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020169224329_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/41429c78-58ff-4d5c-aea4-b64c88857412/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020170152315_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9c1eaadc-5f72-449e-b0b8-caac20ac0efa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020170152407_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f4d9d937-7254-4d97-a4a0-e2602b425ab1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020170215317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ca9b799b-6bcf-4c46-b3fb-d8126588cbb2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020171143523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8e42f529-cc49-40e9-8f06-0c8454cbee6d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020172134740_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/24adea6c-5206-4853-a11d-ba91474848c3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020172134832_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c2fe545c-223d-44e8-8020-4c2854bb03f0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020172152428_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2d52d5ae-9774-432f-8806-c6dca0a9291e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020172152520_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/3ee53c59-0119-4be7-81d2-f8ccf415cac2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020172215445_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2391ce70-f342-4512-be40-0feb040ebab6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020172215537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/090622c8-ce1b-4c79-8dec-a3fddfc6584d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020172215629_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ab624cc4-8753-4ae2-8986-c3989b4188aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020173143637_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5fbf484d-f3d2-4573-8936-c2f438e0ef93/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020173143729_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/55d120ab-7db6-4c48-b199-d29e297ab55d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020173210737_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5257b502-3e45-4f38-a059-82cb1b13dbc9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020173210829_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d7555baf-9877-40a2-ab56-3c6e4e588ff4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020173210921_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/809ab7f4-fb50-48df-aacc-2219bc4ae3d5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020174134831_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7860859b-c657-41d1-8c54-b8aade772ba7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020174134923_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/698b4a97-a1c4-4243-a574-0da76879fd9b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020174201834_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8f9f957f-2da8-486c-9a58-4356f53eb20f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020175130041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/03fef0fa-1a4e-4738-894b-ae1fea8de312/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020175130133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/378c286d-e0a0-4b45-8082-ebafaeb1bab9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020176135041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/89a017ea-4281-4a9b-8c69-383daecd9763/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020176202003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/03b76e3a-aee6-462d-80d6-a021090697cc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020176202055_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e1dcc8a0-8ce1-4b80-8983-9984cb3627fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020176202147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/17fcad90-86b1-4882-a771-f220c102e012/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020177130156_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/049c2925-9846-46c7-ae09-d14dbea6622e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020177130248_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cb41cb1c-6c4d-4a3a-a142-f38dcd9d1eb1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020177193205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/65ee3c22-5c0e-4853-8798-5b387d1a7e41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020177193257_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/38702bb4-0e27-4ac2-8b72-99a07539ce70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020177193349_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1d7b0935-4cda-4228-87dd-f520c932df52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020177193441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5881f997-bbf2-456f-9e5f-c0f10de83218/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020178184357_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c29a982b-0a81-4f8b-a279-be8001dceaa3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020180184511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a3dd44e6-5072-4e71-8788-9b64aad0fe60/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020180184603_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/dd1d5f39-3d9d-45c5-b1e4-80d1c458d4aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020180184655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b8be9430-571c-4e55-8198-3bca2ac085ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020186153423_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c8bd2f58-ba65-46e6-9d27-c398425e7ebe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020186153515_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/18e489db-053f-4e54-bee7-d6024933d890/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020190140118_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/eed4c244-2c75-4749-9e02-ba4bae2679fe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020192140248_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f3a95cf3-8eb3-41c4-bd8a-edb3fab47410/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020192140339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/34432c81-2fed-4a48-af02-e966fc32fe34/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020192140431_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a5ae3294-bc90-4361-9643-9f0ce4a03464/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020192140523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/63a2f4da-0835-421a-b522-32d548ce6746/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020202024702_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d9fa80b6-5526-4d4a-bc39-50271a9b6bf7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020203015918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f7eaefb5-cb43-479d-a443-317e4df1b64a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020203020010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d5575ba5-03fb-4e4e-9103-00118f86f871/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020205015955_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/eb0b8d56-c8f7-4efe-a364-f8e282c2de41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020205020047_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/bbb4b193-d6e3-4c32-8449-719c9316384e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020206011211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/457eed5a-9b0f-4ab8-9259-ed228b5afc34/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020206011303_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7afa4b7b-4f74-42bc-a41d-5ba3c184c38a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020207002428_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0a875f18-eb78-476d-ac0d-e0c67586f01c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020207002520_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/44d4bcca-aef3-45f1-8a7b-59d6f82bfb96/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020207233655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4888b8bd-cc67-41da-bd5f-e4c5ef5181b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020208011413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5e55180a-84a7-4d2f-8605-5b0476b01ac8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020209002512_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5588dd22-d277-4048-9905-d58173e792e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020209002604_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/3a8f3568-ea76-420b-8342-f7c07286604d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020209233715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a4f4988e-4911-41f5-bb08-3f31c96d6ee9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020209233807_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/37d65a4e-0778-4aef-a4d4-a659aa44ae6b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020210224933_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/3a044193-0cfa-4076-a5ea-a69ef2ef6e9d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020210225025_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5b06b3de-2b27-438a-aaa5-8580bffa9028/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020211220207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/97294aed-9383-4954-9c2f-2f9b964df7c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020211233834_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9ec96fa2-5f00-49d0-b235-746cf3bd6cbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020211233926_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6f0f2008-469e-45c5-89e4-96c71988472e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020212225053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cb3c4c92-c869-4d16-bca1-dc2cd296d07d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020212225145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f992cc01-a9e1-4868-9e40-e2caf3c6a140/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020213220318_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/2cc01825-c960-49d9-9e15-1c9a255f4e82/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020213220410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9a5c8112-646d-449e-9494-925b0d02ed0a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020214211556_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7921b29e-7500-47e3-8962-7ad27730f93a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020215220513_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8d176608-2a70-4faa-948d-98389c9472df/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020215220605_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e51f91ab-bf57-41a5-bc63-675b0bc0bad3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020216211724_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7b242720-e209-4991-908f-d323e2e7681c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020217202950_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4dce3e0e-2049-4faf-ab74-66a81dc2bd7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020217203042_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/24d292fc-749f-4f24-a1c9-c50b05b4b97a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020218030005_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4ad2566a-317a-4b0b-badc-a79467d18e9f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020218194227_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/dfdbd637-1a21-46fd-858f-e425b1a14cb4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020219203139_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/35fd2e44-90cd-4743-9062-6e2f7cd16949/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020219203231_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a92d7f50-e60e-4b25-a0a1-eb84b6760854/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020220030142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d67a0eae-50d0-461c-b789-b15d19e78f7f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020220194402_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/00385bcd-cc52-4e7f-8456-352e88c16572/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020220194454_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/07422ef7-d2fc-4cb5-8ed5-ed9049d0247d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020221185624_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a9e45411-32e6-42f6-990c-4a44357b7e3a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020221185716_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/88761b85-e282-4ab1-9b4d-85c72e00b109/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020222012634_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/be771ffc-5237-495e-aa10-4ac282f989ed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020222180903_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b59fc23b-2460-4877-8f41-bbe06c552d74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020223021718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8fce1102-3e0e-4c92-95c6-5cb9e5ed1357/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020223185807_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/cf0b1906-63c9-49e3-ac8b-27f5ebb5f24f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020224012901_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/076f81df-ef11-4650-8e19-6ff546bd568d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020224012953_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/75a4f02a-9bc0-46b2-9e45-561c3e9d238c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020224013045_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4f54cd12-6b0e-4b4d-a541-ec63faa55b5a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020224181030_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/527e2724-7d6b-4e18-84a0-02bd449ceed2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020224181122_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d34c3191-9da9-454e-a6c2-b423c8df3851/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020225004006_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9649c322-c5df-4c32-a8fe-2578d9b1c1af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020225004058_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/59dc9555-9d96-4b48-94ef-54deec390649/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020225004150_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/65f6c4ce-351e-43af-b826-4466b6046c0c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020225004242_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ebfba795-1f8f-4bc9-9542-d60ca85469ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020225172251_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8d775a65-bd5c-4612-9044-a3ef58a239aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020225172343_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/234458c4-40a7-475d-8aa8-b85453324ce2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020225235300_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/05d845c5-3dab-45f5-bdf6-d8e7dc0133f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020226163526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/dacd6839-507b-4a63-91da-f9d3172aa5c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020227172432_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/201982fe-dae3-4132-89d0-a317fd9e3bde/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020227172524_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/822e5262-4ada-429b-ae87-2e7f8aecd123/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020227235433_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/86c503d5-00f7-4814-87b3-1227a43a8f02/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020227235525_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9170fcef-bd4a-4645-adda-55003151d7b5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020227235617_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/44649e32-ddfd-4e71-8464-55142e3bc6d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020227235709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5ed45073-70cf-44f3-8930-701b38e20940/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020228163654_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b6864544-ed4b-49f6-bb20-b40102fe6e45/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020228230630_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9583a6f8-9031-433c-bbda-61292e4af411/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020228230722_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6877f7dd-32c1-4161-aae6-bf9bb5820e88/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020228230813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6bdff581-4c66-454d-9d79-eed746a6d2af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020229155005_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/82de5a78-34b0-4163-800d-ab29746032da/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020230150150_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b12e0f8e-0bfd-4a35-978a-146f23efb81c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020231155057_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/05df9595-0ba2-4843-a72c-b146e9d83bc7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020231155149_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1fa40324-770c-4d37-b466-e3c621eff5a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020231222149_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4f2ac0ae-631b-4257-853b-011c7e544e4b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020232213255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/54aa0789-44c2-432c-aed1-78b178897286/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020232213347_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1c18c598-e260-469e-aa84-c12ac9725680/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020232213439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a7488a4b-681f-4e8e-ad69-8a09e08a4fae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020232213530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/ae5308f2-c75c-46f7-a8ca-096cb8c4db1e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020234132814_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4fd02078-ace5-4dd1-9beb-5c5fc53e3cdf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020235204812_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e1205cdd-48e7-4076-ad39-f5ca30ec7847/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020235204904_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b1755186-3e74-4f50-833e-165a6efec577/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020236132948_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5698b8de-22e6-417c-aa59-283bd3cc0c0f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020236133040_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/54bdb579-4ced-4756-8f0f-dd50a2753120/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020236195907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/56a05d91-d236-4880-97a5-2c63463a7f44/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020236195959_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/7f2a30b1-b332-4c05-9ed1-4f3a8710fc60/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020236200051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6e3e2124-92a6-4e45-9077-706c80e4f068/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020236200143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b072386d-112a-4673-8d01-85aa8509baef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020237191207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8ee2862f-1c67-4ac1-8149-99c6b9f22309/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020238200249_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f71827c2-c740-4cfb-a8c7-50644ff6987b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020239191309_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6840c1d6-d9f9-45c7-b156-61dcf5c15fa4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020239191401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/75031edc-0f73-4ff7-831d-f555bb1d9bd1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020239191453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/be6a32b6-0444-4158-a9d4-96c3fc0d3006/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020239191545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/19273b10-7c9e-4bc7-a12d-e6577decb892/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020239191637_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/55377fc3-39be-462f-99ce-5fddd4560376/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020240182626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6e79a49c-6140-4c12-93c6-fff6e23bd5c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020240182718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/387c212e-160e-44a9-984e-d26272f0627a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020240182810_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e01d8e0c-3700-427b-8b0e-ec794acff512/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020241173826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a607a3ce-bc3a-4d3b-8f6a-585451f0d403/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020244165231_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9e149dd0-5ae7-453b-b435-5a888bc355bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020246165515_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/786a99ef-9b46-48a1-8c49-34588a7b8779/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020247160610_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6890fd01-9332-4f1a-9ff9-40ba60adb836/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020247160702_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/72daf656-8215-4a72-b62c-75c33d36c7f6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020247160754_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/41de8b6e-f66b-4abd-bc72-0186d4288146/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020247160846_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/52caa0d6-241a-4f57-b28f-2d3feed1746f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020250152115_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/de1de8e1-6706-4a7a-ba50-eaa83309a6f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020251143222_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/b951e293-647f-43bf-b5af-ee86526280bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020251143314_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/c72339e2-052b-46d5-a8da-ab7661f65ba3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020251143406_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f0ca5107-13ee-486e-a7c7-4aa45263bf0e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020252134555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/775c5e9e-5d2d-4848-8f00-f1d2f494c7fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020252134647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1981905f-00f1-4972-bfc0-03f2203e11e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020265014818_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/401b1776-5750-43a1-9bac-91c4c159449f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020266010103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/41451383-7535-42c3-9ba3-fc7ae3c188ca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020268010243_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5e8be6d7-8c65-40b3-a15b-59f5822d04f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020268010335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/5b20cd05-b806-405b-9be2-4df3f93efce2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020269001530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/f728ced7-b3a2-4a13-b1d5-e041dd25c015/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020269001622_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/8f3c13fd-2a37-4641-ad97-467f64cdafde/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020269232816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0a257a18-2526-47b7-b5ad-dc24da40b888/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020269232908_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/6ccb8ed3-3e83-44ff-9434-e760d2583538/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020270224116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/0ed25b82-0de6-47e7-95ed-99b8f4e4ca28/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020271001814_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/a303247c-1da1-4c9b-8ff1-0851ae9e09f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020271001906_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/936c56b4-3861-47ca-ad99-a7935791fd79/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020271233006_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/9ff6b51a-95f5-4630-8b30-353c1e67f3c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020271233150_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/026ed41e-c61e-452d-b6fe-08c9cc045db1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020272224329_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/981480d4-baf6-416c-84d9-fafeeb783411/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020272224421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/d8ba22e9-b84f-4bb7-bc49-f04127ac9289/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020273215616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/bbfbd774-1b2e-440f-b159-5b9ca1247a12/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020273215708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/e68c9714-c250-4be0-9e6d-0377ae438073/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020274210913_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/4695b3ff-a77f-421e-8546-faf1b1bd6a47/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020274224534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/5b0cc7cd-945f-4e68-9974-b46e33515dbb/1d465e1b-bd1b-469b-836f-4614e87f13ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020274224626_aid0001.tif
EDSCEOF