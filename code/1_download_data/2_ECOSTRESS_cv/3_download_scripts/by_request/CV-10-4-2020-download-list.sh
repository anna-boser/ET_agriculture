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
    echo "https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ac6ba3aa-50c8-46d9-989c-8c44e75ea157/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020290230236_aid0001.tif"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ac6ba3aa-50c8-46d9-989c-8c44e75ea157/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020290230236_aid0001.tif -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ac6ba3aa-50c8-46d9-989c-8c44e75ea157/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020290230236_aid0001.tif | tail -1)
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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ac6ba3aa-50c8-46d9-989c-8c44e75ea157/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020290230236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/73e369f8-83e9-487c-925c-19e89c190629/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020290230328_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e5ac1cd8-1df3-406b-aefe-003696b776c5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020290230421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/afd17259-eb78-4ac3-9f1f-ba9f93b86302/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020291154448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9fc96fcf-6435-4006-81ad-24533bb71e5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020291221504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/99d019c5-48e0-4593-b7a9-6f734eabc15e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020294212919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b65ca3a8-ae20-4b9b-8c6b-23b49256fbc6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020294213011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2446a27a-e6c4-4cc9-b245-28114b05daf0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020295204158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/428b5a06-0510-42a4-be81-8cbbab056f2f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020298195414_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9b3ceeca-6ded-4479-b81e-50e8393c16c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020298195506_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a87ed1d6-fcaf-4c32-a2c5-93a04d32b4f8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020298195558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/36777861-a659-4e60-94b1-6be929c712f9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020299190600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/fa63a064-e2c5-484c-861a-8a11613bb620/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020299190652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/76c2faa3-1ce0-44d5-b6f0-a85913ae5ec3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020299190744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e7e9a470-e388-48af-ba64-20842f349fe2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020302182051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/968a016c-a03c-47be-90e8-523179995a7c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020302182143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c35eea17-e183-465d-86e5-07d9bcab6936/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020303173142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/17401ed5-3fc8-4f85-bc8e-967f9f1b65f9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020303173234_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/fd88d9b9-324d-4096-876d-90d2344dc35d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020306164537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/f52d1161-2f75-443a-859c-d3aee4a54a3a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020306164629_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/05f1b7fd-4df2-4291-974d-2502d2a9e591/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020306164721_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a6bfe9c2-a5c0-4ba4-9bb5-60edcd5b8245/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020307155800_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/20f468c1-fcbc-4e74-8706-09910959b065/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020307155852_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/6ab7c179-0e20-49de-8d8b-39f949c37141/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020310151203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/57da230b-353e-4ede-a1e2-9bce67c0e4af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020310151255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d0de4e3a-5c1c-4c98-bd5d-d2c5f0a2928c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020331000509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/84e45fd1-3807-4fc7-84dc-52a4c95230d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020331000601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3c0adaff-d1ce-4ae1-adb0-cc1208cac06f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020331231758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9807efc9-3e45-426d-9723-400009f4969c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020333231936_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c89656e4-5ac5-42b4-b615-4c187693b095/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020334223201_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/36eb54e6-2561-4f56-bc08-bcb0b3e0d17f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020334223253_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/09e89a0c-1886-4735-a044-c5a53a117a46/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020335214441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/50623c09-ead9-494b-acc4-5a2af0c6f09a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020343183734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e898673e-a9e2-4f13-8c50-5cb2836e2140/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020349233528_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3f2db4ee-cfca-4db7-be72-af43602beee1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020349233620_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/03ade0d1-8d7a-46c2-88eb-75be6607d50e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020349233712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/bc3d1a1a-d5f1-44e5-8f8b-02d684ec9e13/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020350224820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9d8ff34b-a456-4f20-9f28-4264168b06fe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020353220147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b38ed59b-571a-4a1e-823a-304bb837ada7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020354211438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/f008741e-8d5f-465c-ad0c-28e7a540f452/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020357202946_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d4aba771-726c-49d3-a3dc-9e0281ab40db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020358194052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e17a5bc0-876a-4abd-8ec2-c405626ec3f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020361185412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d5d1400d-fe25-4953-b052-1c80756663d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020361185504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a1a16ad9-bff0-448c-9caa-b37815dbdc03/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2020365172020_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/08714c64-f542-4da0-a9ae-81b99d741b32/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021003154626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/03d6bea5-fa4f-424d-8fa4-fea634bc14ae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021003154718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b5f95915-56de-44c2-86ce-2da389c6e342/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021024003929_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/fc1ac011-bea4-48a6-97da-d30df1f33052/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021024235211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/60f03731-d006-49c0-a560-76fc4241e640/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021035200132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/be18222a-9409-4b5e-93fb-148c443b6cd9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021036191410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8f84afb3-4f48-474a-a611-e35a581732e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021038191616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/6b075d63-53c2-4ddc-8141-2b46c4b5836b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021039182847_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2cbd2c39-db01-4d0f-b1cf-fc4b8e212e67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021040174124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/95a45c6d-c95b-441d-8b03-c0acfa814754/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021043165609_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8d4e35b6-7a33-409e-b978-a936918d052b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021043232635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/bae9b2df-722d-479e-b9ad-01fbc1672671/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021046224044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8ba56369-88c8-468f-81bf-673740de40a9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021046224136_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e7194d13-d01e-4f6d-b534-56e4d6eec1aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021047152321_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/f43ee2a7-3372-4d70-9687-f44e345b469a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021047215256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9f697585-4d80-4a77-8413-1566f8d2bf0b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021047215348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/49e38c8c-654b-460d-9eb7-14d7b0eaf105/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021050210747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b72fc0b9-c5b8-4cad-9bbb-8d9fb2d4aa66/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021050210839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/701c2215-1e4c-4a19-804f-efe0db250fc4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021050210931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/dda179e2-aae8-44ca-b0b8-356ab63f4ea1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021054193456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/945857dd-5d49-4ab0-aa31-cc51f9ab30b0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021054193548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/33f3b943-5cd1-42f9-acc1-887173477827/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021054193640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/66bec751-401f-4ab3-a2d7-c6b85a15099f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021055184759_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b74e65c8-bcf4-4ef2-bd4f-e0cd5f31dc00/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021058180154_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/10b808e8-9042-42a6-baf3-720f72c23679/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021058180246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/1fa98e81-1da9-4bfb-af0a-1bc29249da87/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021058180338_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/73ebdbab-d489-427f-8a78-288208b44031/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021059171449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7d2bedbd-1c5e-4356-a30d-1b4b418a00f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021062162853_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9e9b3762-5db5-4973-8216-7b9483540192/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021066145545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/6b13c8da-4fb9-4517-8701-a8d75c0ab787/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021084003939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/694c90df-d39d-4933-b9ea-d6d5765471ae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021086004137_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/722383d0-82cf-4c39-99f0-ea403fad9bda/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021086235419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/09e2a5c5-2620-4c7b-a91b-dc1ad4901454/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021087230652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/344eb1fa-e662-476a-ac7d-38afe8f8c29a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021089230902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/abddff0e-f340-4705-9386-d1e049ea42c3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021090222132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e4d7dde0-b612-4686-8899-9c410b07cebc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021091213401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/6acab23a-9692-4eeb-8c1c-153d2b8c9e38/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021094204855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d0964223-300d-4ec3-8510-f586f20d9e57/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021097200352_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/26d15f68-358c-49d6-a8af-1f62ed12a060/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021099182905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/6213099b-d41b-4130-ad37-ccc10b2e77a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETcanopy_doy2021103165635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7ffcda9c-f46e-477f-8b9d-86bcaa766bc5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020290230236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/96dc7369-646c-435c-b2e4-8a74564086df/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020290230328_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/54eed173-af25-4c6d-bb03-3000378822f9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020290230421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/5a041c2c-7289-4bce-9f51-dbd26ca02711/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020291154448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0a9e7591-5e3b-44b4-884d-acf7fe407935/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020291221504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ddbc9709-0dc1-4916-b3be-7efd83b5a99f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020294212919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2393ffbb-4239-4b49-8cbe-599bf009841d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020294213011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2347efa5-58ee-4385-bd42-c54c080b9c06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020295204158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/5789646a-7a11-4b71-b90c-c9e20313bfae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020298195414_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8a6e4157-eaea-424f-9acf-897ce5298b22/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020298195506_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/98fcde18-f2fe-48bd-be3f-66382ffeb1eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020298195558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3b74af0d-642a-42c5-a1d8-6347d7bccffb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020299190600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c81f304e-a8cd-429e-ad80-9c511afbacf1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020299190652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/5f01b4ad-7f4a-44ea-953b-536136f47acd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020299190744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/092fc5bf-725c-4730-9719-22a8b259668d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020302182051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9a8964e7-0564-4d04-a19b-629c0833dfc0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020302182143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/5a51aa98-4870-468f-81ea-ebfec8b315e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020303173142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/caeddadd-e8ce-4a08-ae63-28ba7996abf4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020303173234_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/992f0579-be5e-4939-9076-205d8df90ccb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020306164537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/be895e2c-a209-4a30-8fc9-7e1a6a9943d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020306164629_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/85dab604-f8b8-4d84-b296-519c16cd5e53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020306164721_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/82296aaf-d46d-4051-9234-07d5d670fb60/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020307155800_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3320445b-3994-49f4-b8d8-2669a44004ca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020307155852_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c4902bee-61ff-4b4c-9bf4-050e2331c643/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020310151203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ec936f04-e37f-4b22-90a8-a23cc0b17021/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020310151255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b56666fd-5f87-431f-ab2f-00f7f220f4ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020331000509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7c4d54db-004c-4fd9-94b9-6e6466a811a0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020331000601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/393727f7-b518-46f5-8234-e31f89fc0831/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020331231758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/dd5edf86-0ee4-4423-8b10-1601ec81d43a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020333231936_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e59c1204-b315-4f5e-a258-3927690fe165/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020334223201_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/71c218bd-f847-4e68-965f-e0a16844db75/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020334223253_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/25a75a11-e0b2-449c-9329-67a389380bae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020335214441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/4b2bafc1-d1b7-453c-bfe2-0a85c34e2e99/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020343183734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/01d85b6f-ff9d-4319-b102-6b0854a6dd79/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020349233528_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e397a590-1fd9-4739-b275-ddfd73a0489d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020349233620_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d3ac8e3c-fb98-44bd-b4c5-4fdf330b1635/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020349233712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2fc0a4b4-fd1e-4c8f-a69a-c5508e4f3559/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020350224820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a1c1d3e0-ddc6-40d3-8bac-1045be2af98d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020353220147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e1b2addd-0460-4215-bb8e-2348dd9a2edf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020354211438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/08cdd925-7571-420b-8acf-a9ce5fd1c4c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020357202946_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e349437e-d093-4541-b52e-cf6cc73d3b3c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020358194052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8cd676c9-a2d3-47dd-82fa-3b32cf28fe76/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020361185412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/cbea3933-0b7a-494c-8b3d-60c431002f4f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020361185504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/6887ceb3-385f-4bd2-b34c-f2c0dc6de4c3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020365172020_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0b32fd03-bfdf-4060-9a5a-cd961ddaa8dc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021003154626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/35fdd603-1cd9-46fc-8932-634520decb5b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021003154718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7f0a23f8-4f96-4a68-8e6c-70774999f16b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021024003929_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7eda6470-cb9d-455b-a9a2-1be4a7dbbbd3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021024235211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e94adc76-4c23-4d6b-9b13-9ae1a5d9bc5e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021035200132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3a4f7ac8-0223-4157-af46-282352a9d0ad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021036191410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/aeb1276a-ee2e-416c-b9da-60244914a83c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021038191616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d3366964-62fb-4c00-be20-13a0ecba542d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021039182847_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7edb223d-4c66-408e-b33c-dd0bad294ad6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021040174124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/dc84b0c2-7dc6-40c4-a7a5-5a1e6aead3f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021043165609_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9ecd9f93-4dc3-4306-9e1e-b90bae867aaa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021043232635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c2a45f13-d1ea-4774-a795-2e90bdd7b44d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021046224044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e5b99c7a-7e99-4ec3-aadf-112b643ddb18/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021046224136_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/67ee8627-66d2-48b9-a110-28a61c611597/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021047152321_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/aafeedb5-7af5-4970-89dd-c2f0c77313a9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021047215256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/11c30c28-4c90-43a9-9b2c-e0a820e1a92a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021047215348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/328d513a-c61d-48bf-8b2e-de89f2effd39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021050210747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d16600bb-9d7c-4e22-92cf-4938353ebe32/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021050210839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/01b97ba5-201b-452a-93e1-2eb397eff3d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021050210931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8d19059c-6937-47b4-8b24-17f1e9a4931e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021054193456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/be5913c5-f31b-48ce-a4f0-f342eb691173/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021054193548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/baf36c2b-6039-497f-b80b-acefb678c92d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021054193640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/46f7c680-f0b0-447e-9350-b6ecfab0571c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021055184759_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7fe8c8e8-ad01-4a3e-a2bf-3a56e29e67f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021058180154_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/4ec85bd0-56e0-4178-82fe-2b3f5eb82b09/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021058180246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/062f9775-0c49-49ef-a01c-4355ca38bb70/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021058180338_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/89efeb7a-0183-4fba-803a-e471d630e2ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021059171449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3b257a46-b325-4ee2-a067-3952470e4995/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021062162853_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/82b560fc-5350-45fa-874d-a94047093be9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021066145545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/03ce5733-6b0e-44f1-bdea-1f537ef4bfb6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021084003939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/1120201f-ed18-4e24-a158-60c565dc7564/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021086004137_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a60fa1ee-81ef-48a1-b89f-83662cb96d32/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021086235419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/bf2a24f1-b393-4408-bee7-af59118e5db7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021087230652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/eecf66a0-3007-4751-9c37-6da0cfda0672/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021089230902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/5c7d77e3-2251-4cde-a521-a463eb46c440/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021090222132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/74da1a8f-d03f-46d5-b29d-da0a7be3d5a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021091213401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/68421ecd-a498-4a9f-80ec-d2fe66d8f9cc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021094204855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0fa53d45-d29a-4a8f-bf24-0ff4010b6600/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021097200352_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2ca541f2-b6e5-4f26-a248-fba953d02f0a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021099182905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a835b509-6f99-4e4b-b625-97abcc2e6fec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2021103165635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/74365d53-01df-41c2-852e-d9009342e0ae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020290230236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b357a3f5-88f8-4c72-a3be-46a08e9744b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020290230328_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/68bc1e06-8b16-49b5-b0f3-d469ed836cde/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020290230421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c6c78db2-ca99-4be5-94ba-6bb347ff4713/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020291154448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/cbfdb444-ded5-4e3f-99e4-0bdde1fb10ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020291221504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e3239111-308a-4a89-b287-3612601b9e1c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020294212919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b6361cde-c64b-40d2-8cce-a0c0f2db8d42/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020294213011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/06932fed-1132-4aca-9b30-7a0124a9490b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020295204158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/1f1124cb-e4bc-427c-bc08-1ce5e9e9db4d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020298195414_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/598c42f5-cbbc-49a1-87ed-fdb816463287/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020298195506_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/54b3c257-caca-4e79-ad08-ff92412d3654/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020298195558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3510f4e6-4aff-485b-a445-951d2df72538/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020299190600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9778e5c9-6528-4299-8f45-0d4a8e352100/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020299190652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/16dc762e-6b01-40f0-9fa5-504caea77fb4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020299190744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9b1d91aa-8fd9-480b-94eb-617fbd47d759/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020302182051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/f937c889-1026-46c0-82d0-1585c6c498c0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020302182143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/f67e79b9-5b6c-448f-920e-ac71bd417077/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020303173142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a21b2faa-fb24-4f60-bdcc-f95b0a2ee63a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020303173234_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0c8ef229-d2e3-4d30-94b8-761f6efcd19c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020306164537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e319aeda-88bb-4d79-b7c7-bd6af60cf235/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020306164629_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/92b96123-6d64-4328-b470-31819d2a198e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020306164721_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/24d55a92-eb34-40b8-a47b-8e73c984969c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020307155800_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2c130072-51fe-4c84-86a4-d09f3231bf5f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020307155852_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d7f3eaf9-cb61-498a-b7f0-7a42c1a4d71d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020310151203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7fc1f78a-7161-4568-b22b-0fd3f1c03a2d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020310151255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/483b03ce-af13-4855-b4ea-a2f7e2a26949/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020331000509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/6ec9407a-29e5-4e52-89fd-35dfd66d3321/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020331000601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/678c3fb4-7c92-4249-92c3-b8d4ad6b5f58/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020331231758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/503fddbe-9d32-4a9a-b68c-9c4c0c7ef2e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020333231936_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/06ebebf3-c344-4c36-b623-a4ac284960e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020334223201_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/41ea04e8-1ce6-48cd-b505-17d910e78ff9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020334223253_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/52c96236-f425-4cd0-8c50-643430bbf43c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020335214441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/00f47369-12b5-44ca-b691-dff38f173ca3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020343183734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/1cc14a24-ad36-4940-92cf-6593a450a6c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020349233528_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/80c3cb85-7004-4e8e-8bbb-ec8efc8628f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020349233620_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a4deb0f4-d837-4bcf-9b43-154700fc2d17/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020349233712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b27e3b05-6791-4133-b519-8080d30c5498/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020350224820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7075dd69-d8b1-447e-b916-7db76a8ad822/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020353220147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/188dca41-7900-49a8-b336-396170831229/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020354211438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/73d7197c-613d-450d-a6d5-7316b892c30c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020357202946_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/f0d438dc-15f7-4b89-9560-e678fcc21f7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020358194052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ae868d8d-63a3-41a1-832a-3fffd972c494/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020361185412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/25016bcc-7b18-4493-b81c-9d0ffb02ce5a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020361185504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d33b9bff-2f91-454a-96df-593d71494e78/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020365172020_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/814dc213-361c-47a2-851d-878396cf6f32/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021003154718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a2a335b8-85cd-4a0f-84e2-2c5ddb0d0dab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021024003929_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/bd9c0e20-b53d-4f6c-9422-02756a60dfbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021024235211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7947f5e4-e5e7-4d45-bda3-15646b96c8c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021035200132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/77d8ce1e-8060-4409-b867-ad2e2be191de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021036191410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/256272ae-f703-4195-8f6b-35d623d54ee3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021038191616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/19f23e99-3862-481c-960c-674908775c89/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021039182847_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/89352bc6-77c1-413a-96b5-cff40f1f0690/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021040174124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/bc523553-f0f0-4f4d-a18d-f1ddc1445acc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021043165609_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/5f31d327-c9d9-4bca-a5d0-f16361da0827/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021043232635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/09c1efcf-0b60-44a9-b0b4-e5e1447efda8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021046224044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/64ebffcb-c0c4-431b-88e8-fda2fd312c8f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021046224136_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/33a155d8-a961-4cf0-a7bc-3f72133488e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021047152321_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/81db424e-bf98-4278-9b0e-e436564b589f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021047215256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9f458977-2f3c-4445-8356-1b6f71917799/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021047215348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/31eaaaee-9969-4d6b-a0a4-c846a06c3eeb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021050210747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9627fd55-a739-4f6f-814b-937ac7e62e4c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021050210839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/fa87b338-a2fe-48a4-a4dd-f9e9bc0f5202/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021050210931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/dceeb4be-8758-43c5-8f00-4a6c6887fc2f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021054193456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/f33e3cc3-1866-4866-9ada-d1875b21767a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021054193548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/5ff91998-8b80-41d0-a80d-92050a68c42a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021054193640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/f8d99ca7-9472-4998-b030-5b5117c298b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021055184759_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/815e72a2-df08-4e07-b295-e1abf9930864/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021058180154_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3fb27a06-291e-47da-97f5-03a89ede7d1b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021058180246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/76a4425b-410a-491a-9210-341ff695ab57/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021058180338_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d4423301-b30d-4c84-ace9-66b7dc431345/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021059171449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ff8f0d5c-cb73-4f42-ac28-8ec5658655a9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021062162853_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/cf961caa-8d92-4d54-b621-fdf8927f884b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021066145545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/28a8d1a6-c22c-4055-b615-c2148206a163/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021084003939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/90e5f408-f824-48a4-839b-047725506355/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021086004137_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/4c6a91eb-16a8-4f90-9b9e-5941ea93ad6e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021086235419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/fef55244-31e8-4809-8f1f-be4a6dd76b53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021087230652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b0139682-7969-4b97-9e46-172876419b79/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021089230902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a3a22b40-b534-4a34-950e-6f6d6c7824a3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021090222132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/243282b5-f30e-496e-a161-ecb240c3fde2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021091213401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/fddae885-ca4e-4acb-9062-608187c6689f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021094204855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ed5da7c5-4d59-44cb-b5e0-d7f6c7932f8b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021097200352_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2c671bee-ef69-4b54-8288-10ff300b3c36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021099182905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/97f8de69-d29d-46b7-98f9-abef272c00fd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2021103165635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/ea8ede5a-6d2a-4f8d-ab8c-056a2e0d888d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020290230236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/88d94f65-b230-45af-af2d-9ddbc50cc4fc/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020290230328_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/27f298c0-48dc-4917-9156-21e536c9a74c/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020290230421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b618e1b6-d1a7-4697-bfc6-71b17c6e3cba/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020291154448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2ff95372-3a54-4ace-8880-82932a865ac1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020291221504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d26259cf-684d-4f05-8bd2-1cf9f89a306d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020294212919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c865c471-ce2e-4156-bffc-65b5226cd14b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020294213011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b315d664-5fae-47a5-9677-2f764dd066ce/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020295204158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/86db0ef6-d68e-4af0-8bbe-ac7a2a6afa23/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020298195414_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/12f69eb0-a849-4b9f-aded-1a4cb4c48a57/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020298195506_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e4cd4bb9-556c-4e56-9a6b-464deca058bc/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020298195558_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/de5a4817-e33d-4477-ba69-3c51a4a3b4fa/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020299190600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/01135483-ec97-4440-a330-9d865b8dd73d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020299190652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/9f8d60b8-eac2-4387-8805-f4dc21383a1d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020299190744_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/6d78c729-9d65-41bb-9272-1da5ff098eb6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020302182051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/3ba72415-a66f-4b19-a715-90c12c304d91/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020302182143_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/60bbbf64-7c7b-4b12-bb0b-b8ec414c1470/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020303173142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7711f181-3e1a-4309-bf5e-c2aa179ab061/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020303173234_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/18e17961-938b-4611-96cd-6f5611299bb5/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020306164537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/235ac4f5-0443-43b1-bb64-69fcae7eba26/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020306164629_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/fadbe9bd-fbf3-434f-a5b7-783ecc103491/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020306164721_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e38fb5ed-e21b-4376-bd14-aa571ec8c8fa/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020307155800_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8f8dc981-d3ab-4f4c-8fdc-02d5a0eec12a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020307155852_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/de64c9c5-1e82-4bce-9180-89d64a0d7c8f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020310151203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/31ebff96-27ea-4cfe-bda2-5480c83da40c/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020310151255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/4eb48541-fc2a-48ba-b222-0f9745c48318/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020331000509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/4883e6f1-b310-4d65-83e8-a2c09c12a966/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020331000601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/037d1433-66ca-4023-bffe-bdbbdb5d134e/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020331231758_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c6d7bbd0-e963-416c-b884-55be81a104d5/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020333231936_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0ec290f1-707c-4ed9-a196-a8d0c3175f26/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020334223201_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0881bf8f-a889-4e8c-8e81-bc0729aef556/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020334223253_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e8a46e07-2b9e-4349-9fa3-23869e3c4896/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020335214441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/024b2f90-0349-4fab-8a28-2d23cf170f89/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020343183734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/bfb13dbf-5b89-4abb-9b43-b11888ea6f99/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020349233528_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/181f06c4-311a-4a47-8ed9-638913b19a96/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020349233620_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/1a16e78b-8882-4567-8035-c53eeca23f31/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020349233712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/fd666022-76a8-4881-a150-68d2a4a7d6b7/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020350224820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c8bf5afa-edb9-4248-9540-9d31912b32bc/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020353220147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0ae19f6d-4251-4679-8b7f-3e921ca8467f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020354211438_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d4891d71-cd58-4435-a730-6093bf715980/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020357202946_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2ab1d283-45b1-425c-9011-29a9a590e060/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020358194052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/4a4b9bec-c44e-4daa-bbfd-988164efe8e4/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020361185412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/aea4bbdc-a01f-4ef3-bf03-aa2a18f99f2d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020361185504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c2482ff6-085e-49c0-882f-d4868d54c407/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2020365172020_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0f351d7c-4b08-4afe-928b-5691b0a33dad/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021003154626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c4b70e8a-1927-40ca-9182-ec6fe4bf1cc2/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021003154718_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/887e2bdc-9baf-4aa6-8b1d-ed7c76aa7a4f/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021024003929_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b44a4488-4f54-456c-838e-1cfa2016bebb/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021024235211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c15bed8e-9af7-4fb6-a5b2-42c90b004aa4/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021035200132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a750c1b5-983b-4e8b-a136-ea118365df95/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021036191410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c3d9af52-b004-4708-b1ac-20b0808da4e4/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021038191616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/34814cdd-21fb-420d-b906-095c0917d050/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021039182847_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/0cdb3985-4ede-41cb-83aa-1b8718ba0519/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021040174124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8b96f086-4919-4567-8c7b-1569e0dcadac/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021043165609_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/18794119-5193-42e0-b92e-01b78c2f23e3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021043232635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2833bb8f-1aa1-4257-ae7a-be785d23ec01/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021046224044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/b50c7c42-4e6c-4797-8bb1-c022f535bc9a/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021046224136_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/cdfc1eb7-fca8-41d7-81ba-4bb8a9756bf9/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021047152321_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/881c1f9d-f762-4995-9bc9-71a6f09f75f6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021047215256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/a731af6d-c6c1-4498-b0fe-6b742fd2a38e/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021047215348_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/28584b2c-6b23-4bbe-811b-1e4dd80080bd/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021050210747_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d13f0456-d81b-4cbc-95e2-40e0362dbb66/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021050210839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/027137eb-06b8-433b-b9d1-45f6e36f13d6/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021050210931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/79511ffb-e4fb-4a41-9835-ae8588b74b59/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021054193456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/231ac9b9-e39c-489f-8cfa-3775258332cb/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021054193548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2a936749-9ed5-40a6-abb7-388f862ec3d7/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021054193640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/e268df9a-13bd-4a03-9858-bb801e7a652b/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021055184759_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/8ddad374-bbd0-485b-8219-5b80a04a72d0/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021058180154_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/94eaf220-2ef9-4770-a248-38a50ea0a3f8/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021058180246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d39c2134-84d6-42c9-99a3-79740cd162fb/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021058180338_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2305cd89-64a2-4381-ab37-d800d2a661fe/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021059171449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/98438a1d-04b8-40ff-a05d-180967db46a3/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021062162853_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/5fb7d2af-53f9-468d-a398-4b41c1f2f310/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021066145545_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/83c98b31-135d-40e6-bda0-9a747bdcafa2/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021084003939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/21dc63ab-c38d-4b3c-96dc-9c202f1c842d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021086004137_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/2976487c-eed0-4378-99e6-60db34269cb1/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021086235419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/34618381-8743-4765-a441-122b8bd0a309/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021087230652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/33a7bc16-ef9a-47c3-a6ce-ec7730c8ead4/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021089230902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/58c6d45b-e20b-44b9-a90c-3dae27e4a0e2/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021090222132_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/40046dfd-38fb-4a61-b2bf-0d08fe7b9d30/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021091213401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/7b6a5104-32d3-4d53-bb37-6913b8dec9ed/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021094204855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/d2a06988-1798-4a43-ae47-6d9179d8ba5d/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021097200352_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/de7ff734-4a20-46b5-acfb-895f0ed96ef7/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021099182905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/75bd84f5-fc4a-4e18-9247-2dc7c8052333/c247c4d5-cb83-47be-ae07-595b76312083/ECO4ESIPTJPL.001_Evaporative_Stress_Index_PT_JPL_PET_doy2021103165635_aid0001.tif
EDSCEOF