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
    echo "https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/81047789-4d4d-421d-8259-0a3eb234b6e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019152232302_aid0001.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/81047789-4d4d-421d-8259-0a3eb234b6e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019152232302_aid0001.tif -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/81047789-4d4d-421d-8259-0a3eb234b6e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019152232302_aid0001.tif | tail -1)
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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8cab0e10-41a3-446b-8c96-9a29949b522d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021152204836_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5776e248-dc86-4968-a222-a272b90a23e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021152222520_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/51af801e-1b31-4b4a-8068-e8d777def632/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021152222612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b5d252af-1091-4d96-a873-fd8092b2f665/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021153213748_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3d3bccc8-4424-411f-bd77-ad18e63a8e62/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021153213840_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/bfd3e099-a4b5-458d-a052-4c7d8ee38fb5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021154205023_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b030118a-5253-471a-ac39-71c41bb6f8c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021155031951_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d2ad2003-c1f7-4693-af8c-3d3dddad7f9f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021155032043_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5ced24ec-d4a0-48a9-954e-7e23c3aeed44/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021155200301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5be73944-99ba-4b34-8dc6-9491121493d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021156191552_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1f402f46-fe5d-44b3-a245-df06e3f19e59/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021156205239_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e92ba4a1-e68f-4a7c-b9ed-a1265c3a36ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021156205331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/324833fa-9868-4422-8d3d-5e5b760c6b55/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021157200504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/009e65e0-bc53-4979-ba5d-e9704829d2ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021157200556_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5edc0ad2-3d37-4dbc-9664-963fc8f2d57a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021158023431_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/92419a63-b830-4281-87dd-71f2a4662f98/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021158023523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4415d380-847e-49b9-866f-446b576723e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021158023615_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b2e1a456-b0e1-4d45-8628-1c339c5538b3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021158023707_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b5a0f600-f9c6-4a61-aba9-0dfdc0f6f89a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021158191736_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/577ad2b9-3ba5-4ea3-a9c3-09bf35025178/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021159014705_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f35a6025-eac1-4d5c-8124-758056b9dad3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021159014757_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1f2e82a7-28d9-4d48-a5c8-a9c1013862a7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021159183014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e1db2f21-5413-442c-8517-543d71d016da/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021159183106_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6024de33-b3d5-4cad-9da9-e735f49a1c00/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021160174303_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/bd040488-eb0b-4161-8034-550452a9335a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021161183216_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d73a5571-cef7-47bb-b8ee-5f884de45ed6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021161183308_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b9bf102e-6e4b-41e1-9a65-d19022ce75d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021162174439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/90e41800-fb10-44cf-a9fc-44fb2b5913d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021163001456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0d2a31c1-094b-43f7-acf0-411bbf2a93e2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021163001548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8885e2de-ed0e-43fe-8ab7-cf2a1a8debe0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021163165722_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fb0c1db1-f97e-4a85-89aa-2290662a7950/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021163165813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1216034b-4865-4e51-a70c-7c385d960c99/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021164174658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/71864e0b-517a-4e85-b59d-d313498f1799/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021164174750_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d9aa8b79-76ae-413e-bcb2-abac584d0290/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021165165925_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d12a57b5-c976-4125-ac76-205cf08ed251/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021165170017_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/23fafc26-71e1-4968-aecc-6ac3a97818fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021165232846_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c80d2145-c90c-4d1c-a1c5-69612d4dccb4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021165232938_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4b7b8017-0344-4c4a-949a-46effb40cb0d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021166161146_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/bfbb613c-7dc9-4295-a757-4370aa079990/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021166161238_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/befd19bc-de8e-4824-81d0-68731cb27345/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021167152428_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/cac8488f-0b68-457f-adee-e6558ac3c998/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021167152520_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1a4b93ea-4226-495b-bb46-128660053dc0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021168161352_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/44523e7a-c2a4-406a-bf14-4e067a719b52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021168161444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/da719460-3dbd-44d5-829d-ee5b7d00da9a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021168224508_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d2ff7928-2798-43b4-8fa0-552cf8c370c9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021168224600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1dabb2fe-6c3e-42d6-bcee-e51eb11d8da8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021169215549_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8988ce83-e93c-44c0-b553-8d09c8526467/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021169215733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e4a216ba-9d74-42ce-9d48-8446022bc4b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021169215825_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a8e8ecbd-339b-4eaa-89b4-2bf1d023e9df/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021169215917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c661f734-0e0f-4cbf-9336-0197190c6696/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021170143851_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d36cb31c-b48f-4204-a9f8-d3abae0ebc14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021170143943_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6e3fafa0-d001-45e9-aaf2-86c991d00153/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021170210809_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5900bbb8-9de6-4a6a-ab42-a27992499a8f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021170210901_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/999d93de-1111-4e27-8363-1f3b9351c528/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021170210953_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/37348bb0-1247-41d5-8714-24a55bac88d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021171202154_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6e751a4d-b47f-47ea-8683-5e5b0ba22050/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021172130413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4940ab13-cac7-4592-b62f-08cab5a0c4b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021172144057_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/df078c36-53b5-4958-b72f-a6a3c95576d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021172144149_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/45239932-8e69-43ba-ba11-f98e7f53fe83/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021172211115_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7b2745ba-c3b8-41d2-b315-50a6e370d45f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021172211207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2903d540-2a5b-40e2-88fc-084df32e07d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021172211259_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b2f00f5b-eb51-4f93-9e53-ee50a70d5849/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021173135419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/613a653f-b350-44fb-95bd-eef298e9d03c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021173202250_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ceb9650f-1d59-4e8d-b200-f06bd3594899/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021173202342_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4ed9cb35-f108-48af-91aa-a4de76f9e859/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021173202434_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ef537a54-53a6-4c6d-8322-c2f8af3bd84b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021173202526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/21b16cba-ce7b-4117-95b3-7b18dc6add3a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021173202618_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fb34269c-4165-403d-aaae-bb97aa343b2b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021174130548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/691c6fc8-5e23-4739-a7a7-2a6e2e1b993e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021174130640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e9d4cb33-d819-44e2-9bb9-bd57dc421008/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021174193639_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2d48ad9c-b8cc-439c-9e92-9fc1b02af0c0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021175184841_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0a07d5c2-b461-48de-80e5-dd81dea161ca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021176130828_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/28757410-9e7e-4626-af39-b4b97d5d9b1e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021176130920_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5aff03cb-c673-4e1d-a16e-c4aa2751be7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021176193831_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e4d58055-4a5f-4665-8504-2e7c43f20bbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021176193923_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c729b98d-32bf-4658-a0ef-aeb9f5a005f0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021176194015_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fcc5332d-2769-4715-8651-de3fcdc276e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021176194107_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2c496ffd-e406-4b37-a1d4-54f20e6dd172/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021177185036_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/54a12c28-f58e-4d5c-b73a-008dd33baa33/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021177185128_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c1bdfd9b-d3d3-4dac-b3d5-5f09101483a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021177185220_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a8922c56-aa65-4fce-beda-a7ca413fadbb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021177185312_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3d7e69e2-d74f-4b39-8ccc-bbd3a31e8009/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021177185403_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/47c527ba-4c01-4895-b47b-cac4e2aaf3d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021178180313_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e53b8636-c0c5-4b96-99fa-41cf47d8a3f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021178180405_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/474eda4f-fe02-4305-a16b-27a6feff417e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021178180457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7e969a62-feb2-4d05-81a2-20bb7936f2aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021178180549_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ff229fd5-d32e-48bf-ba71-7bc9afa818a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021180180653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a36a3ce7-8374-4147-b729-0cbcb36e3822/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021180180745_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9e325963-3ba3-411b-a9c4-bf69471754af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021180180837_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9d537f0d-17c0-4a11-8957-a87b40a0634f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021181171855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c55d3597-1786-427d-b445-49c9d8e9fb7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021181171947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2c97647a-8bae-4442-9560-25dc9c683f3c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021181172039_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4932a5af-bd38-4da0-af85-0e8f88b5bca9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021181172131_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dc0da308-6623-46a8-88ec-7b99291a8afb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021183154420_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8f48a2cd-7574-4a2c-905a-57ab920dd43a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021183154512_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3ed24456-b453-4bc4-9e55-7e14ba15ee65/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021185154654_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1447c88d-478d-4e62-b5a0-49cff4f648dd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021185154746_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d7a41527-5882-4da0-92df-59dcdea0dccd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021185154838_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f1dec2d0-ead6-4bfe-ab89-c8b006b1599a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021186145916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/db1f6e15-aee6-4737-b5ba-061135514509/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021186150007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/90bc48ce-c9db-482d-bb6b-3935de6b59a3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021186150059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3b345743-d2d0-41b4-abab-11f4741f2d73/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021186150151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7d35cef1-ca00-4783-a298-3380b7519a5c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021187141258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/56d92071-ec2c-4388-bdb2-9a6bb37571c9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021188150321_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a3913206-8240-4a93-ab1c-2dc06c4fad17/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021188150413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a7ebaa8f-f7ad-4c4e-95d9-1f15a3536798/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021189141457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/df77f191-4ed7-4dfa-94fb-102dbb3258c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021189141549_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f5d6a5d1-d869-483c-b7de-811b77b94f93/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021189141641_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/62be6e94-c893-4570-ad4e-761787f1a6e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021189141733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5dcac8dc-01f2-493d-843d-552d7b333a4d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021190132714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/05c19b52-da4d-429f-bf9d-5c5651f6e459/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021190132806_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2111053d-42fa-4356-9f76-989d8a3e1024/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021190132857_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a402f08c-4a4c-4886-82ee-675247441c43/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021190132949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/82e6fed8-8fb8-49de-a9cc-984bdf88f9e2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021191124004_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2658016d-5b5b-4fde-ae96-487a0a385350/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021191124056_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/eaee9442-04c2-4db6-a180-318588fa1725/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021192133143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f0240731-f5ab-4937-adf5-d1e88d69714c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021199030531_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/162309ac-d331-4b5e-b176-8f06209ad00b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021200021758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0133b3eb-7b27-45fd-8841-7c844a6f8604/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021200021850_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e9a38071-d1d5-49bf-8a83-993cd3220dea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021201030813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3b625d45-f407-440a-a762-a7b3307c4b18/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021201030905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ed8f27e4-2af2-40de-894e-b878cb733fd9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021202022035_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7578e677-96e6-4b99-9076-82b497e41b6c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021202022127_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/327cbe93-c76d-486e-93a4-23acc42b35d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021203013317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/371ea75a-0438-4dc5-b953-1113ab65e9c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021203013409_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/235bbbb1-e058-4aeb-84b0-bc2786fe97a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021204004557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/32906d7c-7141-45af-a92b-7f3a1eff0d76/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021204004649_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e3343aaa-4583-4f9b-833b-e23402006e48/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021204022331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0dff5b86-46ab-44c1-b10f-f154f48e27ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021205013548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7e70681c-1339-46d3-8fd9-491364bf1055/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021205013640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/815f4289-0393-48d3-af2e-f357e98ae891/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021206004924_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b82f77ae-36a0-43a5-96fa-e4f7a02ca520/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021207000059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dfca8e56-c416-4447-adb2-0d9b430efb96/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021207000151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c1ff76c9-0072-49d9-b4ae-dc9d7e2eac98/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021207231327_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2934f6dc-3554-43f5-8a7d-bc4d5bc3322f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021207231419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6bd61506-a582-4ba9-8f23-1ed01fa88893/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021209000329_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fa7cb2bb-d15a-4ac7-a348-6d2c07b5a44b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021209000421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/89e5a3e1-b884-4274-ae76-3936d9a2b3ea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021209231548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d4d78812-35f2-47bb-8e94-5ed1e94ef3e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021209231640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/64faaffb-b8fd-4632-927a-f2e75a0d13ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021210222824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/075924f9-f00b-4a06-aeff-9391dd4c446d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021210222916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/665321a8-5116-4910-8604-ad75f55f0d66/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021212205418_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dbea6eea-8f87-4ed3-8208-402d1d252e40/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021212223059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fdc5a27d-2b37-4d03-8206-deefe536674a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021213214325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f00fce93-addc-4708-b3cf-56754c6bb110/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021213214417_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ed523352-43c2-4b8b-8b03-dc887253c9fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021214205549_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7048970a-fdb2-4210-b546-b33fcfefde04/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021214205641_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/913654c8-e03c-43df-b520-6bacd773b448/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021216192203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f604d74c-7258-49e2-a80d-c114a7601ec2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021216205823_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/54d1a38b-ca21-47db-bc7e-91b8c26c1347/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021216205915_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ed73427b-58ce-4b7a-9953-3d3cab1d316c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021217201103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6b9ff8c5-87db-4280-ab75-6af4a587241f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021217201155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6b4a1a01-ffd8-463d-bada-2f00907502b8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021218024051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2c885d43-99cf-4718-b2f9-60885430944a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021218024143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6ff2feec-f345-4ff8-b8d2-21965f60c4c9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021218024235_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ea948a06-cd9b-427a-9897-e4270aed50b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021218192326_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c4c99391-93c4-4d55-9290-fb219ed1d4be/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021218192418_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ea7fb9e0-1b04-443d-9e7e-afb2a4cc5ecc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021219183603_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2285f252-880c-4a7d-83c6-b1ff4a3b77c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021219183653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1ac600f5-2fc5-4362-86de-cc4979def4f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021219201342_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4243eb81-1e4f-4fdf-9551-948c0d1bbe1b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021220174943_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0c5b6bd4-5075-467f-9764-ff1d01805a83/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021220192601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e4cb98b8-83c1-45a6-bf7f-9d3544c758a2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021220192653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0f394127-ba91-4812-9694-686c3fbb0d82/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021221015619_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/62c0482d-3d9b-48ea-8681-c21255019a54/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021221015711_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/06bb92b6-5d58-4d0c-9ab4-309c05738013/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021221015803_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/947c3434-e217-4457-8f9d-129a8770bfce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021221183835_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/26d3b757-8e52-4b10-8d04-905db686b0eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021221183927_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/01081366-2b1e-4e62-b0bc-1bbd36f47bcf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021222010820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/168107c6-121e-4cef-92dc-eea7e877a7fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021222011004_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b22bab33-d390-4561-a9ad-44688a649b25/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021222175101_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7690f88e-b99d-4f1b-b221-ab312eea7120/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021222175153_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/46077e09-dd10-4102-8f6c-f77bc850154a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021223002115_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7dac3628-0195-4308-be8b-bde9099d0233/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021223002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/56974ce7-73d9-4933-b916-aac7b388e135/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021223170335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b1284887-c042-42ef-af7d-376b9f0d84cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021223170427_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0aa3b2f9-fb48-49d2-bcd2-865eeaa3cdf8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021223184114_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1069055b-7677-4ddd-92ec-192637519f62/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021224161659_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9f829748-0588-4d7c-ba0b-b0813d190b41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021224175331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ddb93ea7-4094-4ba7-a08c-afe3d3255fa2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021224175423_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3fdc3b6d-f3b5-4712-aa8a-ee76eb113e7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021225002345_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/34e4fadb-d364-482d-992b-a31ad45b54fd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021225002437_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2fb186c6-cdff-42c3-a417-db2854b2366c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021225002529_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8ff668b3-3c54-4728-998c-3d5aa01fa076/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021225170601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fba83ca2-90ef-4602-b6c5-db39bd4b3ad6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021225170653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f547517b-51e3-46e8-92db-dfd424c11cbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021225233638_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9cb2d806-12d6-4005-a273-f34b51e825d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021225233730_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/af61fba2-1d03-4f4f-a572-e5ae9febda2e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021225233822_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/14a91e65-d340-4d44-8059-62e79ef14b11/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021226161828_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/38ab451d-c714-4523-9f3c-55f57f2ed968/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021226224841_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ae379837-b6af-4d32-a14e-cd50a4484f29/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021226224933_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e872ea93-fa5a-432e-ad03-0ee7157cb92c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021228144431_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/20103c34-3769-4d67-8b38-39be8cb1947a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021228162147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0255d943-6a1e-44f1-a6a1-6ae1e4f0bbe1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021228225058_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5b1d6e26-fe6a-4984-84d5-0ccf7371bf76/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021228225150_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/abfb0bb0-e56d-425e-831e-c3a60aae7aa8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021228225242_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3e2ef42b-b07b-42b9-8a3b-46bf8d7b9b75/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021228225334_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/cf80b518-7e5b-452f-b68e-b88b6bcaa7f9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021229153337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/da5d4235-c2d0-4667-b202-c9aaa8d85ea7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021229153429_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2f0239a7-8b0b-4d97-8f48-80e014951e21/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021230144553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a23a59a0-337d-4b94-96c3-9db30eafc46f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021232144903_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d73fe967-c662-40b3-a5a0-34bc080e28de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021232211912_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d84c77e9-a4b3-4dac-aa7b-7e3977efea14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021234194416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/02eeefcd-e834-4ea3-80b0-b48af21773af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021234194508_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ae0b5254-c1db-4057-88ab-61dc29f05b53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021152204836_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ef50ca63-c3f2-486b-bb33-1f3e5656a965/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021152222520_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/401e12ea-739a-4622-8271-096ca179e501/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021152222612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4e3dde32-751d-448f-a5cc-1d1fd695fcc5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021153213748_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f5123877-d802-492f-811d-d733560c354f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021153213840_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dfbb19b9-8e1a-438e-a74f-70dc0067e0bd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021154205023_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/401f984e-7845-4e6c-aac4-e5ed45855ad2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021155031951_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ff7504dc-2458-4bf3-a37d-8ea7a5b78a36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021155032043_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/900ac331-d17a-451b-b08a-1b038f5faeaf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021155200301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/383c1619-d6dc-4af0-bac4-2b7a57f4ac41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021156191552_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f98ffe57-4340-4416-b496-b3c22bcb9f06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021156205239_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/39c01491-5a87-4467-a161-f18e32aab730/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021156205331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e8f1fc61-7292-4e0b-9c95-e8da6674cee0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021157200504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/885cac13-1783-48ad-9861-0d3df45624db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021157200556_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d07e8d52-bd8b-4153-8377-d021a9f12b2d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021158023431_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ae908ccd-894e-409f-abcd-44333f02712c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021158023523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/36b1049a-4915-402d-bedf-b0b4cb2c39e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021158023615_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b457a80f-526b-44fa-a187-4a9409ef3166/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021158023707_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ab8153ab-24d5-421c-80a2-8976d602b276/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021158191736_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/bdfdc0e9-f73b-47fb-8e89-4d327a204519/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021159014705_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d3628d14-a739-4c7b-9723-b58d2b3219ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021159014757_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/655c7f66-be82-448f-acca-8684daf48ddb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021159183014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7b5fa60e-5f57-45e9-af96-20c0ae835126/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021159183106_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5929a670-ac78-413e-af33-722639ea46af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021160174303_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/47a1f718-8a41-46b7-b9e0-d39dd9bc068b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021161183216_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6e574be7-d176-4642-8cc3-34aef7e2e3cd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021161183308_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b79a5648-aeef-473b-b960-c2ccac850583/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021162174439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2705c457-67f0-47cd-9467-1aa181a5d5b4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021163001456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6ed529b2-d1dc-4ef5-90a6-20d293ec4be6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021163001548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4c2e108c-0cf6-4ca5-970a-1e529c9b7027/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021163165722_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/56dc7ceb-4a8c-424b-a6c1-a60c11080edf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021163165813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4ee5133f-37d8-4097-89eb-fb903b270a71/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021164174658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/aa570459-5689-467b-97cb-8b70aef1317f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021164174750_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8db65d27-16aa-47a0-85d8-31889f124662/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021165165925_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4c87273e-7931-4593-a040-558da0c30010/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021165170017_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4486071e-efa9-479d-ae7b-7cbff0ed7e29/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021165232846_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/af9993af-13fc-462b-8a7e-f040e9d0fea8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021165232938_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f262e343-3b32-47d7-a6ad-7fbb1bbbf4e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021166161146_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/836fe1fd-569d-43a7-b7ee-653cf90f2b02/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021166161238_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/49e71bdb-73b5-4e71-8165-76a49f9b6f9e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021167152428_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7ebcfadb-60ca-49f1-a619-8265ddc8ea22/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021167152520_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/68b9e525-2431-4244-a2fd-0c3581260d69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021168161352_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fba4534a-3160-48c1-a334-74a9c02eb905/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021168161444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/26b84190-572f-4f9e-9c81-6a161a35eb3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021168224508_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/70e61a1a-3d76-40bb-8ce4-557f184c5d37/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021168224600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2509144f-2c10-4dc9-9232-383d5fb14020/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021169215549_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/10a3d9bf-0372-454f-94e9-9bfbba9ccbf5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021169215733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9a178d45-ef58-45da-9170-416a5c2ed960/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021169215825_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7cf7b52c-0e53-426b-867f-7b4f0a02bac1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021169215917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dbc8f906-5b25-4fab-acfc-eb78d997b3ab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021170143851_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1b3966cc-8e14-48f8-8adb-88e6770061fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021170143943_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ace70be2-575f-4d24-978f-0095d2abb16a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021170210809_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/23107c46-3e58-4728-8d8e-616da6a70e16/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021170210901_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7076bf0e-4bf6-4bb9-b62b-bcb461e64a34/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021170210953_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/14fe16ef-b1be-47f6-8b28-926760c5ecef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021171202154_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/489b2689-bf16-41be-b158-f77976d6db69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021172130413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c2b07f35-dd97-4da0-931f-444272fe1477/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021172144057_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b62ea496-6fc5-44e4-8725-baedf932b55f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021172144149_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9179546d-8f07-4e5a-a8e4-70810d89e130/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021172211115_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c28bba33-8590-4b29-bc6b-39bb6abb92a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021172211207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f3818e4e-b489-418d-baf0-f11da0069324/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021172211259_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2af2ab37-fd7b-471f-bf8f-a83674e32d28/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021173135419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/75bbd039-c9ff-40d3-a2e1-d3b8b43e549f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021173202250_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/74e4d82e-c949-4f2f-9116-738caab7b026/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021173202342_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fa22ea31-40d5-4277-b2af-3c9730d64a33/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021173202434_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a3bc90ff-1698-48c4-b845-273c7987463e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021173202526_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/154b88a1-f84d-4dcc-83cc-fa71028ecaba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021173202618_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7f9a8cdc-6916-461f-b43f-f68eb79cfc4b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021174130548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d8bb2e06-5fa7-4d56-9e7c-757941bf5224/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021174130640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f6a9ab33-93d7-4e83-b4f4-47ba6093cb94/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021174193639_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ed3eb5b4-1ec8-46ff-bd09-34cb114bdebd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021175184841_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9ec327a1-2eff-4e24-8fb8-cef32ca34d25/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021176130828_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c14cd65e-51b9-44f1-8560-5ff283a46bf1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021176130920_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/10c40bf2-5374-42fd-b3f1-de993c1c1df7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021176193831_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/e507d2cc-2b9a-4312-b489-f82dc12a5817/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021176193923_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a4655223-3bba-4f10-babd-efbd65bcda19/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021176194015_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9a557475-86a1-4ce5-b46b-028981fa0151/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021176194107_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dfebe465-e84e-40b8-9bf6-9ae16609b4ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021177185036_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8e18df24-9fc5-4d21-b1d0-da9dd23aa299/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021177185128_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/db27de13-a0a3-4760-8458-f8509fca119a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021177185220_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/27a57eca-5823-44f4-9ac0-ec6456e193c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021177185312_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/eb207a52-d942-4438-b29d-d0ad5f12f4e6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021177185403_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dc44f25f-8748-4b1d-9d92-8b5f12572081/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021178180313_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0b6eaee8-45d0-4313-8ba3-83af0318d836/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021178180405_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3b753152-6041-4b05-a268-4f2c1b4401f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021178180457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2ec6296f-4440-4fe4-82f9-12637a1d3595/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021178180549_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/adca8d07-6885-4da0-a32c-ac4022f7aa95/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021180180653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dc509383-c430-46d1-8ce4-1c18f3a15a99/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021180180745_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/42711562-3778-4c0c-8436-60f9166d38ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021180180837_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d6a62e2f-af4d-422a-8866-66066292b5ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021181171855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c8f808f5-3293-46e8-83d3-0e4e697564eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021181171947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/bbd4cbc3-98dd-47a5-b1b5-d1c509877d4d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021181172039_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1278d8e2-6f15-43c6-aa38-69f054393138/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021181172131_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/19688eda-4f2a-41ea-81ee-51017a99f129/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021183154420_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/447c4daa-6954-4cde-98c4-c2400824735d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021183154512_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b343b5bf-e136-46bf-8e10-09bba0bb3c30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021185154654_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fb4af91d-66d0-45f1-ab07-714aefcb6358/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021185154746_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2187bbe2-2db0-4c9a-b59a-4a09a644ac96/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021185154838_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/bba55097-5f92-4f8b-a74b-c387134e9370/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021186145916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fee7fdd7-5499-46c7-9d65-d379ddf25436/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021186150007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/72748b5e-fa10-4253-9e28-01f11c45e7c4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021186150059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4a57d9c1-370a-41e8-8987-518027e4f28b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021186150151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/07c6e69a-d634-4d18-89bc-24e20408df5f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021187141258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/bdb0fb65-19df-4855-91f9-03efdd4abc45/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021188150321_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3bf6dbf2-71e4-462f-995c-5855a85af78c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021188150413_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c2e8b466-b8d8-4228-9ebb-101fab641f58/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021189141457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fedfa60c-35fe-4d79-836f-473af8000525/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021189141549_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/03926777-193d-4d92-b234-f6c474007d7c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021189141641_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6139b638-446d-4701-936b-e8815f0118c0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021189141733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8c92da20-7d07-4da1-a32c-7682eee79fc3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021190132714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1a2ad6c3-9f75-4325-bbc2-bfd37a7f5a46/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021190132806_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/763d84f2-928b-4026-91f7-751ad00c5b30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021190132857_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b5e6b0dc-3b40-4543-bd2f-9a18677131de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021190132949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/89522356-8b13-4c96-a6d1-da8f437045b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021191124056_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/67d36410-de88-4f06-b329-ee0bcb7ad871/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021192133143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/29ac7ce3-dfbd-44dc-9a96-82cced30731a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021199030531_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/708c3a07-80d8-43a2-9021-ebed791be614/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021200021758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d66bd88b-0180-4324-b15e-98fd93c03ee5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021200021850_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/10cb8806-76ab-4620-abbe-b97d2e6f2633/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021201030813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/54c4ea86-cc2d-4801-8320-de951e444783/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021201030905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b4fbb547-a85e-4404-813a-e2551b06506f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021202022035_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a614d8cd-5a16-40a3-9fc6-b3afcab77dea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021202022127_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9384221d-f919-498e-8e3a-fd7c1d259afe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021203013317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b8af2081-01cd-4bb6-92cd-91edcd74a072/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021203013409_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/43921e03-5213-4b92-8de7-db5154ebeb94/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021204004557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9404b847-8212-413e-aaaf-b854c5dccc41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021204004649_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/933ada79-ffbe-457a-8345-2ece11c2253b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021204022331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4edd2139-eb93-41d0-9173-4513e1d679d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021205013548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9cc38989-c924-4b56-9c38-ca16c3599d99/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021205013640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/45cf6f8d-d1d8-4e3a-a02c-b05f75e0e777/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021206004924_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c94693d7-793b-42b6-8dfb-c32d0260301a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021207000059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c83746b1-4d1e-4415-9388-78b957c35233/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021207000151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dd01c316-bb69-4e65-a53a-481eb21dba52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021207231327_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9ec78896-e2dd-4e4b-b0e4-82dfc45d92d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021207231419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1fc7bea2-cff1-45db-b862-0ef9b09bc1e6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021209000329_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/60c1dcd4-46b5-412f-a37e-c55051bf4fba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021209000421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/245efcdd-67ac-4d35-8eb2-1a1affe39e90/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021209231548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/061b3234-c0c9-411c-ab3f-3dd8dd00075b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021209231640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3337dd18-ffb7-4cf4-8b1d-fcfe957f7b43/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021210222824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/7f80530f-2281-4963-a831-2c99e8da2543/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021210222916_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8da93ec2-1b5f-466a-ba95-9a28dced3a12/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021212205418_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fe65b2c8-8dc5-40da-aadd-4f2f44271737/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021212223059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c86be38b-5083-4276-abde-2a720818c5e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021213214325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9c601779-cb9d-47f3-ba3f-afe54e91c8bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021213214417_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/065c69ed-f38b-4ec8-8956-5df807373355/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021214205549_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b470c80d-15a6-48e2-a72a-ce84bc670bb9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021214205641_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0aa059c2-9504-49b9-968b-f145fccabc96/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021216205823_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/50e4a659-5074-4bce-ae20-dedbc1fe5a7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021216205915_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9605696c-9c4d-476a-8a90-fb410099ef41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021217201103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1be1adeb-beb1-4cf7-b753-462c3fcdd924/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021217201155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8b9afaf4-51c9-41d1-97ff-e64850de32ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021218024051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/1f88398c-001b-4b6c-af3f-2b11c22af69d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021218024143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/15f6cd5c-9242-47cf-93ab-ea7b7cfb7113/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021218024235_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/0d6c65f0-dc3a-4d37-9d15-71a7fa973be3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021218192326_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/77ed584c-70e2-4e73-ad42-27806b790d00/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021218192418_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/fa73b6cb-a15d-421f-bd00-2216d3a4b799/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021219183603_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/dd14f025-902e-4ec0-913b-001b138a54ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021219183653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b6aee200-a907-4b1f-8ed8-1db98b11ee81/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021219201342_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/9039cffd-1601-4f6f-a7ac-d1d75bc73865/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021220174943_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/2f33ffbe-057e-45a4-b70c-2d3c837f7ce3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021220192601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/468698e1-6d29-43bd-a14c-9e6c478f2394/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021220192653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a40ef89a-e8ec-4d09-8520-e57ea846da60/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021221015619_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/14a33405-e149-4bf7-9703-c355f19b4b04/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021221015711_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f6b9b496-c0c8-490c-90b9-3d8cf69e6e45/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021221015803_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b793de2c-98f0-4f0a-bbe4-5701189adcd4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021221183835_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/959ec4cd-3fb0-4b30-b1ad-14d72f2bb9f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021221183927_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/430a846b-0a6b-485e-85e3-68880bef4e27/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021222010820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/a539d39a-8351-47c5-9fb7-43631aa08139/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021222011004_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/48ee47e4-96f8-41f9-9454-ded6dfd2f05a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021222175101_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/cbeee55b-da45-4172-a68b-8ae36938c35f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021222175153_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ce0f04d9-6b75-4ad7-b07e-e51bcf8b9bcd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021223002115_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/c1825031-38eb-404b-8563-44945470de2d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021223002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/52656999-3ba0-4ce6-a7fa-8e81385495d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021223170335_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/eca59402-cdbf-4e30-b471-47b9d94d7e38/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021223170427_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/46858e7e-de67-4cc4-8fbe-c544a3b93cd8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021223184114_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/96c1fd67-7e70-4c6d-8e71-254f24a3fc22/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021224161659_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d8d2461c-1564-4851-8479-d13c94ad62ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021224175331_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/bd4be6c1-3c22-4d7b-880a-4515a3fd588b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021224175423_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6064fdf3-c824-4fba-86e8-1fae9d51307c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021225002345_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b4e53da4-a82e-4ad0-a8ec-976fc53964b8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021225002437_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/57f8d95b-330b-4931-892b-bb35c3fe248d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021225002529_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/63df2227-de1c-471e-85e2-a48c0cfa44b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021225170601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/8526bcf1-8fec-4050-bf9d-7c14aafc8d7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021225170653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/4461d9e6-d94b-4a22-8fc5-86d0a66ae361/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021225233638_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6d6522bf-d151-497a-89b7-5bf78f21ab2f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021225233730_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/ca6f3b5c-60d6-4e13-969f-e13a3925948f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021225233822_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/3ee39c93-7eda-4c7e-8813-6c8676e563f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021226161828_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/296180bd-5997-49e6-9681-853f41ed32ca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021226224841_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/f3951075-bddc-4900-8a91-04002dfe1cd5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021226224933_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b347931b-1ee5-4402-8446-ed2c5e28a5fa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021228144431_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/086aebe2-fa79-4f23-92ed-a4250849cef7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021228162147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/b14c6be5-2ea7-44df-a6fa-aaec3d183a0f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021228225058_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/60bdecb2-d5a3-4f31-9083-95607674d33a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021228225150_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/51ddf943-2939-4c4e-81f7-b029083ffb3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021228225242_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/6ab51de0-500b-45ac-8015-6d52e5903b88/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021228225334_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/97f7ae03-921c-4f1c-92bc-2ac1a50a75a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021229153337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/682bec2f-3261-426d-97dc-9074ef4a0f5a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021229153429_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5c1b315f-965c-4032-b76c-91899d733050/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021230144553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/d39d396b-24b3-4f01-8a97-4f14580b468a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021232144903_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/890cba4a-c03b-4693-b432-b2a36eca8ab7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021232211912_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/26f247a7-17b9-4404-b758-7e2ff899863c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021234194416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/f5d416cd-2c44-46a2-971a-e8b22d9d828e/5cba443a-0006-421a-9494-98ba4d9f2acf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021234194508_aid0001.tif
EDSCEOF