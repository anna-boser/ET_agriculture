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
    # read -p "Username (annaboser): " username
    username=${username:-annaboser}
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
    echo "https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ef7d8a33-7b7c-4f38-8cf4-6bbfdb9198c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019146015626_aid0001.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ef7d8a33-7b7c-4f38-8cf4-6bbfdb9198c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019146015626_aid0001.tif -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ef7d8a33-7b7c-4f38-8cf4-6bbfdb9198c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019146015626_aid0001.tif | tail -1)
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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ef7d8a33-7b7c-4f38-8cf4-6bbfdb9198c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019146015626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/31b1c313-586a-4500-985c-f5550aec0e44/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019147010635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3641fcab-341f-49e7-853d-d5eedd393e31/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019149010421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/7b460415-7784-427c-9c08-c2c55a9ca9aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019150001456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ffb18c7f-b0f0-453c-8f27-3fa26ac21c6a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019150232523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6145a2c8-6c79-4ecc-ac2b-a3f98fb784a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019152232302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d86b5056-371e-4b38-a8f5-846487603edf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019153223337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/83cf8972-e896-4d33-be3d-9c8e4d7cec67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019154214409_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/123470ed-b4d5-4b1e-bf62-a1d025940506/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019156214148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f0dd392c-a38e-494a-b296-0b53f433675b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019157205219_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6508674e-e393-418c-8649-ae3a291773e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019158200258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/bc3ee689-9919-4870-bcfd-ea3d1fa09069/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019159205018_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/afbc9404-9e18-44cd-99b2-79903c5fce34/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019160031949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/49c20d7c-959d-49fc-aded-76371516fbd1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019160200116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fbb490f5-5310-4322-b2b6-d7d0d1558a72/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019161023053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/986fe50d-a9e9-4ccc-ac4e-660fb495f9ad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019161191105_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/988822b6-9796-4e93-88cf-c10e6f5e1dce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019163190842_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fc54326a-1196-4e2a-a909-9b5b3efb436b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019164013816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3dbdb7d6-dd2a-4005-a5ab-8016a7b20862/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019164013908_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f6013378-c0c2-44ca-be75-6dbac2d7ba64/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019164014000_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2a1b1009-2121-4398-888c-407c6be8ae39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019164181917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/77db1ed9-c633-454a-82c6-3d521b7e6e40/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019165172949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b9ab738b-2149-4c34-aee7-f9da9ce4316d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019167172723_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/0b53621a-92e7-4010-977d-f3b191d2e5fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019167235642_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a7cf57c3-1c38-489e-8521-2f303e5ef2c3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019167235734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4ef54ed7-62cc-4fd1-b931-ad97f06faaa4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019167235826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/48c6f5f6-2c8b-4553-a043-67f5afa80067/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019168163752_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a78b55fc-60b5-4741-89e8-252caef0b101/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019169154827_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a1abb34c-3fb1-4ff6-82a0-f181087dada4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019170163541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d890ad00-d758-4a32-b35c-8bbd17e2e73d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019171154606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/0249db32-ef0f-4809-b2f3-422f6ab784be/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019171221555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c36a41d4-a8cb-4cde-a4ee-0d9367c783de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019171221647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/53355db8-050e-4922-949f-aae86aaaff89/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019172145635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6298258f-4ae5-4fda-b235-2c54f6566998/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019174145419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d8c44e1a-a757-41a6-aa75-e2a714b5741f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019174212350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1d906bbe-4e5a-47d9-b11c-56b8d1dbc890/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019174212442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/af03caf9-c7ad-4122-bda2-74355117b909/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019174212534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/7cb16c89-6f80-49d1-8ed2-a32ee4d82926/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019178131247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8e8ee4e2-f778-42f7-98ee-65792f72fb9b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019181185158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a35ad3fd-5b46-4f5e-8f92-2044bb4b896d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019182180108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/265ae2d5-f3d6-4281-b356-644fc9f09cd6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019182180200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/58b151c1-9c4e-4195-aba3-5d8a43511b06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019186162007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/af5db79f-5577-4982-a2d4-f941a168a19b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019186162059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/af77fcf0-12ed-452a-b600-9cd06c3df6fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019190143956_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d47fd212-c66e-4196-b4ad-5f7dab8969d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019192143905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/16b6fac2-8ee6-4c8c-8aa5-c9aabce30dd0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019204030601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/7399f088-d771-4064-85fe-209c476b1eb6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019204030653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b1870097-cdc7-4f10-82f3-b8bc650b6f8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019205021709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fba3eb63-fdba-49a9-bcef-07b144c541df/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019206012751_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/950ac474-9915-4fae-b21a-c68928aa812a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019208012553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9be74525-e2fd-494b-97f5-cccb26eb1d5b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019209003635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/73b76382-6782-441b-9d88-c74cf8be8f53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019211003448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/99cef6c8-e3dc-4b23-8503-d501079ced74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019212225557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/266d0dde-23e0-4f12-a380-4d7ad645b452/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019214225401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fff77f77-cebd-4803-bc95-95a34dd36b10/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019215220442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3a07ebd9-fa7e-4a74-b7a4-ae036e398e0c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019216211518_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/072739d6-047c-4237-996a-ef09b900b7f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019218211316_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/143d16c5-0392-422c-80d9-5294a3630bab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019220193441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/af630c3b-09a7-41ce-8020-d1cfadaa8b46/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019222193241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f7e93a16-045c-4375-90fd-887ed3370d01/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019223020155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2c5b98d9-48bc-4181-8d0b-6bda07332881/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019223020339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b90c5db3-d0d9-46c0-a7d6-ec565cd76ae7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019223184311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1349d869-59de-4343-95b9-2e6ad4a1d8ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019226175155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/14637e93-df7d-443a-9129-631b68fd7ca0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019227002102_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6a86f5eb-f6ea-40a0-a644-7a5523a7eb5a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019227002246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2775efa2-dac6-41c0-97e2-606e98f92841/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019227170241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9a0f2035-0fd5-4d0f-b243-dcca39d8b413/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019229170203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/78f9e98f-db5c-4f8b-89b1-27e5ff132ea5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019229233140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/42bd2823-c0df-482d-b1ce-c6c379f282bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019229233232_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/53e5285a-c9e8-4057-b5bd-e4104286826e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019229233324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/32801fe0-955d-4d0e-9ab0-2ea347cd52a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019231152436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/65a47a68-583a-452f-9d84-e78ed74bbf06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019234143457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c99635f0-70a9-49af-953a-159e4b31b59f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019234210456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2dc80766-ca63-4bc6-af8a-e8ee2291bd35/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019235134612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a4570cc3-d776-4826-8bf7-14d9350c37b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019236210451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cbfc1bdf-04c8-40e9-8284-e8b0125e6819/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019236210543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d7c9aab9-bbec-455b-9f58-8fed374a349e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019237134529_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b40d1b4d-f911-4b11-a59c-a4414fc0ae62/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019237201527_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8dd7703c-46d8-4679-9401-e1465dd7461d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019237201619_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ed51376b-b760-4c9b-a285-cd9ef0c91997/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019241183712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6066dd95-93b7-4db3-8489-8707c377462c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019241183804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5db1452c-d72f-4cf6-9648-81ededc83f3c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019244174728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8fa4b278-18e5-4b37-a811-05a9380f4956/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019244174820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ac9e4f4a-aa59-450e-b603-567671c43d80/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019244174912_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/0f99cfd1-a6e5-4a66-8957-785c4b4b38cd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019245165855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b8eee0b3-7ff1-457f-9189-bf075818179b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019245165947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/886010f1-c9aa-4053-88ea-4d565687e7b6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019249152011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/711fe2ab-85d2-4f14-9764-9bfd8a30de5c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019249152103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a8a7f9bd-14cf-47ae-8fdf-ce352ac6d07f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019253134205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ad4429cf-a871-49e4-bd29-f2977878af69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019271235301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8ce14f68-5fd6-4762-8fe8-fe33da051712/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019272230444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9ef308a7-89f6-446e-8625-7da6331f9551/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019274230422_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/94a636e0-0828-4a46-a9ee-f22038c19adf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019275221558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6631395d-bed1-4273-b07a-349aef01d090/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019276212727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ab62d908-28d6-4fb6-8d68-72833775de02/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019278212715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5a19d77d-574c-4723-8235-473110a1d1ae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019279203840_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/bdd37605-d743-4146-8705-16f3ebeb3eea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019280195010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b9f068bc-6fc9-44d9-bb56-6cbc10609b2b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019282194945_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4ea26e73-5bc3-4da9-bf6d-ed7631a3be39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019287004210_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/861116cf-c1d4-4459-b50d-8287ec22eda2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019287004302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/55fbc7ce-ba4a-4ad7-a080-49cffd4d1595/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019287172335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/7b390f00-1f71-4c7f-a298-1e9d5afe3744/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2019288163504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/600cb5d4-dc2f-4c47-a91c-c910ecfa4fec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019146015626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4b871726-660d-4096-acf6-a16639b2d1e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019147010635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d932b6df-c75d-4254-8633-55fa607d34c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019149010421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ab8ac3e9-f57d-494a-937b-d610b55bf7a3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019150001456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a004711f-3425-4bf2-bed9-99c99270b6f8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019150232523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/881486ab-f388-4e9c-9b8f-e1689f80d69a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019152232302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/09d0d03e-43c1-4e89-a311-c360bac3ebab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019153223337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/278ae252-dd59-4127-bfaa-9cf55e2669da/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019154214409_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/dd13b1c4-a0f5-4a32-b876-e1aebc0d0c5c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019156214148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cef0b91c-a522-400b-98f3-93ff8bac16d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019157205219_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4f0a1339-2178-4d22-ab9b-10bbb41251f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019158200258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1d375963-9e8c-41e8-89f7-7474ad09b3fe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019159205018_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/7209da26-edae-49a9-b3b2-36ac39e62c4c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019160031949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b244c395-cf7c-417b-95d6-2cbe279bcea3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019160200116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/bdf568be-c4a0-414c-8c5c-f74526913106/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019161023053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/958e206b-04b5-4a74-872e-9cd7f2258ec6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019161191105_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/0fd35900-5b60-4ae9-9330-6281026ed5b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019163190842_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1035a0cd-4f30-4404-abaf-3faca57da766/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164013816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/50bde26c-0f03-468d-9352-e33866095c39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164013908_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a5cfa426-9bbc-47ac-9b5a-58529c0bc2ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164014000_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/194a2b54-7b6b-4c82-b91b-199c2d0bf403/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164181917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f4aa710b-349d-4212-a23a-dab65da640ed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019165172949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b81abed1-c9cd-42f6-a9a0-b45657f62022/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167172723_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f1909092-b658-4866-b812-6b6382c45059/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167235642_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ccf035c8-66ea-41e7-b902-770c3d2b1f13/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167235734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/196ff330-b8a7-4afa-b351-9889d41686bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167235826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/29cb843d-913f-4ef6-88be-1dcab5ed5461/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019168163752_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/80593547-7da0-47db-bc3f-7b59338f4546/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019169154827_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/94820868-813e-49f6-ba62-82842843b792/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019170163541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d2437195-13f1-4ec2-9dc8-c8d19b834056/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171154606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e9c8211d-6b42-4b5b-bc83-1c83105697b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171221555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b14b53be-b1f8-4c24-8d17-87fca27fe550/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171221647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8f3610fa-6e3e-4098-86bf-38dca4faefe1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019172145635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/88650220-5e50-40bd-97ba-329232726c1e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174145419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e4a99c8c-3efb-4182-b6a2-54b7d5a91c7c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174212350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2a06e31f-b7b4-4fc4-b8ce-cc8f40946053/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174212442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/56b0102b-ba89-4755-ad7c-0a22fbef0a63/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174212534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/08d959a6-2292-4f31-ac3b-aa4137eb72ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019178131247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/507e430a-e6b6-4b03-a5bc-c47d56dadaa9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019181185158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9bdb1565-f550-4c56-998f-b11541fad97e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019182180108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/36c98816-7c16-4d55-8806-e4555b6c6a52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019182180200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5e1f3af2-74c7-4857-968e-b7ea88222936/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019186162007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/aba19249-caa0-46b7-9712-fe17dc0c1c2f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019186162059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/7b66cb98-3ce6-4455-8db5-3d37314aef51/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019190143956_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/611516ed-707d-4f97-a0e6-4a83eabe6af2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019192143905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d43db122-3470-4fbb-8fac-b3a1b47163db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019204030601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b174a78a-f315-48a2-a548-b7e5f16fa975/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019204030653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/60510abb-a9e4-46c6-8ad4-39e1e8752026/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019205021709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ba40c77f-9255-4e16-8714-0a3cbce1fdf3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019206012751_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a9a910eb-c745-4b87-a7cf-ae4c0aca8e44/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019208012553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/24b429c2-7a0f-4c1f-894a-9373e5ecb125/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019209003635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b4d2688e-b718-4125-9698-3465437a3f28/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019211003448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/227b2c6f-ba82-45b0-af80-0fdd16778596/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019212225557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f200f7f4-d4ce-4f15-a928-9a48a54bf9f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019214225401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/beeca902-df9c-42b0-9fcf-9b5a0f07e7fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019215220442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1454d351-49c8-43a7-b446-e6c927f756c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019216211518_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/16cd3450-368f-4ad7-b3d5-020817eebfcc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019218211316_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4f425602-1034-4522-848f-bb70c2b3174f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019220193441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d0e67724-0258-4e8b-8e92-7c46d4d4dc53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019222193241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a3a73b8f-8534-4575-88e6-fe203d4c6afd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019223020155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5c32e82a-13f8-4cfe-af7a-e23c6fc51220/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019223020339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c3af2251-dfb1-4928-b51e-2beb57f72688/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019223184311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6febca6b-283f-49c0-8744-d29b581b5023/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019226175155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/99099f81-9c6e-42cd-a722-5a73eef4a334/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227002102_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/af4dabbe-81fa-4b30-9a73-ca89977faaec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227002246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/90ee88b4-3567-4e2a-a2d7-0cecd355d84f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227170241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3aa80a24-1d90-49a2-80a2-b3c8ee41d71d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229170203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/63f6aadc-dad5-4b84-b0ef-9da59a65c6e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229233140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b35805ac-3619-4134-a18f-036d955b9e9e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229233232_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/0aed7a58-7514-4b84-9eee-27e336ab985b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229233324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/09d78cb6-b138-4659-be94-147a4dbb279d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019231152436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2a2ede55-8f4e-47e6-95e4-a195a38a1bf6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019234143457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/19c8e31d-fb16-467c-92c1-3575fa2a3838/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019234210456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c54807a5-66fd-4b14-b528-085ba1bfee10/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019235134612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2b0f6a51-8c0b-40dd-882a-5aa05eebf723/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019236210451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c5c6345c-6ca6-4943-bef0-f210444b009b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019236210543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/7f9ad9b3-7b48-45c1-a88a-b87f9266d717/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237134529_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/392b144a-6e2d-45c8-bec2-9dbd7b548e11/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237201527_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cfd2025f-93d4-476a-a08e-5d9833995a70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237201619_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/42f319ff-57ae-4674-8908-a00a714020e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019241183712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/aafb8eb6-3541-456a-9e59-eb9d90167afa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019241183804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ce596097-825d-4ad6-aeb1-c07dd8d20067/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019244174728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1586155b-1c52-4c31-abc2-da79f4b7d970/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019244174820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2ee7af5a-b3ac-452f-b0e8-94891e462fe1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019244174912_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3fc7b021-27c4-40a6-9a89-eb20887bfbaf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019245165855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d1fd56d6-8fda-4ca5-a1c2-fd1a7554430c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019245165947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4016cc45-5796-4bff-aa23-481a6edfd82f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019249152011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/78480c4e-595d-4500-985a-2f922a5bc574/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019249152103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/24bc691d-375c-45c7-9df7-3d6d28538d92/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019253134205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/94c06345-77e0-453f-894d-6720de0c6f84/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019271235301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/43bade38-b3dc-41fa-ba25-397def192f02/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019272230444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/eb466580-5a32-4884-97b9-562febd213d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019274230422_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2d7c921b-4e59-4659-b39b-c2723282895c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019275221558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1413bcab-c40d-4f65-8e8c-9f048336333b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019276212727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/da8d2f9c-dff2-47ae-855b-04326eee71d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019278212715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8e1c8b89-b244-44b5-b677-edbd64186604/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019279203840_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fb2b2e03-95b1-441a-bea8-53e857dfa731/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019280195010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e96feefc-e227-403d-9d30-64bfc67371e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019282194945_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b038221b-88aa-4f43-9ec4-27771f3c914b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287004210_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3862a106-acd6-40bc-81b7-00b175a17f63/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287004302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a6988d12-85fc-4cfe-ac18-230055852243/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019287172335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e3c3631a-cca3-4348-a259-7e1821109ade/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019288163504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d3297a4e-a0fe-4c80-a3fc-5684ec1fbccb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019146015626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/70493869-9a64-4219-850b-381ca089f172/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019147010635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/eff464a1-c6ae-4b3d-ac8e-32729e41a0d5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019149010421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ad22c361-23cb-46e5-a197-b022ea86c405/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019150001456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a9b575ca-a3df-4b3d-854a-1634735ba48c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019150232523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/01eab727-5c1e-4faf-af67-de722003c555/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019152232302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8f4dbd73-3164-4058-aa2d-ab2c2023de36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019153223337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ebb2524f-8f07-4907-b3db-61b1a7eccc19/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019154214409_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2901e4cb-b86e-4567-a9f4-1249575fa4e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019156214148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/699147da-47a1-4f62-a9c2-b494ba32dbb1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019157205219_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c2f50a6a-29bd-415c-ad5c-6fc6034afb65/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019158200258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b65903be-5bc5-474e-bb7a-7e1dcd631d51/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019159205018_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d67aadc1-614d-459b-85cd-e40e41571d01/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019160031949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/aa64f5f2-2951-4677-8b6a-724e96baa1a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019160200116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3d79a8bc-21d3-411b-be1d-952e9642e856/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019161023053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2bfe94e3-0c50-4c11-85dc-f5ceb525499a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019161191105_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a719847f-b418-46fe-b794-9c614a2d554c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019163190842_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d28e7042-e568-4b27-aba6-8c00c949e765/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164013816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/08e33b12-4f1a-4558-9420-f5bf8fc54c04/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164013908_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6aa6c881-546d-4a95-a317-4e0afded7ae4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164014000_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/48818399-ea27-4690-97f7-5d1a5c44452c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164181917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3eaf4486-3d0d-485e-a7fc-fc92bf105377/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019165172949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b6a6f421-9f59-4ec8-a3f8-d855af9ee28d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167172723_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/95d4c462-b2b8-4797-8a36-b61534407fee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167235642_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/17bad73c-25e6-4d6a-abc4-8b71d83dad1a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167235734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a2d2e38c-b41b-49f6-bc87-bf151217af35/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167235826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e057a17d-50c3-41c6-8655-8f69c29ed5cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019168163752_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/98e13d55-74c4-4ad2-bd5c-3a8728df783a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019169154827_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b602ca94-aa4b-47f8-990f-e564fc440965/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019170163541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/289a9248-7f79-4d9c-9ea4-6c0e0c803d2f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171154606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ee75b471-246e-400b-9033-937f77d6f2ad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171221555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ffec7965-c69d-4909-8551-370f722fe7f4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171221647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/83d9877a-0d7e-4e28-8ddf-f6db5479cae4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019172145635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5a684849-afb1-4a6b-9982-15f7dc97e0b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174145419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/52dd4382-f25d-4742-9eb5-b70d73ca5de6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174212350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/691da610-2871-4cdc-ac2b-6df51af5b518/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174212442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3cc074b5-3717-4e6b-b925-6f10d34e41c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174212534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/760ec460-eb61-43c7-83ce-76bb4a8e78b6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019178131247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/95d83688-edd2-4145-b31a-3bb608669019/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019181185158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e6ebc052-b0f7-4699-b14b-309c43a41b2a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019182180108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fffbb1f2-72f5-4eec-99b5-cc678792193d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019182180200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f2d39973-fb53-4ab3-8b17-e1e06bfa9eaa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019186162007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/30a0bc5b-b1a6-46b2-b41e-f5f8d5a69c30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019186162059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/dbb61334-7474-46e4-bf5f-1501fbb4cfdd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019190143956_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/aaeddc06-7074-4807-967b-6e279f59ee6f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019192143905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5be3bc90-1ce7-438f-a942-13a383fbed5c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019204030601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4010e85e-8c80-44d8-8ab3-469b1ef2ba4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019204030653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b186a888-c8c9-4d72-be1e-ebbee5afeee1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019205021709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e3ba0c1b-df79-4f45-8504-a1dae5cc617d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019206012751_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/42d51914-1c13-406c-89d3-98cce211178f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019208012553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c3f1fbb3-b627-4f0a-8959-9da36c81631f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019209003635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/10dd29c4-9420-42e9-8824-672b6a160e81/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019211003448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/718d4d9a-bce2-451b-8dbc-b26a60984a54/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019212225557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ca6cab64-f81f-41ee-99ba-c86b8e1c0da0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019214225401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a8bcf407-9f1b-49b5-b36b-fa4ddf623fbe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019215220442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6834db97-311e-46cf-b5ce-69382528d2ca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019216211518_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e33551cd-c249-49c3-888b-a11e3d51690c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019218211316_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b98a3f3d-a610-421d-be25-57b588b8b299/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019220193441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/939eabd1-aa6a-4f70-bf73-4be5986c06fb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019222193241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c011765e-613b-45d0-ac3f-06cafc36bfb6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019223020155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/38acd521-e317-40d2-984f-2746987e04fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019223020339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5a02dea7-4811-43a2-bb8d-f2f886e74e34/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019223184311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/0174052b-6849-4822-ab9d-9716fadee19d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019226175155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/074ce7cd-a7bf-45ee-80bd-37d52f358737/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227002102_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1bcdd812-6ff5-4d2f-81d1-1519a1e8a006/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227002246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b63efba9-bb63-4efb-8df2-a56992fbf45f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227170241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/502dc906-da6c-4497-88bf-75309a0b1ab2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229170203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c612c004-4a59-4ca7-9e61-495eac8458fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229233140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/975b7487-f854-4dc5-90d8-dcfbbac76aa4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229233232_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d8b7ee91-736f-47cb-a9ef-a1b4ce1aa13e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229233324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5332138e-a401-431c-8d3b-8e0d0d95ef18/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019231152436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9fc4ec7b-0d2f-498b-90da-1f6b83ee2c62/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019234143457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/67a73746-aa90-481d-913c-d7b597d6e0f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019234210456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f534dd34-bb1a-4c2f-91ea-0cb020885717/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019235134612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2a6e47b1-ceff-4f46-8224-b72392d7925f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019236210451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/eb586efc-6e5a-4ed7-a50d-851cfbefb640/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019236210543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c1bf73b9-251f-4ac0-9531-eca38f4b1c60/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237134529_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/0d9dfc60-8a03-4e42-a527-d0bc67776623/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237201527_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/63f631f2-e434-41ee-8264-ae767c231eb7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237201619_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/31ac433c-305e-4bf6-a7b3-eb32dccb1cb5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019241183712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4a358e85-9e5e-45b9-9cd2-ba69305c89b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019241183804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/febde1d3-a658-4572-b7d7-05168e0179d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019244174728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/574fefab-9e29-4879-8b08-bc66e7ff12bd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019244174820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4c33787d-a9b0-4720-9c39-b3d1efb94cd9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019244174912_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/98f23430-aa2d-47b3-ac79-3cb136d29ca1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019245165855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5a00cf17-0894-4df2-8ea7-630f5f4d47f0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019245165947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9f87893a-e2eb-432b-b303-924988de2e65/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019249152011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4e76177a-97e0-4498-91d2-9a7a5d3ff127/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019249152103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/dae6d9e7-3061-4786-88ed-8ee0820e7c1f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019271235301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3e8e3172-17d3-4a81-9075-06be583788d6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019272230444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f8ed2ec0-e47f-4a44-ad63-06b3f7386381/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019274230422_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8d98df6e-e735-4bdc-bc66-aaf4da4c67d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019275221558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/0a08be8c-50b2-4c83-9e0f-7bbc335dab07/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019276212727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6add56fa-1282-467d-af71-524f44e386d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019278212715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b5e8a4dd-303f-4f0f-8f0e-0df4c7a5e64e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019279203840_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9de75e1e-5db3-49bf-9f76-818fb9a96353/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019280195010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4913d839-78cd-4ddf-91e4-068a458fd584/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019282194945_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/61cd9ea1-16fa-4f8f-8198-48f3f6dcc50e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287004210_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2fa1ce25-31ce-44bf-9d32-1f5a957f831c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287004302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cbc763b9-47b5-4c49-8084-fed7dfcd0e46/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019287172335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c223eec5-7a1a-438c-abb4-272c6c341414/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019288163504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4b7d4212-426d-4c77-b452-45a21165bd77/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019146015626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4c02efcd-5726-484a-8699-7c97a4c38dbf/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019147010635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/20286641-a5e5-450f-b73f-7cc5be650f84/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019149010421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e4bf383d-24d9-40eb-86c1-5da73f61c2a3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019150001456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2a7b9fd5-554b-40e0-b453-e7045d76be14/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019150232523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e63a9658-baf1-40d5-aacd-16e12d09ac06/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019152232302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fab80d78-2361-4c1b-b009-4f06d65e157e/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019153223337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/aea7f9fe-0681-4222-874a-cc97dd76af22/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019154214409_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e528824c-59c1-4a6e-9608-731f94763442/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019156214148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d8c99f95-8b71-4a67-bcf6-b2ec2ca56a2b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019157205219_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/800b0680-79b0-4ad7-83dd-1b352132dc49/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019158200258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/32fdca5c-39c1-48d3-8070-22b964d6d60b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019159205018_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e8f0f423-7ca7-4c8f-8cc4-81603d455c41/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019160031949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c0c76660-fdce-4362-9758-3053617f8f41/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019160200116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f7412c92-54d6-44fc-97e6-3f0b330e3bd3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019161023053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c95d540a-25cf-469a-b64a-9e163ef5f632/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019161191105_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2902dbf5-f5e1-4b7a-a744-c496eea215e5/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019163190842_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9edf1f1b-1769-42f8-ab86-7818fb81afbd/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019164013816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3f301b12-e683-4764-be5a-093fec61926f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019164013908_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d36f29a4-4ec0-4843-a9b2-6543923fce45/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019164014000_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/51ab2951-ce1a-477a-9892-aa7c64c4a65b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019164181917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d1da232a-be44-47b7-81eb-d636a8be3f29/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019165172949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9d2e7b12-dea3-45e2-9166-2f44d70575ba/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019167172723_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b5095d00-db63-4a65-8970-2a0097259284/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019167235642_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cdf711a6-2e71-4769-99a4-eaa00a8c6c6d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019167235734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d0b41cb2-c72d-4470-8d89-9653bb909eff/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019167235826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ba1736a0-989b-45f8-83e7-52352b5bff5a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019168163752_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cbdf2f8c-3115-47a0-9a68-0507a0771457/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019169154827_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ec6ecc57-390a-403f-98ad-af2521fe8ed1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019170163541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6225f866-d440-4da1-a716-f4f92c9e8193/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019171154606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ed69d271-bdaf-4164-bd32-50ee8d39d3d5/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019171221555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8c09e0d4-8557-4c17-b5b3-3292570d216d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019171221647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a719263c-c794-41b0-a7ce-8e11373c8dff/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019172145635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/34d317fe-63de-4c39-99d1-b9e9f0c5e8ee/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019174145419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/29f467db-b988-4527-be6d-33197f5d0be5/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019174212350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cb79915a-93b2-4cdf-8f32-a327b4586772/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019174212442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c96dbc8a-016b-49b1-83f1-514565b023e9/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019174212534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/dfb0840f-2874-438d-a1d5-60aa4a1e7e2d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019178131247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/df623110-7a75-4797-96c6-93abd86482d6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019181185158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b0a6fa10-c3ec-4334-bf72-43a90655e9aa/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019182180108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c836add8-2acf-4aa6-b4fc-325b954a0738/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019182180200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fb9eb188-3499-46bc-8d2a-b63f019ba38d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019186162007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/b913666f-f905-4dba-a73b-37e59c3cbb60/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019186162059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/2a9d75c3-8475-4eb6-95ab-3a8463a7887f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019190143956_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cbf4f224-3236-4918-8fc4-68ed4b71ba16/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019192143905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a6642943-ca64-4433-971d-4e385aefea6f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019204030601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6d9a66e9-c23a-416a-b519-6b26b509263a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019204030653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4193cf5f-c2c0-4153-b5f6-48cb1c132e35/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019205021709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/6c288fde-5e01-4ea6-b0db-d24f6dd00538/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019206012751_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d66d3bdb-754e-4228-b094-55476d6656e2/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019208012553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/90c99f2e-61a3-42d3-ad2d-a8b2bce9d841/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019209003635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/68dac016-9add-405c-b4bd-c31d880f69df/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019211003448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a0958615-b7f7-4455-b471-949dbd5c0fb3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019212225557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3f9959db-4ec9-4f36-ae95-f3fe576f5233/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019214225401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/23166c39-3200-4513-8dcc-d2b680dff6e1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019215220442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/04dc66f5-8f5e-4517-a793-e0adf026450a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019216211518_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/287cd345-8b49-4246-b9e4-ce5bdc067ce5/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019218211316_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8e4ea6e4-094a-4ab5-b4af-e11f18c7c7c0/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019220193441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/1b33b738-cfc3-4f7c-95f6-26bf22646347/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019222193241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a1da450e-bf2e-4970-8329-5ac4839f7c23/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019223020155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/52e17c06-e784-4d4f-86c5-82f48711891d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019223020339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/a02d6cc2-686a-483c-970e-0cc7ef884481/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019223184311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/66c3044e-eeb7-462f-96c3-e00ff7370841/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019226175155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d7c89a5f-8597-4319-abe6-d3534e7f2379/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019227002102_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f427950b-2778-4e84-a209-40e983f360e3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019227002246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/75b0a526-20c6-4c9b-b80e-4ce72ad0e935/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019227170241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f4a82dfd-8f1e-4159-b60e-845c8ed290a0/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019229170203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/46b16c25-529a-4c6e-ab46-e7e9522ef8ea/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019229233140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4b714a40-b8cf-47ec-a3a5-0b174666d1ca/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019229233232_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/e0fd4a26-cda9-4492-93f7-b3ad2b451b73/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019229233324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cbc3240b-a986-4cdf-82e5-20cb08d37ec1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019231152436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/8fdf49f8-9649-4a95-a45b-22ed6f306209/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019234143457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c43a8097-87a5-49ea-98af-bee9a92d54dc/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019234210456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/c98ed7a4-8d6f-4f8b-818e-3776f985a9c8/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019235134612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/00c88e03-f225-466f-a0f4-5205b3365a4a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019236210451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/20538469-56af-4bf0-941c-539ad4a8838a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019236210543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/d0ee35de-4a1c-4400-bb82-bc361d7db795/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019237134529_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/af3c123d-c031-4391-8437-a91ccd9410df/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019237201527_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/31fe6f74-f293-4cc6-a584-d21472513940/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019237201619_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ed3615de-2dbc-44b5-80a4-2f5fa7a15a57/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019241183712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/347f1142-839b-482d-99e0-ab284445ce52/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019241183804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/70798a4d-b50a-41c4-867a-8a6e21e8ad3a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019244174728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3eabbd3a-7cab-4364-aedd-38bf8eb4bb1f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019244174820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/5035d215-0b6c-4665-ace4-ed5d7ad73441/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019244174912_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3d225bbd-e72b-4029-8b12-2300998f37b6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019245165855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/957a64e7-8ec8-44e6-baa9-9946c9f5dcf0/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019245165947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fe219f38-0a29-4a89-b2bd-442fcc1043f6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019249152011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ddb6fad1-b73b-4891-be3e-ac203f030335/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019249152103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3746dfc0-1c74-431c-a61f-f76032d6f577/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019253134205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/ede7fbbe-874e-41b9-a27c-9a1588cb1b48/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019271235301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/f4611018-4331-449f-9db2-f56ddf629f9a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019272230444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/9dbad989-ab73-46db-a037-61bb75ef27c5/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019274230422_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/58ef66ac-57dd-49a0-b521-b043b3c7bb23/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019275221558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/22732c24-acee-40cd-a876-c034c9184a2f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019276212727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/3449ad92-cf32-4878-9f85-a4be9a25ef6d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019278212715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/75b2ea59-2f7e-4f02-9e70-a4dc1c4ac5d1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019279203840_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/65fb75b7-6683-4b4a-b380-1ef531f703d6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019280195010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/cab48202-1987-47d6-a672-a5c38c4a4642/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019282194945_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/77bad159-5f4f-4e1b-baca-de3b7b2fbefb/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019287004210_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/fa14d785-8539-47ee-a127-245246ffe8ff/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019287004302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/83621f19-77e8-48a9-bf56-25b2006b4de4/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019287172335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/abebceaf-c5b6-49db-958c-bc2e70c290f7/4c69a7d4-5bf7-4f4d-a3d2-a84eb5a8cddb/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2019288163504_aid0001.tif
EDSCEOF