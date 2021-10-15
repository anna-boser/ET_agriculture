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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/85dc3ca4-79a3-4a3d-af65-1a712cd534b0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020275215846_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/bf629c8d-365e-4a91-b61d-7a6a4959b263/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020275215937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6ceafab1-de80-4999-ba3c-186d891a80ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020276211124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/385f83df-7839-487b-a857-cb2539eb3091/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020277202421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/10d68c57-3dd7-4d03-a882-34cbf2c9d138/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020278193726_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ee96e075-e718-4f88-95c0-6375165a182b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020278211348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/256a4676-b5d6-48d8-ba21-44ad1cc9a341/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020278211440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1cb812d2-42e3-473a-b0dd-372d9e5bef5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020280193901_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6419502e-e633-45c8-88a3-76d2059f476e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020281185136_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1807db96-ee2e-4689-a562-268677317598/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020281185228_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/3776e7d5-eee8-4dd4-9000-075c2ded2002/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020282180432_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a42c6189-3f08-47ab-a340-dd77eea340a7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020282194052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6dd37729-aa6d-4f67-bc7e-eb7fb391f6bf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020282194144_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b9ac9fe9-7234-4f95-a22a-fc0e0f9bab8d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020283185304_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8321d00d-b73d-45c3-8796-d272aadac95e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020283185356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b5ddf583-029b-4e93-81cd-c87b1a697c6e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020284012317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/036cbab7-fa51-4614-8504-5f4c9b74b897/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020284180517_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e654ada0-91d4-4d0c-8854-835bc02cc90f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020286163030_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/20630c12-ac7e-4f97-813d-657d5c741f36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020286180647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d2957151-8659-42c7-9c69-adc0fec9f05d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020287003640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/976b7ae7-234d-40d5-a4b7-c0407f63d89a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020287003732_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/746bee47-1ef7-4e64-8ad3-6834e3b8fefc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020287003824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/78a3441a-8206-4530-a7c8-fca57221719c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020287003916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b0bea420-69cd-4976-afae-267b50dbf892/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020287171859_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b40decea-be22-4179-bb15-3a76302d3834/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020287234916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c9b93150-5618-421b-9a31-da142df58f7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020288163113_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8f867006-ba01-49e9-a8f1-7d7d1fb7645a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020288163205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/0cd2813d-33f6-43bb-83bf-3ea56f14fe52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020288230118_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9f5cdba8-1582-4e3f-acbf-05e0b3427b11/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020289154331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/222eaa3e-e8a3-4087-840d-ea983359d218/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020289154423_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b9f3b96e-83d8-4173-a341-e2b4d16f698c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020290145617_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8fa2fb36-c0ec-401e-af46-453d3ba1d131/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020290230236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/fd16cb62-a3a5-4dd9-8b8c-54b22d89a9e7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020290230328_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/76d67094-1c7f-470d-9763-4858c7ef1cd6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020290230421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/0e65b042-1680-427c-aff1-23bc0eebf63f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020290230513_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b291fef4-e7d2-482d-8867-18e40c68cb38/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020291154448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/893acf5e-c9e8-43c9-a970-a5229f7ee238/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020291154540_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/043f04ff-2e07-4e58-a41d-9ec155d7025a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020291221412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/5962cb57-d74b-4898-bfdb-935f562b7442/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020291221504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/2a1a9924-59c4-4602-9e1b-b76402df0f48/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020291221648_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/58cd9e69-8acb-4af3-b363-ca1bf4e5bcd0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020294145919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/7c09fabb-1883-40ca-8e33-2e742b99240c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020294212919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1be69a5d-b9ef-4013-bc1e-de3904e8bc8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020294213011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e741a217-5a2c-463f-bc34-b04db7dc2af7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020294213103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/cbd4c2a1-530e-41e3-a441-c819a3af99cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020295204106_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e1c4017f-50d3-4b0d-9e2e-678053eb201c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020295204158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/dffb0275-fc3b-4c9e-a9a9-74488df2dbcf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020295204250_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/bebed80f-05e8-4608-9245-080ed9dd6660/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020298195414_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9574fe99-5115-42af-9eab-1320fc2a8f47/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020298195506_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f1737f77-ea6c-468c-8ed9-f1f6d3c0725a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020298195558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1becb473-1f7b-476b-a944-3f61898f1ad9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020298195650_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/02b2f254-e4e3-47be-93f3-e117439b6f4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020299190600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1c66248b-83e5-4481-bc42-4ee3f6057545/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020299190652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/cc4ef4a6-54ee-4fac-9b80-b372c748e706/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020299190744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/5f491b20-6df6-4a95-9887-4db361d59418/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020299190836_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d2d2f305-c04e-4e01-b1b1-4989f52fa246/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020301190916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/bc60c2e3-d2ff-48a3-bafa-a1cfcd57619a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020302182051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9229592e-b44f-41f3-9116-d911c721a0ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020302182143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c013d689-4dd7-4faa-97d2-95bdd9784be4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020303173142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/734791e3-317a-46f7-8a64-879e5bf1909f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020303173234_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/acc50bf5-b81a-405c-a93f-e6d91f4315e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020304164424_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ffc193e2-480e-4232-86aa-a23069e655f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020305173437_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e942d9e1-3b54-4211-aed1-d198c3c7abe6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020306164537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/07ed02c9-4edd-4757-a0b7-6f52b3af7995/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020306164629_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b90894d5-1869-4a27-9bef-ebfcbd399baf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020306164721_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/38b23dc9-0d42-4c15-81f2-c9e804b621b8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020306164813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e0ccb13c-a201-44d6-a36e-1e72c2dcee20/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020307155800_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/833e6db0-deb8-48b5-ad34-07d562dc04c0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020307155852_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/cd4ec88f-2e55-4c1d-a4e7-0be6d92f4f70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020307155944_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a8b34bf7-7a32-4b9d-9bdf-ee78660b539c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020307160036_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/0aab2039-3471-4e9c-819a-32a576c18e5b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020309160000_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/bcd200e7-192f-4388-aba8-ca2d1d7bc41d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020309160052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b945c545-d57e-46ef-92f7-ca761211c40e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020310151203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/09035cff-1290-408e-935e-712f501042aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020310151255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c06a944e-f737-4d83-b426-2bb78b5181b5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020310151347_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/bb93c58c-bf84-49d3-b747-6e0ec391c2a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020329000340_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/30913c1a-c5bd-4b2e-8b87-0fb16ee86f7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020329000432_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f49324aa-2473-404b-a2b7-7d7c77de9e92/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020331000509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/fbd03456-9557-424d-9647-9017e03d1253/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020331000601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ea1f8fab-0fc1-4870-81c2-ceb57fb169b8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020331231758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a78bc94c-7ad5-4105-ac76-30a58f16ee1f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020331231850_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/03b04c78-bd06-4881-a1eb-a34e9e4e220b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020332223035_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c9bfff37-3420-4c62-b7e0-a29f26333639/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020332223127_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f399875b-806e-4f19-a8c5-0b65c202c393/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020333231936_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/111230b2-bd60-4f01-a42a-742f5cec8103/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020334223201_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c2cf9e6e-0e3c-420b-a02f-4747cd503565/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020334223253_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/24b6fee9-5eb6-42e9-8a50-d12eb515236a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020335214441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9ccc3ca7-61ec-4225-91fc-e08d258b58c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020335214533_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/7d930329-c71d-4588-869b-f16d9a7e20ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020337214719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/68b58ca4-1c7c-48af-938c-7671c8f9ab7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020340192347_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/5ed47aec-38c5-49de-9d5f-f26e4f4529e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020343183734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/515f1394-96e2-4371-b3ae-8bd2a5480d23/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020343183826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/bd29faa1-abb6-4b8d-9bd9-196589880e7c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020344175011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e264788f-9e8a-4ede-b44f-4a43fa0a2ad5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020345184009_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c73a0477-32fa-40d3-a9e2-f1375cb26c66/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020346175137_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/351fd06b-5a4c-4f88-bf66-e8ab7e1687e2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020346175229_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b6593429-0701-4d6a-a556-fcbb9e45e46c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020348161633_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e8194793-72a8-4afe-93fd-2b89af9438cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020349233528_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/da556df4-55cc-4fcc-992c-bdc64b94c7d6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020349233620_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/5495f5e9-b075-4396-a38b-21651605be51/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020349233712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f4fc7506-bd3a-4674-9b55-6d0f746016d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020349233804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b362be68-187e-4766-8da6-9b907baaebed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020350224820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/bb1cc75d-71ea-45a8-a0be-adaeb8463f33/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020350225003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/23fa8741-02e3-43e0-831c-e1c7ebc93eb0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020352225031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/53041884-fcc0-4ca9-9beb-4f3d36c4912b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020352225123_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/632d3b8f-5a90-4e51-9aee-7b60c685ff5a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020353220147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8380ba30-0383-4e6e-93a6-5e1e2b70af6c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020354211438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/7c892f4c-f195-43aa-9004-01e69c60d026/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020354211530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/3581e30a-1b3d-4100-af13-ae8aecbdbb73/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020354211622_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d9968839-63fc-4d05-aed5-4396c95da3fe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020356211655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c1b47166-948b-4a6e-bfcf-51abb3546cf0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020356211747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/27a21d81-2b7f-4fad-a8aa-c45f8eaa604a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020357202946_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/3e666710-6dea-4524-a449-cba463fd7c82/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020357203038_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/5c135d48-72cf-48d3-b87f-a6fe011576ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020358194052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f4fa8284-0229-448f-81be-04625b052f8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020358194144_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/dbe313d2-3045-450b-8118-24ae948ab72d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020358194236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f27548aa-ff85-4a33-a1e4-84501cabfc51/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020359185255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/24479ce1-517b-46c3-b019-dbcc62581043/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020360194306_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/01b58c1b-6c4f-47af-b19a-5a25bc7314ad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020360194358_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/94c9777c-ae0f-412f-a8ae-aa940afb826e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020361185412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d8fb2992-1c2f-42d9-a57f-99953e5c695f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020361185504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f21e44a1-2426-41b1-9e31-deb7ce760e66/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020362180845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c5f39179-f776-49fe-a35c-5f5328508aaa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020364180922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9362e6b7-8892-4296-9dae-6d9f59451910/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020364181014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9b1fa492-d673-456b-8586-fbbc760c042b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020365172020_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6c79fd3c-6a60-4c7d-8d39-ff7a51aa8f14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020365172112_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/842634b4-d45c-4f84-af09-85dcf936fdd2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020365172204_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d7ac1464-2afc-4e98-b078-3d94f3c6701d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020365172256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a3332d54-c3ff-4546-bf12-52867a4b5bba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020366163447_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/97d52faf-1268-4aa0-a0e0-c04e66dd1e17/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021003154626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d3e381db-3c31-4d0e-b735-63a3bef3741f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021003154718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d136558c-5720-432c-8196-acebacf0724d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021003154810_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/04abd4a4-deac-430d-b6e1-bb53f505fbc5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021003154902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8b125159-425e-4222-930d-c6759dc5a4d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021004150119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1a71376d-7f1c-49c1-a7a8-f9a373fdecf2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021006150229_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a095b607-6bb5-4b1d-90d6-7ccd1ed1f599/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021022003820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ab15e113-c732-4e73-944f-899bc2ff0676/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021024003929_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e3267f0d-a0b2-437d-87bf-ea0040d422bd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021024004021_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/96cd8182-f3a1-46ce-b777-962806365983/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021024235211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ba923bc4-d03c-48df-aedb-b80122665e7f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021024235303_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ad408f98-3920-4d29-af23-00469fd1485a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021028221939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b543b191-214b-4a67-9b34-20e38ca53c4d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021028222030_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/7b66f381-7a11-4a2e-ba7f-8457b415e2f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021029213230_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d806a713-82fe-4939-b00d-cb0c9689b7bf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020275215846_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/69b0cdb2-1464-4f50-90af-507d3dc46bc3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020275215937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ce8ad265-e1e8-45aa-b6e8-94e0a3e0c1f4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020276211124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/65a752c7-57b7-4de0-8e00-0cbe9bd8c8a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020277202421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e7272c53-0d84-4eed-bedb-a395b095daad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020278193726_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/041270f8-4fb9-4b5a-bc27-bec70782458d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020278211348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/51c1e544-a24a-4d3c-a520-94815419f641/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020278211440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/34d4986a-2a02-4714-a743-a14fb78ef9f6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020280193901_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b9d617b5-19be-4be6-a670-26334d33f4e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020281185136_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/0682786e-9689-4318-b32a-0f939d162e67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020281185228_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/41d7cb10-bde0-47e9-ba67-09f48b1e5608/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020282180432_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/340ad817-5284-46f5-8fd0-3c3dd315f5c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020282194052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/096b087b-1b01-4bea-8e7f-698a12253263/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020282194144_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/5a8c145f-7902-4fa0-9677-52a1d1346c68/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020283185304_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/518ea9ab-2de1-4ed8-9c50-e924d9ed1ec2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020283185356_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1019e08f-8c5a-485f-96e9-12bbf757b504/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020284012317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1d4f6f2b-74fd-4b4f-acb9-eca174b68775/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020284180517_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/91fae956-84a9-4dac-85b3-f2cc7656f48b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020286163030_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/064dbf5b-b2b0-43f2-87ff-1a650823f9fb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020286180647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/feaf9e81-0055-4c0c-87e1-4408ff8b0005/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020287003640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/777cf56d-e9b4-4374-9400-05ea6bd5b191/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020287003732_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1e6d41fe-4937-4a93-b320-a9cd3d557cfd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020287003824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/01008985-6616-4ac9-9a3f-4dc4f0282e6e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020287003916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ad8b69f1-64c8-4205-8e54-d45369cfa7ea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020287171859_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e7db90e3-24b7-4ea5-b4cb-72581196c9ad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020287234916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/71664f8b-4a16-426a-baee-8a834efee0d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020288163113_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8827e44d-e4bc-4d45-8771-d2e575e32902/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020288163205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b9b4883d-1e10-4044-a146-aaef6d02d32c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020288230118_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8022a621-fc13-404a-addc-de520c69cfca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020289154331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/dac7e90b-742f-4b98-9914-9db60c7954a2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020289154423_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e26f356c-8629-455c-bf0b-68bd30a04ba2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020290145617_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/99056024-2e91-4eb4-9473-eeb278b26e66/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020290230236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9cfd90da-74c1-47ec-a0c6-b9df9c69b06a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020290230328_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1fd01a2c-976b-42f3-88d6-4679606e8976/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020290230421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/482fbbd0-3e8c-46b6-8d36-2bd0059b967d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020290230513_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/2ede2644-a7ec-4e70-a392-e7f92598d77e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020291154448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1ce2e8a7-a6db-4851-89df-c75f5fee6504/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020291154540_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/48ab762e-b16a-4b83-8f3f-41e22a8d335b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020291221412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/0d15b494-35f6-44d7-8e16-021b24300b8b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020291221504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/4d376e89-c1f4-4817-b063-6c3184fe5a3e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020291221648_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f6729c4f-a3bc-4c2f-a08e-7d72a83a5fd5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020294145919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e45c5111-a5b3-4d48-a8ca-ce44b945ca55/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020294212919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/48dd18fc-c156-4275-a96d-68b9b315bb2a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020294213011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/391823b9-30aa-4fbf-8420-9eab9d9697bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020294213103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/017fe3b5-4ce8-4e57-b185-8c753bd680c9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020295204106_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f7cb0db9-a081-4e69-9d74-92f03980b11f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020295204158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/113e37fb-6bfb-4182-bc47-7c0835bfdc00/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020295204250_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/84b777ee-a65b-4b5d-a510-d64ca524a61f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020298195414_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9fcf52ba-df70-4539-9bca-ca1474a4a81b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020298195506_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/168b7622-c486-48ff-9add-de611b5be931/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020298195558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6d926736-4d97-49df-978d-9dc3096329d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020298195650_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/30d93d57-9ce9-41ab-b6d8-aa138952d615/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020299190600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6ebec761-fd97-4602-976c-4038573f8f83/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020299190652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/105105da-25c1-4e57-90f7-e3445d4e4e29/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020299190744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8591a64d-3653-4259-8e3d-9342c1422298/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020299190836_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/02642c2a-99ea-42f3-9d4c-ae1016f09638/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020301190916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1fe0f1ec-6b9b-4358-b7c4-5981a70a5c64/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020302182051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/480a9618-d792-4cd4-9d9d-e86a96eb8d54/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020302182143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/738518d6-3051-4616-b5a9-b6f1eddb50e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020303173142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/78d0671e-83d2-447f-b3d4-0d2117e8c9a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020303173234_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/8a571134-efab-4dc5-bb03-ade644bf1fe0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020304164424_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/505cfb22-8132-4255-9ff9-8eeed7431a0f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020305173437_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/3b57df41-e8f9-4f9e-9775-f18ed966c1ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020306164537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d7955a96-2c81-4b2b-a5e0-aef9c820eb01/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020306164629_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/49b8c8d0-f4ad-4ba2-b26f-7f578ef27740/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020306164721_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ae56d5b2-bfed-4b63-8318-9ae9fbaa49d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020306164813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/892dc195-55a6-44ab-a429-9837e31eae10/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020307155800_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/652b8c3d-40e2-4e6d-8b2c-ef1d2333d396/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020307155852_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/21ee4bbd-251b-4de8-a4c1-b995ba31ceb1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020307155944_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/595f8841-f20a-4609-a5a4-95d4c5dee4ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020307160036_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6c957aec-37f0-4a27-b780-03f2bacbefd1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020309160000_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/2af693f2-dcb6-4cc6-a7a8-bd842663aa3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020309160052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/40e4382e-9ac3-41d7-a453-e3d91bed821d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020310151203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/7e7e5f2a-a56c-4f06-905a-517b0ea5cb6a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020310151255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/fb2ae761-d8f0-4476-a08d-a99953fa5363/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020310151347_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/5478510d-513f-488b-b658-7656cf89b2ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020329000340_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a1b4bb34-ed8d-40c1-9d09-c90de9a0ea35/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020331000509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/fe3022fd-4ef8-4e36-ace1-c3d98c2e740b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020331000601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a7d5d290-71a1-414b-8222-5497f8dee319/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020331231758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/b5f84449-b932-4072-bbc5-ce0632711858/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020331231850_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f6466f64-4a01-41b6-ba2c-ab8ac5ca0ede/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020332223035_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c4072099-9098-4fd3-bf5d-76e0425cb93b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020332223127_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/0bd432c4-5297-42e5-9a0e-e5e68c37993a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020333231936_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1043d961-b9f5-4a92-b364-f0dd9919164b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020334223201_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/3eb6ecf1-1b6c-494b-8137-468ab6ccb3c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020334223253_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/18fe72fb-ae52-4798-bebd-24ecaafa0c5e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020335214441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/4576e64f-8436-4be0-a905-6c4fd0e53742/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020335214533_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/931afaf2-7494-4c47-82d5-e60ed8d585e7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020337214719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/fa009a37-93a9-4435-bf62-06c970f744bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020340192347_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/dee8a42e-a185-4f6c-b38a-5310fea06e5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020343183734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e150db2f-2f13-4aeb-8dd5-99b5da145b30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020343183826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/4e88bc27-2f70-46b9-9808-cf28b3972d17/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020344175011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/30ec2810-f7bc-4b24-b3c2-adf1b13343f6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020345184009_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/42891f55-f53c-40db-ad0b-2c336585946d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020346175137_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/72073675-c744-4b96-91c0-67c0a249c412/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020346175229_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9148d7ea-38cc-4528-8767-7bd45a7f486c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020348161633_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9153f26f-1822-40b0-a3cf-7eaff4c62289/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020349233528_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a7ec566d-95d5-4dd1-9ffb-0eccd61a6f1b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020349233620_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/37ca79cd-9f29-4d28-bbe8-a2bb47514b67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020349233712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/3e8c6613-fc5c-4e79-82d4-292bdcb4f209/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020349233804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c2f2a91a-8175-42a9-889c-52815b11182a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020350224820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ab0fdd46-98d2-4a81-a41a-505ae6b3b908/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020350225003_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ee772329-ea1a-4dfe-90c6-664f02d6f9b8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020352225031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/168e8e76-8a9c-4667-83fd-b8dca5e69df8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020352225123_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c4f95ed5-3f7a-4bdc-82ac-55a0a54e47b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020353220147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9a207732-baf8-4154-9680-e40ebc0b4691/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020354211438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f2f94981-f1b9-458e-b594-051efd1bfa4f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020354211530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/baa88d6f-7d1c-426e-945e-b9d75f106670/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020354211622_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/bf490d24-aa76-402e-b467-575131ee4904/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020356211655_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/eae3cf58-8df9-4742-b3f1-37074e34ba5c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020356211747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/c8a11bf6-2e2a-4e6c-a423-e5aa9b4ba3c5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020357202946_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/93e9435b-bbbe-4261-8f98-f76836fd12f8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020357203038_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/1040d8c8-239e-4f4e-961f-c1ac224ac384/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020358194052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/0f4b7b90-9e0a-4e1a-8656-ac6d021ca406/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020358194144_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/dc4f3b7b-8ad4-41e0-9ae5-1c381be8e9f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020358194236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/4637de93-5cd8-420d-8f4f-ede84bb06842/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020359185255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/20633431-23b0-48d4-89fa-535d2d60dda3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020360194306_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f928f162-4c8e-4c64-936d-db14e24c57b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020360194358_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/295f0101-2062-4044-9559-325d5076695d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020361185412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/d373f289-5ca7-4a7e-b397-931f9cc6fb4b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020361185504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a304c489-3cf2-4a90-8929-d1cbae63d5de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020362180845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/02c26ecc-9bbf-4636-b1e2-dadcdeabf43a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020364180922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/f9cd195d-7146-48cd-bba5-4900add2061d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020364181014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/cc755b80-1162-40a7-a57b-a1eb643c5cd7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020365172020_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9abdb241-660a-4879-a3c8-072342a94f36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020365172112_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6f55f3e7-46c8-4797-a170-fec6fdd393d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020365172204_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/99f2f060-ccf5-4097-8086-3e7d00b5a2fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020365172256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/9677c9b0-2d03-4465-9327-d12287b439d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020366163447_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/0eb5a6bf-900f-429c-9c23-76f076280dc8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021003154718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/44763c3b-64be-499f-8ab9-b78a84630231/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021003154810_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/a931cb06-c461-4dce-8258-8c7fe373ecb1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021003154902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/3703414c-8601-4b3c-8339-46378c3d493f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021004150119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/ab659397-f974-4b68-96ec-bfc17e775802/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021006150229_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/e3527947-db90-433d-a3bf-e136efc3bce6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021024003929_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/548d4dd5-6674-4ea2-8081-d8db34bbb693/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021024004021_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/76d01bc8-14ae-4fda-a9ec-3d3dbca8a5df/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021024235211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/156d2c59-73ab-4cac-8153-bb67fe9239af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021024235303_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/259eeb84-7c85-4757-8754-a0d5818a91e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021028221939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/6c28ecef-5222-4263-a195-f75b26ce4ba5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021028222030_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/fa670565-7e2e-4451-bf56-90f80730f770/2a3bc5ec-45ac-4ea9-8da8-fc6393e86851/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021029213230_aid0001.tif
EDSCEOF