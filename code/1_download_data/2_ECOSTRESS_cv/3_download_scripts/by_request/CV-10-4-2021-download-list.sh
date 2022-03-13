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
    echo "https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fc65a994-5320-43ba-abad-a3714eaa9759/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021289155108_aid0001.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fc65a994-5320-43ba-abad-a3714eaa9759/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021289155108_aid0001.tif -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fc65a994-5320-43ba-abad-a3714eaa9759/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021289155108_aid0001.tif | tail -1)
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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fc65a994-5320-43ba-abad-a3714eaa9759/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021289155108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/14ed275a-6d42-4922-b3a4-c67d33910a4e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021289155200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/f8687248-f755-44f2-9717-28020bc12f97/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021289222133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/419b06d7-9a61-468e-9313-72d2eb17b814/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021289222225_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/196703a5-8654-4ae5-a7e2-602db6dea8b3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021289222317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2f5ebc05-7e4c-406d-a9d4-45a75dfb6486/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021290150348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/bd266180-7fe4-4777-8b9e-04e9c33d3ba2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021290150440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/82e69b6d-6e7e-4c2b-8114-3138de9591c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021292213655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/3fd545f7-9f40-40a7-9603-85135e68c43a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021292213747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/438c00b2-a0c0-4d17-af38-ab140d4fbd19/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021292213839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fcf7b370-917b-4395-8b2e-19e7d39b50bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021293205048_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/55e61ef8-76a9-4abe-8e57-27aad6d6e04e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021296200539_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/ce4916d0-17a7-4a53-a4f8-e5270721422b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021296200631_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/0b4e81c5-9216-4c0e-9c53-e67b76565bbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021298183017_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/5a5c149e-d92e-4095-8142-84499c19d4cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021300183327_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/013bd23e-cc61-4859-9f89-3257a8070f39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021300183419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c3c79091-7348-4e4b-a9f4-1263671036e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021301174532_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/7ccfbf74-3527-4c34-9e95-454dbbe318ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021301174624_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/55b90ef2-a259-45b4-a6e7-8f4a0a06e995/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021301174716_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/47c1278b-338a-43ac-ac60-14037b4d08a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021302165804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/4f177ac9-27b5-40a6-a0ad-b2cc4ba5fed7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021304170113_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/cef0bd41-bf6c-483d-b833-176cb29dda2b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021304170205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/ed1a6cd2-00e3-40e3-a099-7c4b9d0afb18/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021305161406_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/168e9610-5c0c-483d-a2e4-06f13b90f9d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021308152815_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2bb77696-7527-4d4a-b467-aa3898e36e36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021308152907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/96fb155c-cd96-4368-95fb-88db36895510/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021309144122_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/a55d1025-245c-4faa-a752-4c9b0fe88701/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021309144214_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/6c6c22f4-4caa-4569-bc7a-f9e79b6e9cd5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021332225915_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2cfec64a-7121-48d9-8954-eeb94785e4d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021333221206_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/b850fc77-a047-4c31-8193-4f3e0826321a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021334212434_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/7e108eb8-b859-4261-b00f-c16b110e695f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021334212526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/7d2ed97a-2236-4e0f-a787-fefa0a6746ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021336212714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/7ece551d-d9f8-4ad2-aebd-719e6be835a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021338195235_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c7931b3c-5b2b-4ccc-889d-2e5d2bffcfea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021345173410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/e3511baa-f2ed-4016-ada4-5d0e99b981f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021348232026_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/6cbc5ef8-0cc7-4a65-bf54-500c2b7f7033/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021360183925_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/ec471a5a-4252-43dc-aa9a-dd5ee704faf5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022003152706_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d8778498-5d46-4635-86e9-bccf161e1807/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022003152758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/19046f76-c3af-429f-89d0-590f424d1279/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022035192301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/310f0df2-9e50-43c7-9b6a-a0f66db7d88e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022035192353_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c65f4b01-0ea6-4a43-ab06-0929577f8d5e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022038183541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/8f0e37c9-c5d9-49e9-b116-21e0c6e3893a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022039010552_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/5c036b87-e326-41c6-8a0e-9b2e2168302b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022039174724_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/263f63fd-b901-45b6-96c6-f6ed49f17887/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022042170051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d5eac814-e97f-4356-9ee5-256c0a6ec361/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022043161218_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d7368d57-b61d-4e98-8ba4-c74309c445dd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022045224401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/90c2fe75-8975-4df8-b11c-10d758217734/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022046215416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c19efe99-ba50-4b8a-a15a-671772eafd23/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022049210656_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/5030d0b4-9fab-4325-8ffa-5d9fe0a30df7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022049210748_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/293ae5f9-34a5-4999-94e3-e18063db6e40/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022050201805_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/78bb9a1e-f6e3-4544-aa0d-d79761db877a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022056184305_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/a50edf06-c161-422e-b263-96a76918ae14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2022057175457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2e81ca5e-9389-4408-af1d-6ba6d98f4410/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021289155108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d5bf50a1-7f6a-4d88-9057-3a5a8cb3c02c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021289155200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/3a37dee1-2d14-4fc2-aa2f-df363779faa8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021289222133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/f86b6891-c2cc-4627-afac-b86188f3c311/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021289222225_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/32ceb0cb-87ef-4c77-a060-228ea5727821/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021289222317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/102d9a72-ebc4-4d86-ab2a-eb0efbb536a0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021290150348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/54bc6cd2-d474-4b55-808b-1e482333ba36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021290150440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/23e69070-aa99-49ae-8775-6cf066ce2c1e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021292213655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/e70737e1-1750-4d1a-8137-05b1ba02ed3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021292213747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/959f8872-efcf-43f8-9edd-84878987c758/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021292213839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fc5d60ba-0846-48cc-aa3c-95a162508e11/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021293205048_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/3a9ad2cc-a395-44e5-a2fe-183e77ef89ae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021296200539_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/acd7a707-a138-4ff4-81da-ffaf5da0addc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021296200631_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/dc1142c6-d505-4ea3-ab65-4f40ba97d24f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021298183017_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/6ea7869c-1519-4ed2-a927-64ac3f970cfd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021300183327_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/3be019c1-8193-476e-9aef-b72399bb8315/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021300183419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/e528b6bd-e2a7-439c-8974-ba0f1eab0cbf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021301174532_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/6be6d71f-32d6-4a49-8968-670ee410c0e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021301174624_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/e662070e-0266-42c5-adc2-741975c4ff53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021301174716_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/34b4010d-a703-4b2d-818a-6f68f4ee7d16/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021302165804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/19341a62-67f5-494c-862d-2adadf0456f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021304170113_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c98f76e9-6e70-4815-bb7f-2b5cad10f394/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021304170205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/e519a82f-39f5-416c-b14f-b485665efe35/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021305161406_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/708096e9-3764-41e0-8085-9364c84ba992/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021308152815_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/810d3f6d-2c41-427b-b03d-10cf235542e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021308152907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/437b2123-3b91-462e-87c1-7216c0dc6cf3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021309144122_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d235766c-590d-44e2-a33c-31bfb9204984/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021309144214_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2bb0d14f-2a30-4e48-a9c0-d5489f6e11a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021332225915_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/38d28e61-01a4-4f8d-aa86-19e4472fbe07/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021333221206_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/ec0d4375-ca5d-4197-a41a-c1342d6b4eed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021334212434_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/aaffc38e-acb6-479f-8e7e-6940a082698e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021334212526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/1f92ab27-a522-45bf-8e4e-e88e0e67659e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021336212714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/76549b0b-f7c4-44ab-b09c-cd8197f11b13/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021338195235_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/e748c4b2-5c89-4e83-9286-895a8e9e0bae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021345173410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/b07de849-0f21-436a-92ba-2bb9d519af4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021348232026_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c75feb02-18a9-408c-bf5e-eb664e892bc0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021360183925_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/8e2c36b8-4123-4b33-86d4-a7e6eea5f52f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022003152706_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/605d6c65-7a0a-4914-b82d-a9d87ac526bf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022003152758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/955e0435-d206-4d58-8775-46b3662208d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022035192301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c91f59ca-fdaa-45a1-9593-80f8b3630471/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022035192353_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/95f856e8-3116-4f3e-891d-a2512159a8d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022038183541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/bc951e8d-b22d-4f83-9064-56576c2ff73b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022039010552_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/45e141fa-5385-4b63-a529-b60e6f1f570a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022039174724_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/1df08c65-1204-4144-8f90-fd1afbed599c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022042170051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/93568b33-c994-4412-9766-04f5fc872787/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022043161218_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/b42bf4a2-4a50-4584-8c89-0c48af61f54e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022045224401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/036e7db6-cc99-4f7b-9e67-5aa66deec118/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022046215416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/64870d16-7746-49f9-b4b6-d06de317a25c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022049210656_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/69bfbf30-6a45-43d9-8235-4a4bd2bb30a9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022049210748_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/afea027b-c095-4651-ae2d-f8ef0e585eb9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022050201805_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/34d1a67e-490c-43e4-8604-9e711229929d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022056184305_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/11450c7b-1ae3-4a3e-aac7-24a7d093c527/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2022057175457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/9af21571-8db9-4599-ad1f-fcaa35968dbb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021289155108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/293c79fa-ead2-465c-befa-1106681289a2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021289155200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/8b17b26b-2836-4603-9596-dd2dd55476e7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021289222133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/b2649034-3876-444d-a637-26c65abc24d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021289222225_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/47119727-2635-448a-a955-644581e0c276/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021289222317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/f70d8d09-0ffc-4977-9477-b26494843b66/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021290150348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d94ee592-2643-4973-a78a-5dcb4f987dc3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021290150440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/299f10b4-e349-4902-a82e-ed2bf3f669eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021292213655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/b8a9639a-2789-4537-a5e1-e58465cab3b5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021292213747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c32b496d-fcca-4919-9f67-32d934178ab5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021292213839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/8cc3cc5e-c8b6-4be0-83ec-d720da3593fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021293205048_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/59d0baca-1b1e-4938-b5b7-8577ede04627/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021296200539_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2400a9c0-0537-4ec2-a5e3-a54de79b908c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021296200631_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/ad736d05-d71f-4798-ab76-9443d2a6126a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021298183017_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2a6dfe7b-d3c3-4794-85a9-782efb868727/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021300183327_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/19645214-2e05-4088-abed-a70d47c6bce5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021300183419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d99fd6e1-6ec0-493b-a3e6-5d685a02e98c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021301174532_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/3f352573-5370-4f55-88e6-d3913a25cd2d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021301174624_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2e21b199-40d2-4937-aee0-fb016873d6ab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021301174716_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/8d1cb807-c561-4315-a883-137b6c9a0c31/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021302165804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2d3b7fbd-3f72-4faa-bf6e-ab620c3ded82/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021304170113_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/9ff63fd5-0b71-4238-8962-f0de0c72db96/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021304170205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/1aa894c3-2166-4829-afbc-2e37a4d22ba6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021305161406_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fa4727d0-4444-445b-87dc-4e0cfdaf1fd9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021308152815_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/7fa30a81-0d18-4843-8628-ea87bf4be86b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021308152907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/02704bff-ce14-4056-aee6-b178b760665a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021309144122_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/0bbcc363-c294-4ca9-a007-1ccbcd19f9c3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021309144214_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/91c099f7-d2ac-4df1-b7ac-6a942e73241d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021332225915_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d41f8aef-c9d8-44eb-af70-f1dad2bfc4e2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021333221206_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/a1f7bffd-5b28-43b6-aa10-a48cafb68ac2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021334212434_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/b9891030-5f56-4ea9-847b-dd8f17795c1b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021334212526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/dbc24ccb-6408-4e47-a1d4-e4b457046ba4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021336212714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/0328f619-606e-48f0-b246-934596468c97/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021338195235_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/4bda3b4b-1792-40c9-937c-2927e7287219/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021345173410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2b8f1fba-2946-42e9-ace9-1f7b67caab46/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021348232026_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/30ec7432-ab94-4f88-b110-ef49eba59f34/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021360183925_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c5904990-c2bf-4cd9-86a3-4bcdfbdf0e09/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022003152706_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/dcb60a99-0acc-40c3-a703-6a1d83e94364/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022003152758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/94419573-1391-44ef-823d-f4db7ccdc0d6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022035192301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/920d0db0-730c-4f8c-996b-b841cd60a0a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022035192353_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c455692e-28c1-46aa-9449-6af2fedd56e6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022038183541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c55b0a6d-5371-4978-9f5e-374f39167954/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022039010552_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/667f95d9-13d2-421e-ae4c-8c302d2900c1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022039174724_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/63c7865a-014e-4b53-ad9f-1012c86a9bef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022042170051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2d88777e-635a-4cdd-8867-1b2adf0be68f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022043161218_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/868f19f2-eff2-41d7-aee9-93f1dd26c631/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022045224401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/23bc7284-b902-4609-8a43-65caa25ab132/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022046215416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/31798233-88b4-4c0e-bda2-86403d8c21e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022049210656_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/6fb426ab-3ccd-48d4-b322-e38a93000b68/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022049210748_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2a7f9f52-751a-488d-90d4-bae3bb0af5e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022050201805_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c4aa2a51-1b94-48d0-b0e3-aab2b4a6430c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022056184305_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/e04f9963-8130-4aa1-b05d-e1bb52e32476/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2022057175457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/dfe31409-0284-499b-9213-293194e9422f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021289155108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/df4bd929-f96c-4adc-bc38-1738278a9aee/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021289155200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c2fe2e98-e89f-4d74-943c-5dc20557cf96/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021289222133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2132f429-3de4-404e-9873-c69ec56b8baa/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021289222225_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/56e47a52-3263-4536-8296-a7cd4313c3b1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021289222317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/94c1bd55-54c3-417b-9bf0-0b002c89febe/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021290150348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/6f508082-5ac0-4b0c-aa3f-b3927a590f23/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021290150440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/80e67dff-531b-4de8-b8af-154cf0700bc3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021292213655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/4597bd68-3603-488c-be9f-a00e2f682e7b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021292213747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/3449c3c2-c523-447f-9b55-c65b8bb305d9/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021292213839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/4da27687-d297-4caa-9c9f-9544fa50393e/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021293205048_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2755c65c-e699-48a5-a1e9-3d7f805a8f1a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021296200539_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fb63bb82-dbb6-4929-8d96-030552365a78/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021296200631_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/81de6a73-8b83-4c37-b598-3fcffd61a8a9/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021298183017_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/830c35ae-eceb-4851-938e-eafb441c9a2c/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021300183327_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/475b30e8-43a9-4f78-a1ec-1448bc48745f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021300183419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/5f30fdaf-52c4-479a-8c01-330fce9ffe48/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021301174532_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/3177ace8-6309-4880-8dba-a6b86ec4d90f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021301174624_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/2c3a4c3e-3ae5-4109-a2ce-5c4088225a53/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021301174716_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/1423edbc-b08a-416b-8891-311d2b3d8fe1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021302165804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/9b989455-2b19-4245-bae9-23edee3c37f9/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021304170113_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/15aa0318-2d14-4aef-addb-0b14ac56d58b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021304170205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/7316cbcd-391e-4dcd-8c8a-6d51117fc410/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021305161406_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/0a407f9a-b7d3-462c-9476-65333c349d57/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021308152815_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/69f09606-dbbd-47d9-a408-4b3626c06079/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021308152907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/9d6b9193-2610-4491-bb70-d1dd6e69a683/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021309144122_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/13ac8a5a-918c-4afa-9c51-944defa80ca6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021309144214_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c509c377-4331-48f9-b8f0-31c99130de8b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021332225915_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/12bcc457-37a3-402c-83ea-613cf6d4b6aa/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021333221206_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/30674d48-c2d4-433e-bb06-f31dd51a82c6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021334212434_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/f722f86c-713d-4919-aef1-424373075e30/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021334212526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/4acf14d1-83bb-4cb2-b536-049c433ba165/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021336212714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/408698b9-7bc5-4dd1-b73d-78dd064b779e/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021338195235_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/9c5c9b59-01a7-4706-8799-75bf2592fbcf/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021345173410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/5089c490-71bb-43f5-83e5-de1fc7959b86/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021348232026_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/ab6fea6f-b30f-4c59-91d6-42d9f066cb59/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021360183925_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/d0a9293d-adbf-485c-aa62-4e6e69b94a75/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022003152706_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/5d9f2b71-2f73-4a2a-9d0a-e28a4bf6f713/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022003152758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/87e6195b-fb8e-419b-987e-fc060ee55f94/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022035192301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/ca5780ca-2c47-4a44-afd7-d980e503eae8/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022035192353_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/a48e5bc4-2388-47db-a881-d1976ad5a80c/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022038183541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/fb4beda6-d453-4014-b5a9-d85b459d3a92/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022039010552_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/b503e56e-16cd-48bc-bb54-f93d25ac337f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022039174724_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/4dbe6ec9-6b0b-4309-a430-e6827491c967/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022042170051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/7c656ff5-a419-4d5c-aa4e-6b586f660f8f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022043161218_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/3d07fd9e-45b6-4b88-b66e-207e1add4494/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022045224401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/139d2df9-f3b6-40ae-a5ec-1652cd9c9e68/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022046215416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/b080e6e1-0e24-41a7-bd63-e3f9413d0d97/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022049210656_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/4951cf6f-46a0-4c45-93e5-9146a7e3aa23/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022049210748_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/c9de30bd-cc5f-4113-9ea3-e01364c24082/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022050201805_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/5b198457-c702-4f2f-a105-b56df26ce401/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022056184305_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/266e2fa8-529a-400b-9370-a4658256df44/bbf7a1ab-5743-402c-a027-a1f486ecef65/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2022057175457_aid0001.tif
EDSCEOF