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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/c728a3a2-1c58-4f65-aa62-114ff26b6389/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020035211608_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e0a97592-22f8-461a-9167-7666f4289c7d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020036202830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8958872e-a3c9-4d2d-a9fc-f33dee7ce60e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020036202922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/6fae1fc7-b6eb-4b1b-8564-f8103058e410/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020037194050_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/54052aa0-85cd-4c3c-b357-c04fd5612e8e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020037194142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1fc53866-fe0f-4ce2-8ccf-8221c247ba42/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020038185325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/5f7c0d34-6ec9-47c6-aa42-a22b77ca0492/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020039194329_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d3042260-0ccf-475c-9941-5a4145c6d882/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020042003727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ed81495c-c4c0-43cc-8dff-385727083675/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020042171952_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b325520d-0f98-49b7-8ed2-1cf4ae150f64/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020042172044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e0a8563b-1837-495e-92b6-049d1cb335c5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020043012753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/41382da0-349c-4b4a-bf41-2ce8d64ce808/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020043012845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8aeb510f-73ed-4947-b1f5-f05b2a27415f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020043180910_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ce6d24bc-913b-4bb7-8f4e-98623e84061a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020043181002_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/2a527488-b1f5-4298-b8cb-e3e3f9309dbe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020044003909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b777d282-25e0-430d-b03c-8f7bcb8ffb55/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020044004053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/2a4cb2ab-5aec-4953-98fb-7ccc37c67412/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020044004145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/61e43382-e1d3-42fe-a72c-05ffdab3b1f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020044172119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/5ba96f7c-927e-4d14-957a-a86feed9e361/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020044172211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/94072daa-1234-4613-91bc-c5a8376aa580/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020045163344_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/313eb0f4-e2e9-434c-8cc4-2d514e227df2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020045163436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e8f57d3d-5263-49b1-9885-ab09b9c04738/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020045230342_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8c144979-3abc-4fdf-8ec9-66444fb55ac3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020046154624_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/78c628cc-be57-4310-a160-888963f1cec3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020046154716_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8f8fb329-d9d5-4c05-9577-d72c55098772/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020046235451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/56dc72a6-6ded-4c4a-811f-10511dc7742a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020049213014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ae4992f5-6a20-4677-8014-7b6df4b7eb41/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020050222049_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/5147fd20-040b-4094-95b0-f5479f58691b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020050222141_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/71011bd5-f5ff-4ba2-b4e4-799fec7b6c49/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020051150249_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/03485057-bf15-4ca9-b411-3252b7b3b75c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020052204417_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/674b3011-4ccb-4ea6-816c-e36ebd3987ef/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020052204509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/931b8307-88ba-4324-b6ce-91cc101f2b14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020052204601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b55a64c2-5c09-44b4-9710-c8f708da9aad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020052204653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/cbc461eb-e0a7-4871-93c3-d8968226938d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020056191129_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/36c00997-1f19-46cb-85b6-bb973f437456/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020056191221_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/be85b709-a7ad-44f6-a800-4ccc8b5f0859/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020056191313_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/369f174f-9511-4189-bad5-f2ee0e224528/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020057182258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/63989e20-b7c0-445b-b2f2-8ab956c575b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020060173714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7af1f8c4-4d2c-4a39-9713-32e9ada6c10c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020060173806_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b4bdfd86-94b9-4fb5-a771-f8a80860ae45/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020060173858_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/03f12c4f-e402-4063-8f7d-e8595931a6da/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020061164910_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ef3e2de7-222c-4c3b-b105-d8ee43e9564e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020062173948_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/9303a28c-d836-4ec4-a2ba-41efd37aa593/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020062174040_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7c6e046d-8877-4518-9fd4-4fa7c9d6302d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020065151523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1b484401-3072-4f92-be91-00abd9150cc7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020066160640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8f738e07-968a-4d39-8226-c9e53ef9eecf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020068142939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/c78055f1-3b45-4a85-b706-0f1c2d7477cb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020068143031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/f450cdf9-3a45-467d-8215-341b747d07c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020068143123_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/89e70717-12b0-449d-bb9e-17a15bb759b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020070143221_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/f1601e31-6ee0-4039-9729-17affd1b20d2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020082014257_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d5b84e69-3baf-48fd-a5fd-cf32412d0458/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020084014449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8f3fc6e0-97fa-4416-9e8f-577299aa39a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020084014541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b1c2863d-ca3d-48ab-a979-5ec2907b77a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020085005731_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b55abc62-24c9-4f54-9d9a-010c93157184/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020085005823_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/52499ec9-95af-41d6-a5cd-a5d2b810f303/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020086001022_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d449e8cc-92b5-446c-af2d-7c69dcd3b072/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020086001114_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a0f46fb1-25a9-44cd-aecd-d16be88c8346/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020087005951_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/131bf3bc-ca20-4de9-841a-be72de343aaf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020087010043_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ed459c15-84f6-4c36-a32a-d6de8256cfa4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020088001215_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/6b726e8d-09e0-4964-86b7-c0123906488c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020088001307_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/484502ec-bfa6-40da-bb29-a41d7c07a273/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020088232451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/067a64bd-b297-4aa5-b95b-0cd6db58497c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020088232543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/56168086-e88f-4a8d-af65-32343e0757f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020089223739_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/94c154b1-c1e8-495d-8db4-b308cd0c8d0d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020089223831_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4d1ed7ca-616a-4219-a71e-fe0d34c3cfb7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020091223937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/70426e3d-2237-4a0d-baa0-2c6e708a0c1e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020091224029_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/09677361-38b1-4d0f-a783-e02b06cb4f6f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020092215211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8d340c10-9216-49f5-bfd9-641e758698bf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020092215303_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/9247cc9b-855c-4e3d-ab2a-65277a24853d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020093210501_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/80357354-6a3f-46a5-a925-6394a1610e82/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020093210553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/f86f17a1-855b-4da1-a176-712ea0a82ed4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020094215451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/649b20b6-34c2-47d0-95ac-da189f5bd369/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020094215543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/54e2d470-1fd2-48fe-b9e0-306ad8438e08/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020095210733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/21cfe280-e825-4bd6-b90c-d6c812bfa915/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020096202021_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/036e561c-1c3f-4d37-be76-eb86506ec160/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020096202113_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d573a789-0917-49d5-9d35-b581ff478f40/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020097193325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/2ba7731c-f178-479c-b7df-f79b671a54d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020098202311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7173a4ea-dda9-4a1f-a4c5-edec909112f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020099193553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ca02ef1a-2d5d-4ef3-bf1b-c3918fbaaae8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020100184830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/fcd88e37-47ca-417e-b82b-4fe5c06a2acd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020100184922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/51459bb9-2816-458d-bb74-e2210af76baa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020101180126_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e1199a01-449f-42ee-a71c-0d28ebc46b83/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020102171450_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/efa02a63-c5f5-44f0-b2c9-d399f596a1d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020102185116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/cc3d43d2-7e3d-4283-ac7e-bebf0483199e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020102185208_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/90c8f280-f305-470a-b5a9-d1669a822925/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020103012226_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4b9a4e49-6f7a-4c22-b216-a0e86fa7a025/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020103012318_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/45d53d5f-a552-42c1-92ba-935c60e734b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020103012410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3190cff3-e656-4201-8d0d-0515e8db74a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020103180354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e32b70d4-fa4a-49fb-b2bf-4fc1ad3b8a85/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020103180446_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7c4ba553-7614-47df-a35a-d85cb215d418/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020104003659_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ad81c530-5aee-467c-b98a-9e2d48776da4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020104234704_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1f86e4d3-af93-413a-b42d-40946c9e7dfe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020106154256_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/94f5a7a2-fec3-4c18-aee2-b8897e26527f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020106171926_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3928e0cd-f801-405b-b203-adc7fa507b14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020106172018_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d54098b9-c75c-4f89-9dc6-7d5994d66e4d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020106234930_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d8ecfa43-814e-441e-aff9-8dce2680111d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020106235022_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/f2d4eb38-877b-42dc-9278-bd6eded6edd1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020106235114_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e6c069e3-3d1f-40ae-9298-b6e22f231073/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020106235206_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/12d30597-9e2d-442e-9b14-b0c445756064/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020107163209_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/fe56bbb4-4575-443e-895b-89235877300b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020107163301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/6337b0fd-5ea7-4c09-90b4-94ea9beddced/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020107230147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/da111318-e301-401b-b914-c4241454f73b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020108154454_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/c10a2f73-0cae-41c7-abbf-fd8b156554ed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020108154546_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/91dc9eac-3655-4ff5-9e44-8504fa2be01d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020109145755_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/bcb774f5-9291-4d65-bab1-17ca55e4489e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020109145847_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/5e0a8c05-98e5-4cb4-96c2-0bb8098e6e0c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020110154727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/247d53ba-1382-4f8d-acde-b58d0853f33f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020110154819_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3d122b55-4912-4673-85e6-a22a5fedd034/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020110221723_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/6e963d32-c184-493d-bdb9-9f82bfbae124/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020110221815_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/76e7ad9d-1902-474e-94fb-8b5bcf2be035/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020110221907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ee886976-b8e0-4f4a-a76c-a1d01f76076e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020110221959_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a2bc0529-d831-41e4-9cbe-10dea77fca9c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020111145933_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/de36cfb4-bcd6-4ec7-a38c-66bff31cc183/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020111150025_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a78b045c-c54b-43c3-9c3c-c7678399b4d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020111212954_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/9dcf6b06-be2d-47cf-bda3-db9d073befee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020111213138_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/62f8ba16-80d1-436e-8430-489cf8229c86/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020111213230_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b53d7b43-ba2a-48de-917d-f63c345f35dc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020112141145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/71981c55-f82d-48ab-a7fc-1fa07192ee03/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020112204156_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/541638cc-9902-48f2-87c6-6b33046885ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020113132414_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/77735ac6-0998-4586-b5d8-bf2051880017/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020113132506_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/c8af87e6-bcdb-4d14-91c7-52347dad0823/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020114141411_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a49c1949-69ef-49b7-bc98-f9621398a8f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020114204412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/baaa1ba8-bab9-47a2-95ab-520f86d84b98/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020114204504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/561e26dc-34ce-412f-96a5-f58f11910280/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020114204556_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/33cc4612-0722-4909-accc-805a5db3b7b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020115132524_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a08e27cc-e1ff-4a9f-99f9-792ddd1d40a0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020115132616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/433caca2-0709-4e95-a717-64453aebad64/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020119182227_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/02457a5a-23dd-4639-9e2c-52fb63eeb4ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020122173543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ae495846-4c55-4e1f-b31a-20c73eaa4a30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020122173635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/349e2e77-db0b-4b50-a841-592ad8cb8a7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020122173727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/81c88c18-12a6-4d2e-b306-a075d308db99/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020123164857_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/32c5b800-fae0-4f2a-b81e-9e4f83c7d1f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020123164949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4940c742-ca00-4847-b76e-c3638bde618c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020127151206_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/f5f4d5be-d469-450f-b88b-2dbe34e21b85/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020127151258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/6f532c6b-a1e0-4991-a808-ddd1ba7f977a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020127151350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/0a59a989-9343-4ce6-aaae-8627f18785a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020127151442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/254476a2-76bf-47af-a097-584a71394b33/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020127151534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/cb8ca8d3-5850-47bf-80ce-e3cfbc533fcc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020131133825_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ffc3d482-a47a-49d2-9583-d65e7a8d0020/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020131133917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/90b091d2-64c2-4155-b302-16b4b0c56f4f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020131134009_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/73fa08dd-803e-44ec-b5a6-a55e745181f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020131134101_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7b1b2cad-4c4e-441a-b947-553da0f102ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020132125041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/50306688-6e76-4171-ada5-14f692e3e987/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020133134112_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/812cd8f4-c7e8-4bf2-be4d-8d918ceb7719/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020141022404_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/2ade63d7-f3fc-41b8-89a3-4f3c986bcd07/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020141022456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8a814ce1-8859-4b09-9b99-df79b4cb7bbb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020142031311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/535969a4-b054-4da5-9cbf-1838158b450c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020143022502_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a18e72a7-c1d3-41cb-b8f7-225b1b578775/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020143022554_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e795ca69-d4da-40df-b38b-6a1e0c04f83e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020144013719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/07023efa-f3ae-4305-a222-af6a07048867/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020144013811_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e1e059bd-b1fa-41f3-b0ef-af4665a5f8a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020145005033_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3e944b50-99e9-4669-a505-0aed9bc38b8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020146013845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/aab97314-0e32-46f3-866b-a2e9adc8e26f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020147005046_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/31230c0a-543c-478a-b0b3-d11f6ff17f1b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020147005138_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/864fc9f3-88e0-4191-8bd9-d6fc13829e58/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020148000255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1cf94ca0-6418-41b4-a269-76208a6d3d40/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020148000347_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8fe46668-7a6c-4961-9e95-ec015fbcfc00/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020150000419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d319b4e5-3f60-40f2-9bc2-c1a8d1ab20e2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020150000511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1743df26-94ae-4f52-b977-fd16986d8ba1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020150231709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/89e93956-3ef1-40ec-89dc-a9d79b64fd0c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020151222828_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4b6cd385-43ff-4736-a07e-471c7ca8152c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020151222920_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/111fede7-992a-45f4-b313-643d265dcbe6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020152214046_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/acc77728-ee9c-4845-91e7-cf98e92d0f4e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2020152214138_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/123431a3-ee0f-446b-9b17-42d1b197fe49/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020035211608_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/bd94772b-99ee-4dfb-a6fb-0e3f7bd30f5e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020036202830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/50f1eea9-1d95-467c-88a3-fccb0278e794/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020036202922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/066b04ad-6c10-44bc-bbb1-4e0aab9be93c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020037194050_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/98695b9d-a6d7-4c04-be3d-9864f61fc821/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020037194142_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/071cc17d-263b-410d-9e1a-418c61a484ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020038185325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b1f8a210-1e13-4181-8463-3454fdea0f8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020039194329_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b0028e8c-2a0f-4588-87e6-c99a6300ef2c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020042003727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/67bfb0e5-069f-457a-9ac5-694fcddb14f0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020042171952_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ce47568c-8548-479a-a01d-c5381149441d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020042172044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a3cf1d93-520a-4de2-8f2a-a935b0e83556/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020043012753_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/58a5fd13-3689-4568-91c7-30cc65be52b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020043012845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/54d8f891-ab14-450f-b224-c376f683d9da/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020043180910_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/86189ce6-1b79-4d74-bb0a-ad86ab7a82a2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020043181002_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/dfa6093f-ba6c-4d1c-9aa6-b89fd80d4ef8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020044003909_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3536167f-5ae0-4856-a9c0-17ba6caa25db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020044004053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/202d340a-a423-4bc3-a064-268b7a893edc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020044004145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/c1c78443-9403-4466-aac6-78b7f4482b83/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020044172119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d274b5cd-2b39-42da-9332-7a57ebe0d5bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020044172211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8b96b15f-15d3-46a4-ad3a-d2c653f229b4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020045163344_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/45be1a8a-f1bf-4ef6-89de-5fa1b604ef5f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020045163436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/eb9c23da-4bd7-4078-98a7-3ce0f3d103ca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020045230342_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/db8f1f3d-7003-4adf-89f6-14e0e3369b55/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020046154624_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1733b038-78ec-4f8e-acf6-6bbacf97846c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020046154716_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e9ef59a2-ad5a-4935-92e6-e969f61f8ad1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020046235451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/13298fac-474a-436f-8cc3-8e2527bed00c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020049213014_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/63fc8198-d173-4c2f-83b2-dbf1450c40ca/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020050222049_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/5e364c96-2227-4765-844d-b932f26224d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020050222141_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/2a707af5-dd04-4c89-b146-00fed9257a02/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020051150249_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/84d8226c-6cc0-49ed-b5dc-aa69f5b9f1b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020052204417_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/c7cbbdfc-26b7-4cc7-87d8-b5c1ef91bc6a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020052204509_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/df040f93-fbd9-472f-bee4-fb8422ab7417/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020052204601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/612ab1da-83af-48e3-9629-e2b590fed999/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020052204653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7a099056-2e45-4499-a6eb-972e3107c7a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020056191129_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/586a4943-ff75-4d75-aeb0-84f34833fc94/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020056191221_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d2cfab7d-3651-440d-ad6d-40a9de746c06/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020056191313_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8b4f1baf-490f-4481-874b-88f8f959fa5d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020060173714_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/2d9e2052-ad97-40fc-b021-237631b0924c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020060173806_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/19a4f920-07cb-4432-82e6-650fb6d12313/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020060173858_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/364827e3-2441-4b43-a69a-bc6171cd65a0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020061164910_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/0c739b14-16d3-4f33-8e42-01aa8a5d0f6c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020062173948_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e3627c41-77ed-4ec3-ad1f-2cdbde07d03e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020062174040_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b1d53a6b-0699-4c1f-a278-2238cc301e6a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020065151523_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/5e1fbe4e-3d9e-4193-9843-8d4db0d9c2e6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020066160640_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/fa043c2e-fdc7-4077-91d7-89263a0afc97/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020068142939_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d0aa4605-2fb3-455e-9a97-40cf636c9600/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020068143031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7d49e8cf-8ac1-40a3-a80a-80e3622beda4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020068143123_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/9af0d4b5-0854-4281-891a-40612f8bb0ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020070143221_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3a6f58ba-5095-4ad0-945c-9268d3fbc69a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020082014257_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/51de8d04-e627-4bc9-b07f-5c821be655d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020084014449_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d5de9120-e755-4aed-aa30-728c89cddad1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020084014541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/6ef2d051-2843-4551-8db4-17d2ecfc2ac2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020085005731_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4a0393b4-d62b-4959-818e-29bd07b0d4e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020085005823_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/569bac92-9018-4e38-b815-f16a1d24b76e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020086001022_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b25c964d-b0fc-4a87-8dd0-851572b03a35/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020086001114_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/50988757-c24f-426b-8627-e2847378c014/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020087005951_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/66fba933-854d-40a3-b8d7-b74b77832a89/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020087010043_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d03504eb-dce2-4a15-b0ff-5a4ebf6724f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020088001215_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3b2b36b4-6dd7-4218-bf40-6bb06472db73/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020088001307_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ff4146c0-868b-47b9-aa9d-4bcd23731cf4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020088232451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e6063937-faef-4f0d-9076-e7e91c506bfc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020088232543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7e114aab-72a3-45ff-8117-a57214997a76/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020089223739_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/577a099b-a8a5-494b-b595-e43a0f9fc935/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020089223831_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/af1954a1-ded6-4a68-856e-acec76dbfacd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020091223937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8f7c8949-487d-4356-9530-8d908d3052a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020091224029_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/2ba98f3a-863f-46d4-8485-426201e124e7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020092215211_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ac5700f4-1937-4b04-90aa-922a7fbb742a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020092215303_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/40b54fa1-7444-4a1c-b10f-1d480d61874a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020093210501_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/91cc0cf6-378b-47cb-ae65-e6dcb10273cc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020093210553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/9416c45f-522e-4071-8ff2-04f5e5b76cff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020094215451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a55a181f-baa7-47f9-80ad-5004f1551481/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020094215543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7f6e53b1-a206-4487-9ce3-117c160d16d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020095210733_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1f5c9297-94f7-49f0-8a84-e55abbb8e8c0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020096202021_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3c8d6262-34dd-483a-8ec2-b3e3fbc15458/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020096202113_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7b149528-789e-4a41-83f0-fa18ac0178c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020097193325_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/99d98cf5-a677-4da2-8744-4f69578b1837/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020098202311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/69850c6b-9927-4871-b3b4-e8d024df2ade/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020099193553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ecbdcf15-e566-49ad-9699-476eccddf4cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020100184830_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/c0a72749-1357-45bf-8837-90141651d51d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020100184922_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/c2198163-80f3-4f6b-a591-1710cec71da7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020101180126_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/2688cc14-86ab-4280-98a6-95d9e19f80f3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020102171450_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/5b5ecdf9-03d5-4ca5-831b-364c6241d2a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020102185116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/076a0663-0d28-4b93-884a-a0eae855340a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020102185208_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8c7b0e81-b4eb-46d6-bedd-1b25327fb93c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020103012226_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/20e4c2d6-3b58-4b93-b32f-f59524e66f8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020103012318_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/fa76186f-acd3-4ad8-a40b-94c939e261de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020103012410_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7e713627-924a-43b4-9130-e743fbda3573/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020103180354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/cb190c4a-deb5-4041-bb61-8f1f5b89aff7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020103180446_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/80bb1344-3481-41ef-9d31-b22455c5b968/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020104003659_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/cdc83153-c790-4ffe-9bbd-ed5402114a2e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020104234704_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/06c143e7-eeef-4037-8b75-2ae17ffa6d3b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020106171926_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/515c8011-bd3d-43c5-bffc-f7e9eb61f22f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020106172018_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d8f0d829-5311-453d-a0d3-9d521c32c568/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020106234930_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/fcc53530-4ba5-49bc-9794-93d0dcfcdf7f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020106235022_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/f51e6825-eeba-4dd7-8a5e-366406255756/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020106235114_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/eaef74f9-d298-4414-9cc1-24ac93a0e508/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020106235206_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4d1a3de3-ad41-4ff0-9a9d-d372d65681b0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020107163209_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3524fcb0-2e4e-4ec6-a635-2ba3a865fc86/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020107163301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/dfb6e5b0-3d0c-46a2-ab57-6797fbdcbbb5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020107230147_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/90c86f36-f7d8-463c-8a44-e72c4c5b63eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020108154454_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1f1f6ea6-b4ed-440d-b346-02220402dd71/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020108154546_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1bc7e5de-b652-45c9-8457-d60332e25ebb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020110154727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/0dfa1c8e-2a33-48fc-87bc-05f6a11caa74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020110154819_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/91590d45-1da3-45f0-a397-4ca5722539f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020110221723_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/179d4a48-a717-424e-85fa-bdfd155639dd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020110221815_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e045a80b-95de-4ccb-abf8-8780a80130ce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020110221907_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/dc3378d3-1445-4c90-b9db-7ba6f3c3ddce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020110221959_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a99372fc-5de7-4dd7-a17f-c3b5cda20967/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020111145933_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/9db7b570-01ce-41eb-a432-f70df95bf636/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020111150025_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/dc52668c-2018-446b-b80a-7eac61d77f7e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020111212954_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4ea10a32-79f0-4fc0-8735-31014604dd99/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020111213138_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/238f6812-792c-42bb-8c2a-fb739921a4ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020111213230_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/7a5c6bb9-5875-4987-aafc-42a29a9c434e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020112141145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/79f36485-2a2f-424e-83b7-c0b17dde7aba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020112204156_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/42a0073c-dd83-47fa-9f3b-fc4505c96457/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020113132414_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/28e236b2-74a3-43bb-bca2-393a647b7a0f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020113132506_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/82515c1d-3ee4-4d7f-a64b-e93d6fb61749/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020114141411_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/f5657faf-925a-4041-b47c-335088aace6e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020114204412_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/647001cb-a7a8-442d-a799-93bdfc1aaa2c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020114204504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/0d6b1bbd-9503-4b33-9ed2-751d93e2813f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020114204556_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/908989d8-4ab7-46d0-9362-40ca6109ce16/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020115132524_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/88a2bf4d-ed68-4bc9-9ad2-8ce8e990d4c9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020115132616_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/b3a0c107-fac8-4783-8afc-1e30f9ddef24/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020119182227_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/800a42df-7d0d-4653-8a24-84cf9d9cd355/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020122173543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ce43717e-4370-4f9c-bc7b-f1668c4f8391/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020122173635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d9dab537-05f9-42fa-9fb4-3215c0196122/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020122173727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1aadeb0a-a406-4874-a72e-095bb5258264/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020123164857_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/fbce5a95-bd26-44f6-9713-626a60dce3ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020123164949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/1423892e-a252-473b-8f33-82ae303de422/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020127151206_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4b5895cf-a8e9-413a-9430-add4477863ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020127151258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/fcee462c-1842-47de-849f-2da025a1e187/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020127151350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/6fc66c40-586b-4590-b21e-5a1271d6bbe1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020127151442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8090a89e-c6a2-4237-99cb-7488f92ca559/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020127151534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/4dd0abcf-10a1-4e3b-8a25-38af600b43d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020131133825_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/48107810-c6bf-4517-90fb-5bd4d6240ee8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020131133917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/9b53b6d7-0aa9-45a9-a810-8e4c656e7f65/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020131134009_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/986bf758-e4d5-44fc-85e6-544d34bbd157/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020131134101_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3d62a086-bd27-4775-8a48-01a9bb116aa9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020132125041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/466fd8c7-3644-4aaf-8b98-d2175b33b299/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020133134112_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8b91bf7a-264b-4fbe-a1bb-450f4b19cac9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020141022404_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/3cc29734-0a45-48d3-9010-4f5b3e2f5828/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020142031311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/a2635700-10f6-45d2-a231-0339d1a74c8f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020143022502_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/de94cfbb-4b9e-4ea3-9337-b2ac5323d731/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020143022554_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/91c6e4c5-66b2-4462-a0c9-1afb69c9f61d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020144013719_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e739c859-0d2c-435f-b48b-436a50fdfe74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020144013811_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d5cb40ee-3d89-46be-9453-a80998c1b310/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020145005033_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/335ec2c2-8629-4b5c-b37c-e1e7dda0a66d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020146013845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/d8762998-2200-48f7-a862-717cb42ba4f5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020147005046_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/8b107c99-31f6-4520-b5bc-f4324884055c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020147005138_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/cf3563af-dfd7-4584-867c-d58d4a63e834/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020148000255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/00d7a46f-5b71-4de1-9c16-1bdcd9438784/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020148000347_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/de2cef94-45c7-439f-833d-016c625c2561/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020150000419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/13b1e6ca-45e8-4aca-b4cb-18a60def667d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020150000511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/95eefff4-6f52-401e-9da7-2413fa9748e7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020150231709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/05ae3fac-e390-4a50-96a5-97d21f7ed76e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020151222828_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/17b15631-c2f9-45b0-866c-e7f520f8c74a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020151222920_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/e429d24f-3343-4246-a606-b5db1364041e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020152214046_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/7ce957c7-9687-4199-8451-aeefb454a24c/ca5f343b-3c5c-4261-856f-69bbf6f59acb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2020152214138_aid0001.tif
EDSCEOF