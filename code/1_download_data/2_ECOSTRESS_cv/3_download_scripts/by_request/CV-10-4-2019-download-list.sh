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
    echo "https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/53df3234-2bd4-421f-9c45-b78f4d0b2640/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019289235304_aid0001.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/53df3234-2bd4-421f-9c45-b78f4d0b2640/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019289235304_aid0001.tif -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/53df3234-2bd4-421f-9c45-b78f4d0b2640/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019289235304_aid0001.tif | tail -1)
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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/53df3234-2bd4-421f-9c45-b78f4d0b2640/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019289235304_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/6884d7cf-56f4-45eb-872e-50de565daf74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019289235356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c36a0cba-caf4-4b02-ac46-804351ac2c56/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019289235448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/04c8f283-de7e-4afc-bd4d-877c3b52ca91/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019290163442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/1197f5de-165c-44a7-9b49-faa167d69c22/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019290230400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/d95c1048-e830-4440-bde5-942d20f4dac4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019290230452_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/ee5e38ee-c24d-40b9-a8cc-7beb77633417/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019291154604_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/970cedb6-2cd3-4b73-ab8b-1ad961f8ea17/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019293154543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/666fd72e-f9c2-4b5f-80fc-1dc87fe48c70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019294145708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/09c98f8c-3b9d-48ee-abaa-430c41b77c27/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019294212719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/64206ed9-00a3-4ee9-b1f3-637cc1ebe26e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019301190107_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f756fae3-2620-4dc3-b76d-f789b47bdf69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019301190159_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/a525d379-794a-4a56-9bef-9ed185b4a99e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019305172233_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/34e4e20f-f25b-4ec6-a64e-cd8f84939120/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019305172325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/655739f1-ed4d-455e-905a-b5817b097365/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019309154439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7ff8fe5b-4601-47bd-ae0b-2f5b0fcd2e53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019309154531_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/4187aa70-2a76-46c0-9d93-9028d6209e05/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019309154623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/270f9498-3db3-46bf-af14-9d479f41769b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019330002148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/faa1eb4f-f064-4701-a4e2-1c5da6719a41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019332002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e331f442-3e03-455f-85e6-1800317a07b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019333224453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e56134e8-ee6a-45dd-a43d-a51ebbdb2a45/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019336215612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/925da6b1-614a-4c6a-a361-97c0a263cc9a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019340201909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/adbb4f39-284a-4a12-83f2-563c8d32e097/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019343193029_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f49748c8-fc95-43f4-9191-464cbc6ce516/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019344184205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/a2a5649b-a705-45bc-868b-d25718bf160b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019350233514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8a9a9ece-f313-4404-b0e5-66d25c9ad730/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019350233606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/4e1673fb-6944-43dc-bd56-5656e479040a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019352152728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/85e10d91-ebe7-46a8-9ff3-3d477350a4af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019365175734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5086057f-58d7-49eb-8060-e0bd9a3a4aaa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019365175826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/79a67c1c-a01c-4d6a-bcce-bb4b8cfe1c78/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020005153413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/df16dbf8-6ffb-482c-baf7-a6982ef422d5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020005153505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/3d4cb634-44d6-40de-9c2a-2f82fbfd48cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020025010824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c5cbe9aa-0ac2-4180-a315-1706bfdfd341/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020026002103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/86b34352-ff86-41d1-a696-181b56c38c3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020028233509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/9ef5de71-a0c5-4614-9af6-c5defd8f000d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020029224753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/15ebc465-6ced-4a06-8d64-d4b8fdb27cfd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020031225003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/fe8b0c43-dfe1-4dc3-b6db-57f77c7f12e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020036202830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5efd61ec-fc07-443e-a582-d7efb9ddf37b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020037194050_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/dc66c967-97d9-4050-9308-e84e6b02297b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020043180910_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c7ff937a-bea7-4be9-a390-017846454750/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020044003909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/ad4c8e32-46a6-4d8c-aa27-f0c7fdf73e81/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020044004053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/bdbccd14-9948-4d1a-b43d-68f7a2314e45/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020044172119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/23b633e0-cc42-4fd0-a680-591de78a8246/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020045163344_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/12a6be00-edb5-43fe-93da-f14059806f3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020052204509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/98526ee0-e390-4cee-9e77-ad69a947e58c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020056191129_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/48fa15a7-de60-46aa-807a-729012397407/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020084014449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5e11d973-c232-4c7e-b400-1005b1f303da/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020084014541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/4a1b855d-d789-4ba9-adc6-f344e7da658b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020085005731_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f5fd12bf-a920-493e-b907-316fcbb7fab0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020087005951_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/75ecbdfb-22d1-4905-aae5-f3ee391fc839/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020088001215_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8cc20d54-a428-4577-b521-13217d18598a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020088232451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/571efa20-b0ee-4bdc-a9e0-0b5d46fbbc87/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020091223937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/9e4f606b-c957-43b5-9884-15e8369eaedb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020092215211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/98beb5c4-1aef-4fe3-90d8-14eda68cf941/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020094215451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/110c7d5f-a74a-45a9-b0b2-01562f61792e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020095210733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/bd05ff80-12fc-4e49-b543-65b64e79b8e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020096202021_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/01bb76a0-c9db-4546-a9af-6e27acdbea1c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020098202311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7060a1a2-bafc-4bdb-b00e-68412962de21/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020099193553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/66ae0e65-37df-42ca-8ebc-bb5abaaf9bd1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020100184830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/ffbc41b8-3b45-443d-88dd-70ccea60ffe4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020102185116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/3e61a426-dfb3-44c7-9f21-a4e202e79b35/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020103012226_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/336d23d7-e3ce-4686-8757-e5eb4de40576/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020103180354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/fa8d3f68-aeb8-43c9-9765-5df60b778f4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019289235304_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/89836b4d-7d61-45d3-a0a9-41d38f03606f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019289235356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/724b2dd0-c803-420e-8f00-e69d59e8fe3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019289235448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/b8036702-25f5-48db-bc4d-69b79e4a820e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019290163442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/b1ec43ac-b382-47cd-b70c-e681fa52dbee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019290230400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/d501c7ce-4d9e-477c-8d3c-e7cb2d4e9e56/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019290230452_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e0889739-2788-48c0-8d97-f56b561156c0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019291154604_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/788d348d-d996-4c32-9475-3d2895b1ebfa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019293154543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/bf209258-1652-40b8-b4c8-d08da881811f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019294145708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f7bb1362-2acd-480b-81d4-7620c889ec89/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019294212719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e86a53a2-7184-4df9-a1d3-3dc2f460eacb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019301190107_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/3ead0c9d-c2e1-4dd9-8802-57ec32770dee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019301190159_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c7acd9b1-55fc-40e7-99d9-c2deed8341ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019305172233_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/0e2c9c5b-8f10-4c24-99b1-19bc46008443/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019305172325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/3cf5fd6e-114a-4fd5-9bbe-9db693eaf50c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019309154439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/874dc311-89e7-40f3-821f-42de0555061c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019309154531_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/0e935806-3675-48f4-a637-193e2c9e71bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019309154623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8f10430f-fe1e-43d6-965b-562a5ee0407d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019330002148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e6d925cf-536d-4328-b80f-ccdc872c71bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019332002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/83391a77-30cd-403f-aa20-ffe4cc246400/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019333224453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8c37a956-6ed8-4a04-977b-fe39194ebcf8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019336215612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/35c740d2-56e6-4b92-89d8-c0c23769c5e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019340201909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/a9d9c083-8c52-44f0-817a-307c8bdeed28/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019343193029_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/da67450e-7c25-4e91-8c42-efd47f4490e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019344184205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/11e90a88-0755-4fb3-9d6b-4430bb330019/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019350233514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/67ad7b8c-aad6-4c1f-ad18-b5f2e6a777d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019350233606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/cd817713-a770-4683-991e-efc3a9e40b7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019352152728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/721be958-13ad-43dd-a4cf-b5eb1c99460d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019365175734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5d978ce8-1434-4303-84fa-04c548398f89/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019365175826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/eb471521-c602-42ec-a676-d2b0858ab28d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020005153413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/59a7bd7f-cc00-4ff5-b648-d8a7427e47a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020005153505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/ebf731b1-76cd-45e4-bdfe-632ea4fb42a2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020025010824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/b62e4799-0b2c-4dfd-9bda-b3968e9be37c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020026002103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5064420d-d421-409b-9276-164aa155812b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020028233509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/da4777c7-55b5-43e1-bf55-1de65aeb1031/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020029224753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/71d3ddec-5385-49a2-bbed-c357839b561c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020031225003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/49eef36d-266b-43b5-86e8-1146606a8225/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020036202830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/456b7624-1068-46ca-b060-bce4da304848/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020037194050_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/a6dbe5a6-a875-4265-8cb7-fb531d3c57d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020043180910_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f3c2611e-b9fc-489b-8706-aba81ca76afc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020044003909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/fbff04e3-1aaa-4daa-8cc5-74a808546fc0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020044004053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5a025a48-1c0e-4e8b-8e18-66c59f49dce3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020044172119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/93aabcf6-4cab-4207-96fe-f5729d06ca85/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020045163344_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/2eddfecc-1100-4a91-a323-c2084c85485c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020052204509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/4e7c9e8d-15b4-4d9f-b081-7b12b50f0296/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020056191129_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c77c6568-ee7d-4581-94f0-085ce2735fbc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020084014449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/06f92568-6a1f-4267-9691-417f158882f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020084014541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/fd2f5d2a-dad3-450b-9000-195f6f196ad5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020085005731_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e138233d-95a2-4bd5-ad54-e559142e5134/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020087005951_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/42c3176c-4e6d-4975-a13c-97d681bc6834/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020088001215_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/0d8a4b4a-d00c-4014-8d3f-bd9eac4e7b57/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020088232451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/260d032d-baa9-4aa6-bad8-a941b1d6b634/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020091223937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/d5fc1465-a6c0-4f47-bc1f-c667cefc8eef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020092215211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/cc22f6c7-04c6-4aec-b4ec-ccbd7fcaa5cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020094215451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/903d6233-c31c-4cbe-a07f-d8ff6e97bf5c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020095210733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/06ff92db-312a-4a2d-8268-2ba36a4c6d63/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020096202021_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/31ddf7ee-9ab4-4b56-94d9-52c6ace846dc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020098202311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/2c690156-d61d-4f4d-9314-7d9ea7a1c9e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020099193553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/87c9dce5-813d-4d04-b0e8-93703c2ecce2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020100184830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/903d9127-a517-4808-aa5a-aa2cac08e586/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020102185116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5c9174a4-f751-4364-b164-d42b7783a244/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020103012226_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7b9c25b1-e777-46b4-86ff-ac31e121fd4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020103180354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e0481253-8bab-4d93-b186-447fe0f8117d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019289235304_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f8546071-8377-4e46-b04e-9551368e69e7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019289235356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/eb6213a6-3e5b-45a1-a10f-be55a32cd830/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019289235448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c8381614-2cb4-4440-a10b-0bc8cd741305/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019290163442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/3c1ea5fc-d2ac-4085-87d4-629909c3bae9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019290230400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/66f4d8fa-e3a5-4fc3-8bdd-14bce745776a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019290230452_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/db0cf2cf-5232-41c2-91e9-8be5ee711ccb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019291154604_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/77d8c27b-7f84-4fca-b320-81a1083d863c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019293154543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/6e36e256-0be9-4bba-b228-f5e07def0e8a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019294145708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8642d172-575f-4453-9e28-4886edeb655a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019294212719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/9e628ffb-add6-40a8-bede-51f95940c487/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019301190107_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/09419607-e85e-4f95-887e-54eea8862350/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019301190159_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/701631f2-6ba7-4572-803a-6b2ee19f290e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019305172233_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c7d7d61a-4c88-431b-9342-ba3b27e522fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019305172325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/4607b95d-5f19-487f-9789-3980a49ea34a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019309154439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/b69a14a1-c4c7-41db-8af3-ed10d4b898fb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019309154531_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/3e261f14-e104-4b42-a678-ab163cc112eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019309154623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/d6c45aba-1cf4-42e9-a315-1875876cfeed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019330002148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/fe41d4f5-9aea-42d8-a309-0ff15b8fcd73/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019332002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f3e07829-4473-4fc8-8fb0-d7465380be02/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019333224453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/4c4eddf5-1e26-44f5-a4af-7512ca703a77/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019336215612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/6e70b54c-d2ac-4f30-b9ad-d7b429f48709/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019340201909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7593f798-89fc-409c-9779-7100976fb4c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019343193029_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/65ba77ea-4a8b-48e4-9cdd-9d00ec16e778/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019344184205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/9e7644f8-326b-4bba-9fd9-b1983a347bae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019350233514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/237e1afa-de95-4d5e-8a68-160456502be0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019350233606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/b1c36d08-0238-4e52-8443-516193fb4598/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019352152728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/0663758c-da8c-469e-8b29-451d451d1f23/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019365175734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/094de84e-1244-49ac-9f54-673cc313bdc8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019365175826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/4037d0e4-f0d4-4cc9-969b-fc45bc44f3e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020005153413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/2f96c8fd-0336-4e45-a723-87499edbd18e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020005153505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8e6d107b-6b7d-4e32-8d16-562fc6a61388/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020025010824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/326e924e-f555-471f-b91b-2e3af919b9c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020026002103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/dfedf46d-e437-4b9a-b494-7a62cdb3efd8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020028233509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/98ab5b75-c2f8-4edc-a428-992a9a572de3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020029224753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5e321ac3-7e4d-42ca-9834-c7e128430b26/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020031225003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8d962735-2713-4fda-977e-eca6497e2f3e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020036202830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/98aff871-b48b-4279-89f4-883fb35f5446/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020037194050_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/a1d8125d-f412-45d5-a64f-31bed45a2fab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020043180910_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/2d1ef616-f689-49ee-a689-3e1b39f9a9b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020044003909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e759e9e6-a562-4d0f-803e-14b1508269ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020044004053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/53dba85f-3f00-46d9-9a5e-587826c2ae41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020044172119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/279f3b45-c9f1-42aa-8676-e0a75dfc3d78/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020045163344_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/842c1644-91e9-45ba-b3e4-7da011738c5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020052204509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f5dd602d-785d-45b6-bdd3-a5b20b1f6e8a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020056191129_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/6c5a8d0c-3280-4fe9-966e-10660589b024/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020084014449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/9e01ed1c-6f4e-42ec-b07c-328dbc54fa58/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020084014541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/12da51d3-de68-41e8-9004-3a68ceb10c5e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020085005731_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e6073232-a4a2-4261-be5b-99bea41768af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020087005951_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/25e2ad7c-e32a-4f39-be78-0259b9720119/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020088001215_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/26fc954e-ca1a-4ff4-9c9a-3e78fac9f9b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020088232451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/a9afe803-5a11-4742-b500-849ea8131368/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020091223937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/a71625a1-bbb4-4eb3-9b0d-4a81fa9d7158/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020092215211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/018853d9-7bdd-4cd2-a831-e8e3505e2a1d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020094215451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f6859fd2-388b-49c3-8bf6-f6713e445a6f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020095210733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7e13bd2d-3bf8-4b2b-bdae-b3959d0dc508/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020096202021_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f36cc700-ffbd-4755-954d-c690e9e43962/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020098202311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/145bf823-1f4b-464f-9ca9-0a1e9d16afcc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020099193553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/2d0469d5-8ef2-4dcb-995b-209e3a4b12c3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020100184830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/b438568e-c1ae-4c5e-9b4d-7187327f82ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020102185116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c0ecedd3-0ecc-4076-8793-610286811d88/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020103012226_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7c7554d4-9ec0-4d4b-a9a7-02e1517da5e6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020103180354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c0cea71b-efa7-4df4-b845-48a3a4bdeae7/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019289235304_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/971e36be-3f26-4030-ac31-f87ef98606ca/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019289235356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/82fb4a88-a726-4fe0-a5d4-ec86d55351ef/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019289235448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8f3173ba-2e90-4ffb-824d-6d5c69448213/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019290163442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/394508e7-11cb-4e50-932c-ab7fbdf823df/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019290230400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/ee4c4e8d-0898-4362-88eb-b0848a2baa8f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019290230452_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c01673e1-d5fb-48b8-8ddb-aab09134f71d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019291154604_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/cfcc8b2f-5033-4a5a-9972-6ed09723d66e/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019293154543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/6aab7588-1626-4283-87c2-44cf93b0c525/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019294145708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/b6204411-45ca-4db3-9279-aeb00ee16ffd/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019294212719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/132392dc-63ac-4f34-b7a2-491935fa39b5/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019301190107_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/dc201762-19eb-4203-a3a1-db5fb1fa4320/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019301190159_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/3e00e4be-5deb-4451-b4f4-f88589547ece/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019305172233_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/c056a8e0-a654-4b75-a869-8c4a9d91e16a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019305172325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e5919784-5073-44db-87d0-be6ff83c5a28/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019309154439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/266b19cb-0e6d-4ac5-a7f5-12f035111404/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019309154531_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f7568628-e0c8-4311-b19d-b801c62e3919/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019309154623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/867ef8c0-2182-4b64-bcbb-63c5bf264c5c/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019330002148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/903ed06d-c103-4398-a956-170ba870ba40/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019332002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8ef7a476-ff19-457a-ab56-53baba8dc5bb/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019333224453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7e01517b-3c82-4d45-9cd5-e5fd59dd6728/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019336215612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/d50e61c1-dd38-4c22-a401-5531ba0d0f07/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019340201909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/23de0f20-adb4-431b-9f93-b7f198cd1770/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019343193029_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/a5f79000-81be-4bb1-9e16-1f6f2213c888/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019344184205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/63779597-b6d5-43a2-8673-952c0e4d562a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019350233514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/47488d7c-4dbe-4334-98b4-9faed448a1a0/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019350233606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8c5ab128-0dd4-465e-b6e8-89de868c2ff8/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019352152728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f8b3439c-1a7f-4ada-8813-6d56be171c39/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019365175734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/18a3205f-ecea-4a9a-b28f-d340937c2073/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019365175826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/3b1c8f39-d760-40a4-92b9-9dd72a213858/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020005153413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/40dbbfa2-c2a6-4dff-8aef-99ea53deed41/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020005153505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/2dd1653f-a48a-401a-97b7-d664372a1661/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020025010824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/5350bc4c-e790-4b43-8678-3b7f157ca957/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020026002103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/ffaf6947-f56b-443e-b835-bf11ee746fee/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020028233509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/00385a3e-a8e8-480a-af50-f1c04381e02e/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020029224753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/465f2a08-d722-48a3-9aa4-93ef1bfb520b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020031225003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/1f6890b9-1b88-4ecd-a1c0-8ae24df3f96f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020036202830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/69ac0aa4-e176-496a-9100-dcea32ee9588/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020037194050_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/fb18b470-1374-49fb-a102-15225e30a6b7/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020043180910_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/24d19c62-3838-44d1-8507-ad4ad46fb2c6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020044003909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f4bc5c03-ad8e-4eb0-aab3-b3f60645cbbe/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020044004053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/65ba55fd-bbf5-43df-b4cd-eade4aed618b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020044172119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7ce5d76f-f8c2-4398-850b-45e9abcc0a92/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020045163344_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/ef94da0e-721a-4be8-bce4-a6e0e6d3f0e1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020052204509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/045aae6f-9ee9-4e6a-b009-2ead1ba6b7b6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020056191129_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f2e101ff-1e04-44c4-adea-cc06757f899b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020084014449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/cd04b169-3cdc-4b8e-bf42-342ddc0ec373/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020084014541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/7c88e6a5-1797-4633-9092-8364164cafd3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020085005731_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/0fd49702-25ba-4ee3-8d05-229680e8e2fb/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020087005951_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/1e8f29ec-de73-49ad-bc8a-c7ee1a9c0832/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020088001215_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/1386abb5-8140-4a68-8267-c59b70333b06/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020088232451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/052acd82-13e5-47e1-a9fc-42c69a27423f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020091223937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/f7a6a616-8217-422b-8c8c-ce20bc3a27a3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020092215211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/78278251-20ad-41a3-9b0a-e40d57cbdd60/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020094215451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/55cf3a84-bef3-41bc-98f8-920e6a772ab6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020095210733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/8ff0d7ef-0be5-4a91-9572-311a5a48451b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020096202021_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/e3f65edb-800d-4013-9c6b-d965bf01c80a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020098202311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/67ef8094-2df7-4257-a1e2-e8f7c17dec17/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020099193553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/4d6ab15e-3360-441d-b9a0-93af691320a0/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020100184830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/eb54c329-7645-466f-8666-baeac0b2c208/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020102185116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/76ad0cf7-07d4-466e-80f3-480349d3e0a6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020103012226_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/12a14e02-46d1-4d07-8a4c-e6da3b7699ff/30b43bcf-c6e5-4854-94d8-6d52832f18ba/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020103180354_aid0001.tif
EDSCEOF