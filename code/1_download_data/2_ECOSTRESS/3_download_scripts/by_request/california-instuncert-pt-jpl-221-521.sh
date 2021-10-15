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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/8b18115e-48a7-4f84-88a1-55b0a90a8a1a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021033195952_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/adefc74f-8fa7-4c82-9a5f-1f49c495c27e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021035200132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b696b1cd-78b4-40b9-976d-23f8c59d55bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021036191410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ec9c98cd-8d0b-4218-b31f-40438fab7371/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021036191502_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0f5ada5b-1372-4e3c-93ba-ad7c017e1a58/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021037182659_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/469b9711-a702-4c84-bccb-4ef1e8788388/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021038191616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5febb935-a8b7-4191-978c-64b3336fb5c1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021038191708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4284e3fa-899f-4234-9666-a7cef7401287/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021039182847_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a4d53389-1448-4849-986a-9e0283677834/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021040010054_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/15b8a457-6d49-40f7-8146-e6a98c188543/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021040174124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/24ab2585-4988-4e99-b184-e795e42cc324/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021040174216_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/34cbb2ca-44fd-4216-b96e-fc7f2b65844c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021041165413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4cc64773-f201-41e9-acfd-249589bc1650/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021041165505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/29c2a869-69b2-4f7c-94c9-99571c19bd66/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021042010216_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4a6cf958-e255-47e5-8e11-e23585b16a24/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021042010308_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a7906df6-2a01-43f2-8b6f-0b36f8d3b910/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021043001513_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a877b309-2bf9-43ba-9155-3dec6e4941d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021043001605_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d1bcd9d7-d25e-49fa-86b7-f40a37ba2e0f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021043165609_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/866b41ad-c004-454d-bb0f-9a283560e261/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021043232635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/94c13106-4e8b-4d15-912a-69aafb931b30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021043232727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/3dd92745-3811-4a35-908c-124766216cbc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021043232819_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d5710f1c-33f8-4fb6-8acf-5ec9d6c7a286/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021044160839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a715e3b2-e0e2-454b-8f09-2f100ff8d828/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021044160931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9a16f0f7-07be-456f-9767-91a94557263e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021045152131_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/37a605fc-192d-487b-a35a-cdfbdee6bf56/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021045232930_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4e6a91f3-4645-438d-bb5d-3877a4ea87e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021046161140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9c4d422c-b266-4ff0-8371-e3cf2d9a6483/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021046224044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/db8399b8-f04a-4ce7-9926-e35b7bad999b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021046224136_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c57bc6f0-7892-4a90-8b5c-10c4ffb2871e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021046224228_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/562de925-d52c-48d4-a2a8-cde42065a9ab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021046224320_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2f1ae975-11bd-422f-8c66-0b22f894d7b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021047152321_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9f83070e-312a-40d4-a63c-1e83fc633cc4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021047215256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/3a9bb68d-9b5a-4280-a91a-bf9af4d0745e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021047215348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/74946451-d92d-43f2-95f6-a67f9403bf70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021047215440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d51c8f9e-3986-493e-a356-994bbfc8986c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021047215532_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1c4e8716-e985-4633-a8e2-5c9c1eda0e59/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021048210606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/458b83d8-f961-489b-8708-860ec1d5700f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021050210747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e41d624c-ce5e-48b3-b16b-0ed15aafa434/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021050210839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/06940903-b233-4129-b1e4-c673d8f2f39d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021050210931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/433a5d53-6f4e-4472-886b-1dcd9fe2059d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021050211023_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4ea23882-b5a7-4231-a0a7-36362e0b73a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021051202143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/92127f28-2452-43c2-802f-2624e6c58f67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021051202235_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/22462871-b6cc-49d0-aeb4-27d859ad898b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021053202343_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/889f734c-6cf3-4a25-95fe-0b16a1bfb4de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021053202435_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f64170e9-4a16-4508-b8e9-167d79284a20/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021054193456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a5df1cd7-3f77-47f4-acd4-705794566f36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021054193548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e8959f95-579c-465a-b91a-c2884a1a2cc3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021054193640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e4b84589-18ae-4c81-82bc-07b6d53f01d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021054193732_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/fdcb14f2-ebc8-49f4-84a6-ce627a8c0b0c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021055184759_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/36bab376-0274-44c1-b8b4-2abf0955bf9f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021055184851_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ffb1ef7b-7d9c-40b1-b60a-0ad3e2520fdd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021055184943_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/22f53640-63e3-4582-acce-3d105fcdd04b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021056180010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cc29b4d6-c5da-4556-acf0-3190d47b8561/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021057185119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d93f3202-d5a2-4c71-b4bf-eca2232f4600/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021058180154_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/04893b3c-ebc5-47f2-9a7e-fac93bc1d46c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021058180246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e58c5fa5-23ae-4637-a4c8-91d0b4d62fef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021058180338_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/27a29911-c2da-43e6-b2a4-4793c18a9d7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021058180430_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1a3e02e4-0fe9-40bc-9c26-31dd0820179c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021059171357_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ea0ae471-9d9e-4f29-abf6-feaac6635deb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021059171449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6e30e13e-a7f8-4ebc-a6c6-c12074c99505/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021059171633_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5460c3de-6b5a-4e37-9c74-1066862908c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021061171740_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9e2b91a3-8e0b-4a50-b85f-5f222d86f6df/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021061171832_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/201caf9a-df47-4a3a-8585-8a5feb2f4de4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021062162853_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5cc92eb0-1bc6-49ec-9b56-4add80245af0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021062163037_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/33689508-7ec2-4b44-aa5a-0358cc212db1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021062163129_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/53a4f4bf-61cd-411d-8473-460c2cf60b0e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021063154241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c9e286db-c950-4540-9e63-106b61314665/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021063154333_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/fbfa3bbe-cc2f-4802-b674-4314dfef3b2d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021064145400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cfc3e2aa-eb02-4b1f-a3ba-02190c675651/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021065154438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2335303f-a1a2-4cc5-871f-75171fb2ea47/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021065154530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/45f33809-d59c-47df-876a-f516007b941d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021066145545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e197eb0d-54be-44f8-85a9-f14669049124/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021066145637_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/514d8fa3-80be-428d-951e-fdfaa604e039/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021066145729_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/69d62a45-96d1-4c71-87c7-8a66a27b592d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021066145821_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4b259065-ef87-40c4-ba27-31a4e1544068/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021067141019_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e7f383c1-4f42-4449-86a6-a59e68627794/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021084003939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1d56a7c1-cf2c-42a7-8a5c-e07d705c4329/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021084004031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/00c492ac-2cb3-4743-861b-d7ac423b83dc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021084235228_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c4cf6ccc-3dff-4b8f-818f-62956fd73c63/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021086004137_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7ab6efe3-092c-471b-8b42-41407099d946/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021086004229_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/bb6ed28c-8a43-4b48-b9c1-68a1ea07ba51/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021086235419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/946acebb-ec87-474f-8af3-ffe71c9bb30b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021086235511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7e5e7c16-b4a8-4214-8bc2-f121c9aba09a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021087230652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/04ac7337-d0e5-4070-bfe4-2b6d3ce890bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021087230744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/63e6d7c2-99ae-4082-b17c-e79fcc5be670/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021088221941_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/3a8abeae-35d0-42d6-a1b9-f930ccf25d9f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021089213240_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ba87f880-2fa5-42f0-b9a7-ab68b5a8f0ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021089230902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b32fb0e1-1abb-4cad-b433-1847ae04c056/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021089230954_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d1e401c1-7678-4448-bdbd-d0409526e5eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021090222132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/baa9d5c9-dc95-4fde-8bc1-ee75bf5662ab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021090222224_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/368277db-3cd2-42a4-bf6d-b2893c8fcb04/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021091213401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b9c5f2fb-d593-4e1a-8296-28d9f6362586/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021091213453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/bff242a4-ae84-4723-90b1-60eae5c3b925/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021092204651_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c4caad31-00d7-4dd4-b659-7cefb94c8932/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021094204855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/796afaad-b633-4bd6-8317-908ae43db04b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021094204947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b0016440-1b3b-4142-9314-eb828670a048/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021096191420_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4f03e974-ee6c-4718-b981-ea0d3a3eeddb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021096191512_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c9c1e6be-f916-40cf-8e1b-1d2c41e5bbbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021097182732_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e328d05c-3983-4425-9e92-08c30d94f423/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021097200352_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9fcb6f62-fcaf-4966-b1dd-ea606ad4d874/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021097200444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ab921d4b-d343-4c1a-bf68-d0e7a3a45970/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021099014610_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d13d00b5-1152-48cf-94bb-04824ab08fce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021099014702_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c6bd2b53-06fe-4c28-864c-5621774ec171/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021099182905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d4095de0-6cba-4300-8d4b-92d615bc7238/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021099182957_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5dbcbbdf-7405-4544-8f13-0cc3cbbe8273/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021103165635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6626bbf6-0673-496e-bc71-149630aebba3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021103232646_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/aca24c17-ed22-4d0d-a82a-97f9351de4c3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021104161012_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/acc979ee-de04-4729-98b2-c4ef6131b966/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021105165851_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4455ea38-902d-4a19-943b-e54adbd9bf1b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021105165943_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/fafba732-3f93-45d9-ba17-205178ef9c02/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021105232949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0ce79d34-ebfb-4b67-847a-081d25dcf0e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021105233041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/490aeda3-7642-412d-8d75-3a47deb4abbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021105233133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4cd0d678-6297-49b2-930e-540de820553e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021106161127_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a2c3936f-8bf3-4185-bd48-a48d91a71618/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021106161219_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c635ff50-880d-4496-8cd7-5b0c82555213/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021106224056_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/77e109b4-b482-4f2b-a331-8cacef47b50f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021106224148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e5ebb16f-9f79-4bff-9c4a-771477964b1d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021106224239_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7766bddd-3a54-4c9a-be34-f713851a8b57/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021106224331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/20510f64-40c8-43a9-896a-685882a4fa64/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021106224423_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1dae37fc-d0dd-47b3-9768-d9b25f36d7db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021107152402_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/fd8418c5-541f-4359-815f-7dae787ca51d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021107152454_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/09054a69-1e55-43b3-8de8-ebcf1ca5a59d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021108143647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b517d6a2-e216-434c-b920-19359845fa34/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021108143739_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/63f879b5-b4d3-4e57-a65e-123e45b0f254/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021109134950_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/bafb47b0-3a10-479c-8ac3-34fb4e1e1d29/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021109152618_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/52556185-e548-4838-8060-17302d2c24dc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021109152710_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/8f04aa41-c5d0-4c70-b56f-0e0feb22bb85/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021109215623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/55f8cda8-2a55-4f89-b96b-6a2a815da6b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021109215715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4021f7b5-e613-402c-bee0-c8621dd5d853/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021109215807_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e89ec3b1-a74f-444a-8582-54dd894a9592/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021109215859_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a3a9d5c9-fd2c-4578-9f8c-6b1fb02e29f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021110143852_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e45b0430-a8bc-4566-b954-dbb3ab4151d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021110143944_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a7487674-8ca4-4407-b6da-123f1556d0ea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021110210915_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b17b3abb-d701-4c63-8e79-7c85ebd9f4fb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021110211007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9d0700cc-0a5c-487f-a443-594356a68462/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021110211059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5f98516c-fcd8-4b48-beee-61ffdbb54adb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021110211151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5b06297f-847c-48df-8553-be46ced3c404/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021112130445_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/fd0b71c8-e32c-4986-b310-bb94b6827066/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021113135340_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7da82c70-4c0f-4de3-984f-30800e735120/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021113135432_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4ef63cb9-6793-4bd7-a095-1eead6ad4b38/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021113202343_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/52530915-24d3-4eca-b063-b19609741785/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021113202435_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9e6f3662-e04b-4b67-aaa6-94350b7d0658/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021113202526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/48d8c4a8-d55e-49d6-8470-7ed39421ae5c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021113202618_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/39ecad69-2569-42f1-a064-d05fae3c6a1a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021114193633_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cd66c01d-b333-4822-b39b-bca660a75dbc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021114193725_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/394df1e5-3d2d-44f7-9ba4-727e2b16a44e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021114193817_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cb5174d6-eefe-4f2b-b949-3e62b69738d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021114193909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/be7cd279-f90e-48c2-bcea-76b34d717d0a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021117185101_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9d13c9b2-29b6-499b-b69c-34fdb6b4e2ae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021117185153_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cf41e4e1-2c62-4ec3-bd2b-0c5fa4f54642/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021117185245_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/3b736cd9-754a-406f-9f46-7f54a9004f72/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021117185337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/12d1c382-070a-4091-a59b-b5bc7f0c07ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021118180257_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/12c6adf0-8d74-4bfd-8be4-d639638583e6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021118180349_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/97d1f30a-c1b2-4a04-977d-0143cdd96355/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021118180441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/aa6625df-7ee9-44f5-8fc7-e7c624e9dff4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021118180533_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/8d83e4c7-05cd-41d0-8577-f7c072ce7550/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021118180625_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b0ca081c-bb1c-4777-9f35-337237141772/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021119171606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1a94ab5b-1849-48b6-b059-b922e87d9e71/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021121171808_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a61b78a2-a07c-4c24-82ff-b8932c2e2abe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021121171900_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6df17c2c-42b9-4d69-a036-7215273ce3d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021121171952_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/8dd28a77-9c4a-4a81-abd3-7179ef9173af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021121172044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a2fd21a5-c513-4d7a-b7a9-7cd1a94db112/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021122163146_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2e5dec21-837b-49a7-a563-644eac087c6a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021122163238_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/47aaa241-1640-4fdb-bea6-0524fa8b4bbc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021122163330_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b66e2b49-bf26-4ea7-8129-482bc5706bd0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021125154508_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b71b1705-04ac-43fd-ac2e-942240405113/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021125154600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/22dc593b-2265-4b6d-b363-208d60df0271/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021125154652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2fa3a2a6-3404-404e-86f5-2a09866d5950/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021125154744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e191222d-8a62-473a-a822-e11925a879fb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021126145802_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a91618ea-5778-40d8-8e97-d974ba3e805e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021126145946_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ef7ec6da-7150-4c45-9528-ef0154d6296a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021126150038_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7eeba14b-db20-459b-97a0-2fd8bf1108f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021140021358_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6194e340-5e68-4965-a77d-10baadb5a662/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021140021450_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/db29cbc4-f1e7-4cc1-84ba-288b7d53bfa9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021141012649_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a5d7ba2b-e122-4348-a769-4e6031080b29/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021141030330_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2f0e193b-68ea-4d14-9d4d-9ce7bd70d428/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021141030422_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/44f929a0-8619-43dd-b2e9-7e9c4f647b41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021142021539_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/fff8bb1f-d26e-4abe-8aea-91d53d2422b5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021142021631_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e52c6ee6-9550-482c-9a89-9b730e3b9862/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021143012832_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/88f4ee6c-c324-4e07-ae0f-ea6e2ad49f27/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021144235412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/06e4d4ee-75a1-4852-9713-7b19194782ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021146004318_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d7b309f4-e8f2-495b-bd8e-d020d9b54351/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021146004410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/bb0bf968-c499-4ebf-ba26-56406b85c6d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021146235552_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5efbda34-5359-4898-aa9e-713673f68ad9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021146235644_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c35e88d0-4ff6-4fc4-b2f2-8e9ee47dddfe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021147230830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ac32991b-3679-421c-ac24-9f898a2015b5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021147230922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/bdf8f460-4837-4b76-9fc9-aee8fc9c53ca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021148222128_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9cfac2d5-5149-4d45-98d3-f932088a3fb4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021149231034_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2a34c8d6-9183-4617-846e-67d657b7b17f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021149231126_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a113aa2d-d574-4c42-8400-e231d4cabebf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021150222305_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/db57af95-3c59-48d5-bd81-b483bd64d105/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021150222357_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2d70ff14-6072-4b09-be6a-109e98333525/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021033195952_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/64f464d9-252a-44f4-812e-7be52d7e8e3a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021035200132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/246f620b-6fef-4c8f-aac0-270ab414109c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021036191410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/12772b05-5c05-4c9b-b4ba-bf9b9f50d640/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021036191502_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/76df6604-6287-4d3f-9513-c26643016bb8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021037182659_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/16b3f9f1-6451-486d-8e08-32d7a4c0e94b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021038191616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5a85731b-3dfd-476a-aae4-377b84d3e041/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021038191708_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f781408c-8af1-4213-9442-14764a4cc9b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021039182847_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c332408c-b49e-42f3-ae2f-8dd8aa2fd70c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021040174124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e5c80cff-90e5-4121-bbd3-17a6be5f8175/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021040174216_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a15cd775-078c-4f33-a6f0-187902594536/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021041165413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2541a88e-a3de-4466-be35-1d22a4aaa052/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021041165505_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c351639b-25c5-4551-8a38-adfa5b8b07f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021042010216_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b6c6db22-1199-4e74-b1d0-f23e2bcf3310/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021042010308_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f321e3ba-271a-4569-acab-bb88f820ef0e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021043001513_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b010e526-db6e-485c-9ac9-9b5464ec70b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021043001605_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/54c64b4b-5b01-45ab-8098-144cd6209522/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021043165609_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/683450a3-ed63-4b72-9ba9-ec9c2def3e7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021043232635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b3b9e811-a63a-408c-8feb-768bcc8c9e10/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021043232727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cc3898f7-1144-45a3-bbdd-955dc7536ce8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021043232819_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a4bde8ee-7fef-4822-96b6-ce9ec7adb164/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021044160839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c020f318-e6f1-414c-87ee-e70e2c4d4128/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021044160931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/93c9f442-4f98-44be-bdef-2f03910e4fb1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021045152131_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a709cf2a-f08d-403e-8619-d59df0711bc0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021045232930_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/27375884-408e-46bb-98be-f89a54bcacee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021046161140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/286b85dd-1343-4fdb-8ba5-69da12ac119f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021046224044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/681ffdc3-cce1-44e5-b9e1-29f5dfda26d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021046224136_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/274f84f0-4f81-4a75-a1f8-2c59bae3ca79/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021046224228_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/45516d0a-0b73-4b02-9edd-02968a418bab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021046224320_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a7607d9e-c76d-40dd-80d9-1ebd55fe3747/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021047152321_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2769500d-b829-45c0-9230-32c069dfaaf6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021047215256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4b3e3fb0-3b28-4efa-b3e1-d269db414ffa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021047215348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0ac84faf-cf07-4642-a528-3200087a854b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021047215440_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a8233b17-9df3-4537-a71d-cbb0f4f83fde/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021047215532_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/67ba70fd-d675-4f22-8dec-49302bf52c05/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021048210606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ae578869-d2ee-48ce-af03-d214e1dd17cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021050210747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9e2ec796-0ad6-4c1a-ab7a-3c46455efa9e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021050210839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4a4fb7d9-4fd9-4b8d-a395-9dbc27f385ad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021050210931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0fef6227-b927-40ce-914d-3cd380b2180e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021050211023_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e651e7a7-6f5f-477f-8aaf-b2941d5722d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021051202143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0030bfcf-7e2a-450c-bcf0-b95155625846/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021051202235_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c10489e9-f6d4-4c38-86a1-c50cbf4df99a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021053202343_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c3fc8a73-58b1-4013-9aa3-78d923fca2c4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021053202435_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e8581f07-e3e4-49af-990f-68bbb3e93fd9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021054193456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ba401ca8-f121-4ade-8263-91eedd87ded4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021054193548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e2645e63-acb5-4bf1-8a52-75534d5ccc21/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021054193640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5f09a00c-5d8c-44ea-beac-4f624c86adf8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021054193732_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/603c4c03-9e14-4a3b-b2ec-e16422f3c323/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021055184759_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6bf1ac5b-6e02-454f-a464-3411a45406d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021055184851_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c9526f03-7b50-48f9-b96c-5c0564475bc7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021055184943_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/bebb0a3b-b9cb-4aa5-a308-9b0e75b8b98c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021056180010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d1c56259-251a-40ca-9d1f-b5f796562457/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021057185119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0c8e3f22-d567-4210-ac5f-f290c317d4a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021058180154_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/20de131c-9d56-47ee-be30-b5e2357e99aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021058180246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/25ee69db-43ba-42b8-b796-82646d687f9b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021058180338_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ab6c6528-24a2-4d96-8044-07ec79b19e4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021058180430_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f20800e6-0eb5-4298-8cc8-4ad85781b417/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021059171357_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5bcc70e9-46b7-46ba-8467-cde96b33a296/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021059171449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e7971fa3-0e0f-448a-895c-8afaccc9e2fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021059171633_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/fcdf19c3-437d-4dbd-8151-b34ef84187f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021061171740_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/587bb1de-9de0-4e55-88b3-e79867dec3ea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021061171832_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/81e4aa3e-3dd5-45c3-8f17-07357dd4fe52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021062162853_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/53cb7d27-111a-4af2-b3f3-a7900e45a1f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021062163037_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f5257b95-30bf-42bc-b67e-9bc25c9d257a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021062163129_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/311a901d-6558-4b15-ab99-9396731a8865/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021063154241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/fc172089-0f0d-4ec6-aaa7-34984b5ff511/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021063154333_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7a7d44fb-3d6d-47c4-9a99-0821d07ff256/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021064145400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e8fe9105-fb56-4f6f-b7e2-902f47d177c9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021065154438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b98eda4f-e97c-45ee-a27b-635e76f22321/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021065154530_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/45df03fd-e92b-4d56-a4d1-0f44fcbadc39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021066145545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a2463190-e78d-4bfd-b859-2596b525312d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021066145637_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ae0b0044-c228-45a3-84cb-aaf14584be79/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021066145729_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6a6438fd-3e69-40ad-be24-8a058a5740f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021066145821_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/9972d8b6-4e1f-4e06-ae15-bfb3c5d4578f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021067141019_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a2521fb1-daa7-4647-b019-0ab2d614d2e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021084003939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/060363ba-6e06-43bb-8e23-0728ad87647a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021084004031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/8dec6012-82c9-4d5d-b093-7aa4185c65b5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021084235228_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/953ba483-78ef-4394-aa63-25e1fb2f7562/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021086004137_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f71cbcbc-fb60-4705-8a4f-a2c75d07a955/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021086004229_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f7203ad4-8f57-47a2-935f-3177082db963/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021086235419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1211933d-1526-45dd-be8c-79b37abd775b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021086235511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4c30f2a3-29cb-46c3-937e-fd3d92fcd31f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021087230652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/06abd59e-5b34-482c-b0f6-51674d6f14d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021087230744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ff6c8ae4-81c0-4b82-b658-a197113877a7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021088221941_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/45fa5651-7b4e-493d-9c07-39fed5a0c4c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021089213240_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a2a99416-2c24-4236-8d0d-1b7a0d1c6a69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021089230902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c23fcf21-13b9-4dca-8679-047114ecd1b6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021089230954_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/8bb9fadc-d952-48fd-96cb-80f56efdebdb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021090222132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a24f8d37-74ba-4b41-8285-0fc5edcc559a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021090222224_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/44ed10b2-2ada-40ef-891f-ed3ec2839262/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021091213401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1d390b8d-1d09-4fb0-91a4-2443a3abdd47/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021091213453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/514aa384-ce74-49f2-acd8-47a64404e28a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021092204651_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cc0432ef-2418-4ab0-9830-9d3407f4ed2e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021094204855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/078ef45d-d502-4afc-b6fa-e8afdab8fa7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021094204947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c060d0a0-04bd-4617-b29e-e076efef6d6f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021096191420_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/252d7f1e-2c9e-4a0b-98f1-0c367ac8c4cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021096191512_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c4bf0ca3-6db2-4dae-92dd-a4688f5b8e6e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021097182732_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/543d937c-a885-4f31-b19f-f19eaaff8ef1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021097200352_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/98a236b9-ffd4-4313-8d0a-590001c8bc31/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021097200444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/16d54962-64e5-4f7e-8d8d-488588e3215f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021099014610_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/73a4a933-40ed-4eec-b965-dbe2019f5aab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021099014702_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/dd2801ec-b0cd-4539-98ca-35eb52243ffc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021099182905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/823ff731-c8d8-4ca0-ab4f-af1956e339cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021099182957_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0b3a97cf-c311-45b2-a9f2-13542b0dfd11/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021103165635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6c5577d2-9675-4107-bbf2-5540d05c8f18/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021103232646_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cdaed3ce-fae2-4805-b050-b2f303951e9a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021104161012_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/3f12df13-7db8-4dd5-aa25-73f5968375f6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021105165851_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/3bdefd13-0430-433a-881b-9f45863508a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021105165943_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5f49fe85-abbd-43e3-8c51-1bf239646fe1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021105232949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/15b603b3-123b-4e7b-9964-7889d72fa949/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021105233041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/eb3ca316-6bf9-4e84-8521-aa877b500dc8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021105233133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2814ae65-f3ff-4794-92af-33025173557c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021106161127_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f9210163-4b5d-4768-a8d6-bf298e8de93c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021106161219_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/07445ffc-1780-412d-b833-2f9b87072de9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021106224056_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2caa9c21-ced6-44ce-bbbc-789e743700cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021106224148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/8d7ff47f-3a1e-4e9e-9db7-3f71cd7134ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021106224239_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b325a8ba-c662-41a7-81cd-ed38a35a5566/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021106224331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d50e0508-1849-475a-8a02-dab251cdd5be/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021106224423_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/62908274-b45b-4ddd-8b67-756fbb8955dd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021107152402_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b001b6ab-3146-40a1-9730-5b8798bdd6d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021107152454_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/05abb057-66fb-4f61-b435-a51390c03c29/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021108143647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6980f512-dd32-450d-b95b-828d9c3b6495/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021108143739_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2e5f29a3-8773-4b0c-80f6-5c657c711d4e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021109134950_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7d7cb4ea-5d52-4acf-8cb1-3f54fa44c3a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021109152618_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b4502879-3e12-4fd9-85c3-4f8a3c65e555/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021109152710_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/8a7731a2-9ff5-44bf-a2f4-61127748a852/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021109215623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/acf878b2-bec2-49ad-baec-5ba1fdecb7f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021109215715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/e999feda-72f8-463c-8793-9132a32cf4ed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021109215807_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b323623b-7876-4d50-b487-5d8df87dd37c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021109215859_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4fd6aa0d-74e5-4ac0-a930-aeb7fab8789d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021110143852_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b9f66b42-9d51-49ec-b2b5-647dcc7043ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021110143944_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/93e64d79-64ff-446f-b078-0b450a178dae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021110210915_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a0e2a96b-9504-4cd9-8e7f-4ce44827c71d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021110211007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/921b8914-d062-47e4-906a-4f2d8e150fad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021110211059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/85483e1a-2f00-43ee-9fd3-e68b98f79d2b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021110211151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d05d1c4f-0025-4e0e-a42e-83c83f8139ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021112130445_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c875e845-9aae-4b00-955c-3b24ad4a4a71/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021113135340_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/55af3d33-e249-4403-a53a-0c1f143e8754/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021113135432_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cac55678-8f95-4cf5-b71e-015b38ca3b20/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021113202343_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0d58483a-042c-4bcd-89c4-48d510431a11/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021113202435_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a843265e-5663-4889-a90b-b94f7132c4cd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021113202526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4b37ce62-c97a-4d02-a43a-b5a0db722124/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021113202618_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/09ee93c5-76e4-46ec-97ce-6a61049903d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021114193633_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d67de51c-68c0-4848-b396-342a64c0be4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021114193725_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/5f609033-dcf8-42da-9fc0-3620085cc6c4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021114193817_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/169628cb-8668-4fda-b79d-02699007f1de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021114193909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/ce2849ca-16e0-4575-8cb5-abead67d5949/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021117185101_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/92b19be5-202e-456e-ad35-ff0fde6e8aa4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021117185153_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b693212c-8fc4-4b20-b7c6-27fdaa140e2b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021117185245_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1dc1996d-6224-4922-8783-ce999e79e2b4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021117185337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cddfe097-3284-4e06-a925-0eeeb478239a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021118180257_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/6e39005d-86d7-4048-8268-906487b2dae8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021118180349_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7a35c8e9-c268-46f5-8d55-d57db01b86cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021118180441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/415e9048-9836-4bae-afc1-726b9a009947/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021118180533_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c57da2aa-0da8-4d14-b443-0e5aed20b11f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021118180625_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1eb79065-7f36-4a20-8f53-0dec0481c9f4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021119171606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/d48d8fde-c9e2-44cd-a861-608d9117f977/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021121171808_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a2ca3b04-6c2d-4b6d-8fa0-af784a076005/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021121171900_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/79b62705-77a8-463f-b25c-6556763ca2e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021121171952_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c96c2068-1da4-43fe-9052-526e7580287e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021121172044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/58233310-1c7d-451c-b453-34dd64e3b879/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021122163146_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/387558a9-ff19-43a5-9b0b-9115b8f676d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021122163238_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/408fbe12-4c65-42fb-b75a-6115c5780bfa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021122163330_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/a364c2bd-0aba-4a1a-b047-79b4fc8a535b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021125154508_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2a6d9e32-1118-4aff-a019-a8571edc09fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021125154600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/da34f207-271e-4242-84ad-2e8656d9feb4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021125154652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7689e3af-88ce-4051-828e-07e607da5e43/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021125154744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/89b9496d-c9b7-4008-b476-f2f45788dda5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021126145802_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/07a266a6-d137-41d1-bedc-75984ce821b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021126145946_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/592e3cd9-1a15-4299-81a3-ad8d9e2c1037/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021140021358_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/0d65228d-2f02-4b93-9e40-84ee4fe1be94/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021140021450_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/4f09411e-52e7-4c51-908e-7e3128c8dfde/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021141012649_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/96f0374a-4050-4fb1-a9de-0c836224dd7f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021141030330_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/420512c6-1369-4508-9b4d-79703c36df62/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021141030422_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/318c2120-11c5-49f1-9dc6-ef28dc2e7552/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021142021539_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/882c6b25-d6d3-4f26-8da0-6443674bb0ab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021142021631_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cf731562-14cb-4056-a34f-8a200d2d07d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021143012832_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/b0f6d531-b529-43eb-a8dd-2fb85443b06d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021144235412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/25500752-2063-413b-9daf-8c3e9e3f5e17/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021146004318_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/cf80c413-fef2-400c-a94a-15b9ce48ff0e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021146004410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/1a31e723-1e2c-4b51-a38d-f92b57f47f92/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021146235552_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/12b41889-156a-4f73-9afd-fa998e7fe615/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021146235644_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/167d3048-3102-4478-b7bf-48462764fbf2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021147230830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/2ea408ef-0eb1-4c1c-a611-3ea1893158c5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021147230922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/09681a05-bc4e-4d8f-8d5a-815235eaf5ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021148222128_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/67aeb4da-7d67-4070-ae77-6e398fd50798/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021149231034_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/f972f39c-fad8-46ab-b7fe-86efec23a79b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021149231126_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/c4884239-8da5-46de-8b5e-8d7173de59c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021150222305_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/25ecd76c-0a02-45d3-a017-9cee1e892e57/7218c9d5-1ffd-4f48-b1db-8f5f8e4f3bef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021150222357_aid0001.tif
EDSCEOF