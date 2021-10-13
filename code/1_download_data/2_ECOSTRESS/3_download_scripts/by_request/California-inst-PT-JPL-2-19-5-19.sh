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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ed3d486e-0903-484c-a961-588987968e8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019032222727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/d6f3b230-2d60-420b-9845-c76767fed1ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019033213459_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/cee699b1-e082-4e26-80bf-379f301247db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019033213551_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/160fe0b9-1a3f-43c2-a235-48f035fa86a9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019040184838_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/aabbc8ce-9a5f-4e37-b701-40b640887542/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019042184230_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/7739a694-31c0-4bf8-b38a-c705211f3c19/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019042184323_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/16915a21-0449-4a3a-bc44-12792387c64b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019043011138_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/87537df6-2230-4ffc-b8b0-b80a9ba90a14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019043011230_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/2f521688-0eb0-4cd0-ac90-51cb0f29e8eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019043175055_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/a0d4531a-3a1f-474f-962c-9f01b7bc5215/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019043175147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/6aa81124-bcc5-4f3d-b414-ba2eebae336d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019045010713_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0133d580-507a-4a00-9741-f955da5ec53d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019045174445_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/aac6c6ff-6898-43e3-ac1c-10b404eaaaa4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019045174537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/1bfb61b9-2cd9-4a79-9cc1-698f6a7f3b4d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019046001354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/986a3267-5f5c-45d7-a741-37a1191820c1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019046001446_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c99491d6-17e2-4382-a996-3995b7f116b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019046001538_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/48265ebb-846f-411b-8545-0b4345895269/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019046165311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/6960022d-4d69-4868-b616-a9b5d709a2a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019046165402_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/6cf7d12d-bc98-4cac-be99-11c38744fb96/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019047160134_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/7c6411ae-8838-4e6e-9462-de1f00f257f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019047160226_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/7d6ac326-b06b-4d78-9d96-9b65c57594fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019048000839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/e33f899c-cc36-4cab-84d5-45e48d838486/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019048000931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/5a5e09fa-5707-407c-9dd3-426961abc0d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019048231610_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/d174799e-5862-48ec-bd4d-f579f95527c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019048231754_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/05337641-858f-44c0-bd7d-7f89a43f8dc8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019048231846_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/5010e5af-3e29-4bd9-abed-77ecc036b8ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019050150351_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c2d96776-91f7-4331-88df-5e74132e6ce7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019050150443_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/aa860ff4-bbfc-4566-8dd8-8e8fbca42448/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019051155011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3732c1f9-8495-4d11-9db7-29db3757e112/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019051221826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/dd8ca0de-44f1-4736-9e03-33281162bd41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019051221918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/b73e2243-65dc-46cd-9a3b-256c756b7ae1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019051222010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/a0ed0731-b4cd-406e-95d9-e03c939bdb7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019051222102_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/231e8bcd-7945-4984-a02e-eefde9393627/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019052145743_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/5988566e-24fd-456b-ba2a-7fa38809eaf7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019052145834_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0d4c1290-e043-42fa-947e-db5395940dd1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019052212650_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0a76b25c-984a-4526-960e-767b520e5ab7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019052212742_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/f322e85b-b337-4e47-a44a-cdcb8ed0f29c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019052212834_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/f6152396-860a-4f60-8207-c4eb4ec5bbf6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019053203514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/2d78d10f-7bfb-4183-848c-0cfd085f538a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019054212133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/1e6c7f38-cf38-49f3-9692-79e366f541c5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019054212225_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/84247e17-976c-4d09-a44e-0738908dce39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019054212317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/335381dc-fce8-4c6b-9bbe-27e05aa8e456/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019055202959_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/8816541c-1eed-49dc-b79c-2d70473d5b30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019055203051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/abfc5f68-eb50-4eeb-bcb7-eacf50b5a45a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019055203142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/72031ce1-2787-437e-871e-0f2c29cb6f63/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019058193306_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/cdcbba8d-ec69-45ab-8f7a-e0b5c9001c64/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019058193358_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ba4fb075-40d7-47dd-85be-33b0db2adbc3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019058193450_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/73dbc701-6b97-43f4-ac76-717f181f2823/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019059184124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/f7c72967-46a1-4e0d-a113-5913569becbc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019059184308_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/e8065e7c-fc4c-4437-a3a7-14bfe87af64b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019059184400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/7660ad22-1f05-4bbe-af57-ab1479f6bc98/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019060175042_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/cfa8172e-9435-4561-9837-ee534c5fd805/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019061183701_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/124867b7-4cea-4cb5-af2b-1a073e20a46e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019061183753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/884612bf-e4c0-49f4-ad96-1cf92a0dc502/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019062174525_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3d67ef01-fbe2-4a88-bbad-c41fc568166d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019062174617_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/579a0f79-c4e8-4344-9981-cbd1c313671f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019062174709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/a2e2f21a-2f62-428c-8d6c-484886450405/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019063165350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/7615dbf5-de83-40f1-ab50-d0842e0e86c4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019065164833_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0850add0-8250-4049-9bec-7201b4577079/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019065164925_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/8b80917b-5ab9-4a98-b5a4-f9b870c1f0e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019065165017_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3f675765-322a-4eb7-a71b-7dd1edec18c1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019065165109_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c511dda3-d6d0-4553-903e-e23ecac148ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019066155740_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/e32fcc92-6311-4e2a-823b-fa52f69e239b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019066155832_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/d430188d-0e34-4fda-8a03-85c523bfe18a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019066160016_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c04d92e4-e38d-4fb6-b32d-4888bd851cf5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019068155316_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/f39440bc-0fd0-4c3f-ac2a-ce822bce0627/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019068155408_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3ec9378f-7017-47bb-b716-f9100e486d63/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019069150232_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0d41717d-0cd7-4e39-b75b-3beda58d361e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019069150324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/e1de2d66-aac5-4d59-9e16-4fab85f1e155/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019069150416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/60b6868a-25d7-4dcb-99d4-9755fb2dfa8b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019072140725_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ff345015-35b0-4357-bada-9614aa279b24/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019145010922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/a3057b69-86e6-4a8c-bb20-b8ed393bdb6f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019145024525_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ab727940-7f6d-4a89-a28d-2b7e6cac36e2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019145024617_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3962259b-56a6-4f59-b778-ff903dd91d83/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019146015626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/b6a25006-8b2d-4f75-b401-674547d14e9e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019147010635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/02afabbb-03ea-4aae-a610-e48038f5ad35/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019148001714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/83f75d98-297b-4edb-8251-c6185474cc87/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019148232802_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/23bba122-020c-418e-b620-9979765ba6b6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019149010421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/1efeeac1-d5b6-4de5-a98f-ed1799523133/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019150001456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c6f11d05-6721-4ce2-91e2-738e48d3160d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019150001548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c4d1ca70-0c48-4132-b829-30711d1f1302/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019150232523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/6315fee9-a9d7-45d8-9537-02ee74a4aa20/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019150232615_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/5e484ed1-432d-454d-a9f1-495f4db34620/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019151223614_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/fd56cdcb-d3bd-4cde-bee2-0011edff9369/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019032222727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/61da7127-dee2-41a5-b309-89cc6e5ac002/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019033213459_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c563fe8a-3f68-41cb-8cb5-c7103f12c2ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019033213551_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/46909a36-2ae7-497d-8310-1c43e41c84fb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019040184838_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/14eee5c8-4fc1-452c-971e-e60887e73bc1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019042184230_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0152a965-dca6-4471-94c7-e7d69a116e43/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019042184323_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3ad5df25-12c1-49ed-8264-f6e49c8b880c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019043011138_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/692f5943-45eb-46c5-a449-5fe555c7171d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019043011230_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/a522d387-871a-4eed-97cb-1e25cf1af46f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019043175055_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/fe2c815b-3984-4943-841d-97fb81143f0e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019043175147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ec53da9b-6ac2-421f-a858-37028486146e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019045010713_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/42cd6c7f-16d5-438f-83d5-fa4f1de902a3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019045174445_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0771cba4-1063-4fdf-a26f-f46b9d980103/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019045174537_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/e4cad63f-6ec5-4c7d-9165-72491f8364a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019046001354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/f86271d5-0455-4b6e-9308-2e77c67124bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019046001446_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3fbfd57a-d180-4f8e-883c-ee073f21ce53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019046001538_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/5f2f98dd-f975-47a8-87d3-a2b7762b2a4f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019046165311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/008c11d5-9e02-40cb-b299-1df1a7418d52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019046165402_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/7ad757d7-cc9b-4605-b92b-ab8d625c42b4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019047160134_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/943fd390-36aa-459c-8d47-97fbf54c1ffa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019047160226_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/23876b7f-585f-4bf1-9dab-978ad4b30caa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019048000839_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/665fb461-056e-4a3e-883a-ca2532bec409/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019048000931_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/7773f2cf-9f65-4b22-a395-cc43acb74dfc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019048231610_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/620ddaad-bdff-4d70-8401-d7e086feb9a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019048231754_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c6232ee2-f436-42e1-8f23-72ed7d1752b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019048231846_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/bf8acff2-6b31-483b-baf4-4f7be0fca3f9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019050150351_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/5205ab26-68d4-4dcf-a45e-9f832b895b39/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019050150443_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/53e5d1da-cd25-47fb-a109-edd27476f4d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019051155011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c34a0413-cb13-44c2-b46a-a0f91053d2a0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019051221826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c97cda58-6553-439c-9844-03073a1abf0c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019051221918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/01f9e540-9208-4d69-b121-c3fa617aa60c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019051222010_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/9c776caa-fa89-42aa-818b-483d22b92843/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019051222102_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/bae590e5-ab83-435d-88fb-0ac478a72873/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019052145743_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ba64d28d-b450-4eb4-8119-99d4f44f33c5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019052145834_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3da44af4-54f2-49c1-8c98-54a3c4f3c770/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019052212650_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/03b15374-8959-4a32-b81b-7c7fa96de815/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019052212742_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/89563370-76c6-4de6-a0f8-c66201beaf60/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019052212834_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0c9d91c6-06c2-40e2-8429-48e16f01337e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019053203514_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ff44cbdf-8ff4-44ed-9f11-0d5b563ef371/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019054212133_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/b83feedc-f891-4d2b-bfb5-2294013655cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019054212225_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/e6de304e-2204-467b-84fc-555cd2321b86/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019054212317_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ef13e368-0441-4d62-84c7-a997724bed3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019055202959_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/2b1555e5-f989-48a3-8454-dd17b713db2a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019055203051_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/8d7888cb-972a-4761-b84c-2ef9b85c8877/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019055203142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ae22de30-1db0-4e0f-9c94-323332322c9e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019058193306_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/e4679832-f0a3-4bce-ad1f-73f779ae90fe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019058193358_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/4423aa8c-d8ef-48e7-a646-4a06138a4aa9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019058193450_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/6db75a16-ebde-4772-8c73-de24855d0eac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019059184124_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/d11c39a6-b700-4a22-aaf0-15a3bf5c58ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019059184308_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/609065ed-38f7-4d6e-af96-a7dd28972126/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019059184400_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/fe82c51f-5d62-4dc8-bc5b-036faabdaf52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019060175042_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/1083ab54-6040-4d3b-9148-6bddb4d5c88d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019061183701_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/7d539bbb-5813-4b8a-ad18-ac9f2493266b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019061183753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/dae3b111-361a-4648-a525-fa4627be21c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019062174525_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/78f47633-dfe1-49ed-a2d8-08aaa1931f6e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019062174617_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/0c81c578-2f8b-4ae2-b82e-dc5b82caf9c4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019062174709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/63613029-9751-46c0-8f76-c45c985c1164/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019063165350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/09cf2443-ea25-4d5f-a8f7-d7f36d23f12e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019065164833_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/d05e5392-d077-4509-a82f-6776ba81e1f8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019065164925_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/46014a33-b5df-4744-8b31-1d619a6423e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019065165017_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/82cff1e5-d90d-4970-9035-cf998ad300ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019065165109_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/36f7104d-089c-4653-a234-10d3faf09560/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019066155740_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/a0e31386-51d4-4c1f-bbfa-decc59936164/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019066155832_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ee62746a-0e97-486b-a129-3f0979539875/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019066160016_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/57fcc7e8-02be-4c21-bd6a-92d1aeefa088/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019068155316_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/51b789a7-5a69-4814-9a85-df9c612cd305/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019068155408_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/39c34648-2243-481d-a06f-a276292b9ca6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019069150324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/baeadf55-d375-4f6d-b23d-b3e2f924afe5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019069150416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/899d5403-ab7c-41f5-bd4c-07712409c710/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019072140725_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/3c5a0edd-04a9-4f16-896e-2a17996082ea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019145010922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/6e12e219-a408-467a-b642-dbb9a32cf2d5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019145024525_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/d2735beb-2d7b-4f1c-aa25-1f8a5fd54513/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019145024617_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/cdd5c35a-62e0-4227-9f4b-da42d7019938/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019146015626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/5a5ba374-18b5-47a7-85bc-81ecdd308305/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019147010635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/251af437-86cc-4f9c-a247-32f8c9d12421/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019148001714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/f30350aa-239f-45b5-927a-34bf4114a678/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019148232802_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/4f111b0f-cd78-4ae2-95e2-c7f4ba7addca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019149010421_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/c167da55-0585-4301-ae2d-503f4ceb15ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019150001456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/aea2c18d-c781-45e2-9a72-3a1c9b2cdc5b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019150001548_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/ada5ffcb-e309-47a6-8545-e741170d8109/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019150232523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/d55f184c-9c99-4eaa-af22-41e85d291669/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019150232615_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/ec896587-fcbf-4470-8713-d2b8b7797dfa/23f94467-8d0d-4d46-bcb9-0f9b2fd87964/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019151223614_aid0001.tif
EDSCEOF