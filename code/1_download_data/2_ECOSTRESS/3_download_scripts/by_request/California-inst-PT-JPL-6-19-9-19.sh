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
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/81047789-4d4d-421d-8259-0a3eb234b6e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019152232302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/227849df-e8c0-421f-ad1d-6c7fd7604213/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019152232354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bdc09165-5fe3-4650-8c0d-fc6885c05daf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019153223337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f2410f2d-4550-4d76-9db0-f829118a92e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019153223429_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d7921aa3-c0c1-4642-8697-e98e34130a89/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019154214409_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c3246401-40bd-4938-8339-92a07c7472e9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019154214501_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/126dc4ff-7a29-43c4-9f6b-ac51163c6e9e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019155205511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/39a22f37-5730-40ac-90c8-534e886709d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019155223144_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/71589bcb-cdc5-4e92-942b-6179ab452259/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019155223236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/17e83004-41a3-4e63-9212-4135afd21a57/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019156214148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8be565d0-2dc8-4219-9c56-6b4e49b506dc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019156214240_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/76116145-f4ac-4ffe-98f6-b814622345cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019157205219_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b479cd7e-fe17-4860-8b46-e1f5eefafb68/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019157205311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1475a39a-2d21-431b-9f86-234f9ae05b3a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019158032135_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6612fb28-21c3-4e89-85d5-4b40b490f657/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019158200258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d2cc2d46-5b3c-4f66-bde2-e1b2912e5a42/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019158200350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/29e45aec-5b7f-448e-8ac3-4b86da924224/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019159205018_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4248223b-ab56-425b-bf4e-19b58b9d4b64/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019159205110_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8a7fa1b4-46c0-44c5-9716-582e15384a7d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019160031949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e4531435-8991-42c9-a3b5-3d3f0784d491/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019160200116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/70df5439-0983-4534-ba01-4d4da19ba3c1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019161023053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/300eec0e-522f-41fc-89ca-9ff11859e916/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019161023145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/565a7364-34f4-4163-82da-16289e0504a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019161023237_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1ede21e2-fef9-4899-8ddd-b0d87ab9244f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019161191105_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4c2351c3-2039-43e5-8dd2-b5629e3e0403/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019161191157_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/27306c57-d005-47d3-873d-88591c99205a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019162014055_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a23dfe94-d765-49e9-b4c0-944c89a67cda/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019162182151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4ebf957f-39d8-4f4b-a884-7274ac2fa338/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019163190842_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/69c9ee34-ddd9-4a64-8540-ccb701c99968/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019163190934_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ef31d02e-83c2-4520-a556-e9c1a0018b17/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164013816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/258a652a-2b83-4174-86f7-505b834db724/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164013908_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/39815c3f-be05-4fbb-bf65-c56eb95a67e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164014000_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/eef523fd-352d-461d-a807-59ac04fe8005/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164181917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/29eb29dc-7744-433e-890b-56b6519cc6b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019164182009_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/91324f76-809f-4233-9801-78b402b5fc69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019165005052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/05913f42-aba1-41ad-bd0e-eddf7e577883/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019165172949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/cb67bfec-d61a-4a12-a168-0cccc71e8340/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019165173041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/551f7e70-27f4-4c0d-9020-262b1e4c9e74/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019165235911_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2553a97c-bc87-4046-bcd8-b60b05fd5c85/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019166164031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/92fc6836-4889-4ba2-8e5b-11cf6c8f1163/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019166164123_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/101dbddd-1d48-4e37-9997-31f0eb64e525/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019166181756_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7c8847dd-4c7b-407e-a1a8-470e5a7bc58e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167172723_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d1cddbdd-e2c8-4cb8-aa0f-4a84d1593c28/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167172815_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5e6c44f6-7f9d-4884-b8d5-dec1a1748694/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167235642_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/149ec7bd-6cc1-4599-920b-9db3a2f30c8c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167235734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/07b691d2-25aa-4a14-96a8-57f24c7a7db2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167235826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ac42b138-05c9-4c14-8321-3a4cfe5e4b5e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019167235918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ae1aea61-3c1d-4ca0-bed4-307ab07babf9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019168163752_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e59fb0e6-447a-4059-ac30-68da3bc5285e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019168163844_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d1df3bee-d6c3-4134-85da-5d738647dc12/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019169154827_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c17d69aa-0100-4ea9-a43e-ef0cab38f7e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019169154919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/58eb7569-7135-4d9e-b094-53df4354d0c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019170145923_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/786e8b2c-1301-454b-b4ff-9871fa4894e8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019170163541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f42f9d34-bd67-4e6a-b27d-7a2495fdcf53/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019170163633_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bbafca96-68a4-4d86-be52-e53ed4f514c8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019170230749_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5991f993-2dde-4fea-b720-f1084e51e305/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171154606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/05a8fdf1-d2b5-4eab-9249-91ad05dcec64/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171154658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7f0a031c-184f-4e11-9c94-201a256bb7d4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171221503_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/75a3c806-7282-4452-ac2c-323e2468289a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171221555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9370ea63-05db-49f1-97bb-ae3182737a83/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171221647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/eb9b6f87-245c-4d39-8425-3c1303db4f50/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171221739_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f50ad6df-5788-497d-92ab-2cadc6614abb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019171221831_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5745ff52-aa98-4cc1-96d1-1c6643055eb1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019172145635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/75091ed8-9f0c-412f-a178-6658cbc132fc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019172145727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/69af4899-2741-4e4d-ba2b-76b5b681325e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019172212542_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a59b2424-a2f0-4261-80fd-4a0176c18108/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019172212634_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/37eb0de9-9553-44cc-b97e-225cf1abb6b9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019173140712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/40d4ee69-9e06-43bc-ac48-35cd65f101d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019173140804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/89762444-6cf1-452b-b72b-1745a51c995d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174145419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/fe8fe822-2412-44b9-9bf0-d562804e4ac6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174145511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/991ad31b-2768-4e04-8292-79d600a056a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174212350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/14bcf61a-5ad3-4e0a-9388-3c933b8b5168/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174212442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/64ba6e96-2ab7-4015-a0f1-ea200ded3218/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174212534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/54f6f75e-3551-4868-9cd8-9cb4fb6a19cd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019174212626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9f3aa549-a17f-480f-92d5-bd9e38304ea9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019176194439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e10dbb18-22eb-46e8-832d-5a25fb355047/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019177122642_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/24132ce1-e4f1-42bb-868f-f508d25c71ea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019177140246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e36fd536-44a8-46d5-b399-7e37c51e32e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019178131247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b279ecbd-e849-498f-8ba1-fe6376fad529/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019178131339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e3c08e86-091c-425c-abb1-de23a96170a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019181185158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f85e82df-0ec4-49a0-b22e-748fb7620077/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019181185250_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/39adb15c-b537-4b08-996a-6822b2d85ffa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019182180108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/aae0d5fd-e885-495f-bdc8-4f020f887680/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019182180200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d34f3c20-3f60-418b-b694-42ac62c065e1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019182180252_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5beee4db-231e-4794-9691-5886c98e2cab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019182180344_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/43d52ff5-5900-4953-9aa6-06e4d9c61683/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019183171119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ded3a3b6-50c8-44bb-8510-de65a59e84d8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019186162007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6ba5031f-8b28-4a25-b283-30995a5b5040/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019186162059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5a425855-f0f7-4d0d-a0d9-97f084da6d04/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019186162151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/cd5cdfe8-cfc4-490f-8004-c29698e203ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019186162243_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4a07b79a-5f77-482d-aa58-de2baf1ddbfe/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019187153041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e8a72bd5-37eb-4be7-bf8c-d4bb8d13efa8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019188161921_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9e4fa8b2-d085-45c6-873d-b17d6eeff9f9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019188162013_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0da9b103-1c66-4311-8d34-aa54227a58e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019190143956_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9df853e6-65a0-4acc-b495-679245f1e774/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019190144140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/51f68dcc-5566-4d94-9663-47c8e7ec2c22/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019191135024_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bacd7830-a4a5-4d9b-a444-8886b8cde3d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019192143813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a2f1c33b-a90b-4b0a-99a5-e001abb3b57c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019192143905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1302cb22-f296-43ba-aa3f-fe598cdd4057/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019193135044_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/56d39955-a547-418d-8550-4ff19f233e20/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019194125902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c008d3a8-0524-4ab4-b833-3539a975cc69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019194125954_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1a4b6ee1-18c5-4907-870c-924b8020cfe6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019196125950_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/11fa2651-07e1-4996-b4ac-4376259ee208/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019204030601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e163a0df-94c9-4852-bdc1-7c3611022030/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019204030653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/12eb2caa-0fad-4ff6-aa33-dfff0268ba69/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019204030745_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9f670274-da3e-43a2-acc7-267e6e7c40e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019205021709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b0c850a2-3d8d-4a5d-8bc7-f5ec33b039b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019205021801_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/56ed0395-9573-4c42-af7c-e06c92c4cc95/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019206012751_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/dd922475-d110-4890-9fa8-a74cb1750291/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019206012843_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8e73d25b-3fb0-4ef4-bdc7-cf237585dcd1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019207003845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c893d978-8e07-483e-8c1a-fea761661753/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019207003937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b2d2aad4-2d97-462a-bb98-4062a79dcdc9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019207021622_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b946460b-b59e-47d7-9fc0-2cfd43a3764d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019208012553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2306c269-6e91-4b1f-9647-783689e6341b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019208012645_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/30ebe33d-4682-413a-b523-92314c0aabff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019209003635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b4efbc80-9484-4f43-8adb-0ce869ad77b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019209003727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/82a087b8-94fb-4bd8-a0a0-56b8ec1b46a1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019210225824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/27a311b2-6224-484f-af04-d8d6c7d3b299/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019211003448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/061ec4d2-01ab-4c25-90ed-f65eefb059ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019211003540_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/fb559f41-d0c6-4ee3-bf9d-8dec37a07c8a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019212225557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1bd35ec6-8f9b-40ef-80b8-dc5f66f761b4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019212225649_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7e4683e8-feb2-4ea1-9fba-c7ad14113a54/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019213220644_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f639bd10-87ee-4181-b1aa-2f57112bbfa5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019213220736_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/67321483-78b8-4732-8cc5-3244e9eb2e57/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019214225401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0e12139b-7f03-4aa0-94be-70137224de07/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019214225453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/08172d17-c548-43a8-b7a1-a505334c2d19/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019215220442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/35f43891-dddc-4a0d-8066-37765442608d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019216211518_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3f30ca59-a55a-4afb-b6c2-e6f162e1d50b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019216211610_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/edd9632c-4f0d-48f5-9a3e-9a1925315cf1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019217202600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/04e4d2fd-f993-4451-9678-34c8c042ee52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019217202652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7fa23e25-5d52-4291-804d-a10e1d0ab34a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019218211316_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/061a8fd9-5ce5-433a-8b88-c2144c4ec91d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019218211408_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b6bf1fc9-5fea-47b2-9799-cf5dc4daa926/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019220025350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/35bf29a9-e0d8-478b-905c-cff309fd6d2e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019220193441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f1a46373-a3c4-4eb8-9126-a6206cc36e01/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019220193533_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/57228eac-dca6-4440-a448-b3b6fc900679/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019221184542_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/78420b50-4690-4c02-ad62-5adbe2bab4ea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019222193241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2f9bdf36-1df9-437c-98fe-bd60ddb8ba67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019222193332_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3c2c53e2-ca81-4d0b-9502-872168f280eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019223020155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/cbe51f4b-973d-4ba7-a5b3-521ded53ecb7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019223020339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/95cf3eee-191f-4f91-a81b-160b09aae03c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019223020431_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bba4e545-2034-45a9-9389-411b4606d71c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019223184311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/30ffb2c3-9973-49d6-b6d4-08196ad02195/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019223184403_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/30292a56-d559-4145-8c2e-e4159b961334/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019224011253_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5fb10a03-3ae3-49ae-b5d8-66cf109729a6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019225170504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bbdb8178-e8e6-42f4-a344-88f8273a288a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019225184208_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f40b5b68-8c50-4d14-bcc2-9164b67065ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019226175155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e06eee4c-2d3e-42f3-a433-a12d957e121a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019226175247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/76d16ef3-2268-4a7c-8bff-576729162355/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227002102_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b70c9994-ac4c-4559-a169-be71dcd456ec/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227002246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/12c52ad0-0cf0-4bb3-a4a7-7f90baf88862/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227002338_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c42e47a6-4dd7-41f4-83d6-f9a65385311f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227170241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9c116421-f1de-44ce-8b94-d03562b4fc11/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227170333_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/34038742-4b08-49f1-ad97-a99f6ce7c76c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019227233214_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/65b571a6-83c2-4bf7-b003-54233928510d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019228161411_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e4465efa-c00c-4222-af08-5bd049974e54/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1f88e00c-b2f7-45b9-9c55-0db06ac9d228/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229170203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5247825d-8f35-4ae1-aa20-272d04cfebc6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229170255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4cf34be3-317f-4800-8d50-073109ff969e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229233140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/95ef2643-56ec-410a-a145-115b12469b1a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229233232_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/573cd3fe-623e-4a44-8c23-10313ed2c737/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229233324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c8ec29dc-c68f-468e-9464-e1ed32e3fb72/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019229233416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4abfdfba-3016-4cdb-9a46-6f3271433c38/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019231152436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d53ea4c0-98d7-4aad-a18e-060eded0b5bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019231152528_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/18aa8e21-2e5a-43aa-92c7-6de7a441a536/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019232143601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7b03eec5-f428-4c92-b377-fa92817b6c2b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019232161300_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4269d88b-0ebb-4d80-bd51-5a3cb4a24e7c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019234143457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d8f44015-78d3-415e-bbe7-7ee10122e6e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019234210456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3ec6d312-3dbd-472f-92a6-4901b614f73a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019235134612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ec55eaa9-c769-491f-b26b-e2d3d28429bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019235134704_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c56f2949-05ea-449f-bc7a-3b73017a2542/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019235201603_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d615dcb3-091b-47ea-bb6c-d397bd7e7ebf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019236210451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/29d47425-a95e-469b-bb0d-8ea1bffc9b47/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019236210543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/692dca5c-3f3f-4319-b2f7-7aeabda69cbd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237134529_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a3f3cf9d-3820-4ada-9d06-b1a99b864b65/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237134621_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3333cfab-3016-4fcf-9f23-5b2a5054c5ab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237201435_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/df35d906-62f9-4b20-8f9d-bf85a90e4796/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237201527_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5f2951db-c40c-4e26-8973-8b5ffd1ae1ea/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237201619_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f918bb0d-678b-412e-96cf-5badf575e3f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237201711_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5cbd3445-2743-4696-9b8b-84817f94b4db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019237201803_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8219fd02-5c7e-400d-ac9d-72517f315fe5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019238192623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/146da1e4-e04e-4a7e-acc4-bf67db8588c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019238192715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a60c5095-1b57-4c87-b9ef-80e8eec573ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019241183712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/aae61e05-1d2e-4894-96b2-30070a478d57/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019241183804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/27327f0e-45f4-449c-ab30-d48e930fcf98/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019241183856_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e2d55122-c128-49ea-988b-16f6c4a06368/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019241183948_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c367a942-2ff6-4252-959f-e39eea030941/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019242174808_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/789b6fb6-c8b9-4319-a555-c970290f1f98/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019244174728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/36b72276-9a25-4da4-97b6-5e60183b4514/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019244174820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e4014482-d04f-488f-9e34-d1eacfc0d979/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019244174912_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/50389d7a-ef6e-48d6-8e72-c29e2a60b84e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019244175004_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8d975e70-33f9-4d1a-bbdf-ab3bfb54986f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019245165803_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/12787535-1c62-4a62-b594-cbedbad38d55/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019245165855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e05bf649-3546-49ba-acdc-ba63819bc317/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019245165947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c9138744-4347-4293-a664-958bb99bfd9b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019245170039_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6b013f5d-63c2-4fb5-956b-1d4c39c1a523/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019246161006_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e0837dc5-c58f-4002-bbcd-2597fc060220/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019247165927_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f288094e-aec2-4c5f-82c1-5c7417a0ac9e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019249152011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/459f034c-477c-4553-917c-909973ec53ae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019249152103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0e251fb9-b1bb-42c2-a886-a6f4bc5c9cf4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019249152155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a294a685-149d-45cb-93f3-635a677699d5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019249152247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6e4c4458-edcd-4215-8e9c-32bc0ee9c376/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019250143120_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ecebbf66-9531-43a4-a721-bfa0c7ec3858/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019251152025_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/637c844e-16a7-4a03-a1fd-fbc70eeb4924/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019251152117_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/cbd79318-f058-461e-a11b-ac64c04e540d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019253134205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/09eb20da-914a-4f40-8902-81ec0617c903/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019253134257_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7fbc0ea3-7f01-4629-8fdc-4bd74e39d4d7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019253134349_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e602a5b7-8aff-41cf-92fd-855ee78e0642/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019255134258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/36c4fd73-b047-456c-945f-abb47e1c327d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019266013037_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/da87bde4-3c76-40ea-897d-268d405c74c9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019267004240_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d484b912-90ee-4d67-8547-0bf272225474/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019269235333_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c02b86a7-7141-4077-8d32-813c1f948feb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019269235425_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/370edefb-f515-487a-aa48-d0f8f2575c4a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019271235301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/35cf713e-176e-4894-a15e-cd9e67dea884/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019272230444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1ad1c52b-0f6b-496d-a148-7667fced6520/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019272230536_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4a0c330f-8453-48a0-a933-bf9f6bb5f15b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019273221628_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b2a644d7-00f7-407d-bbac-9b0349a2bef9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019152232302_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3b17f15a-f6bd-4b2f-b672-908651d932b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019152232354_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/31041c88-4482-4ad3-a037-e244fb86fc32/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019153223337_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/188dc54a-a367-4c37-ab27-599ec3316f52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019153223429_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8a039245-47b3-4ab8-8e94-ddc367c31baf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019154214409_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/fe47a9e3-0309-418c-beab-850f10b7aa9c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019154214501_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e7b253b2-deaa-4aa4-acf9-c486ab5c0710/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019155205511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b6565299-afb1-46cd-95ba-396104747625/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019155223144_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/637da000-f581-4ea3-9db0-3ed532238a5f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019155223236_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a7f5609a-b334-4e50-80e6-583d9dcfba54/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019156214148_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e36af1f2-49ed-4ce6-89c6-0e773a15ca62/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019156214240_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/dd33b6ec-e1a7-496a-856c-9688444e7e42/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019157205219_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5b884726-7b0b-4abe-add8-2ab14f821045/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019157205311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d796f10a-e8b8-4d95-9b51-fc3ab768af01/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019158032135_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/65dce052-4638-4470-94ee-b85a9ce1fe4e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019158200258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0269e989-8a8a-40e2-976e-e1573a9d60bb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019158200350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8342223d-069a-4fd4-9c4d-e22def07610a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019159205018_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bea6d1ca-c31d-4faf-aa07-37a9e6490728/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019159205110_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4bc7a844-0767-43ea-8a83-7ce3fe470dd8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019160031949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bd2c1a1c-a0ff-4021-abac-079355d767e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019160200116_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/60961e6f-edfc-4dcc-92d6-5b55b498041f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019161023053_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e1eec01d-e102-43fd-a946-c0162fe293e0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019161023145_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4ee058b6-989a-4d73-962b-3d21d6e65fda/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019161191105_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1ca841c7-88f0-4d99-98c6-83a1c1f00a54/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019161191157_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bae52c7b-eea7-4d13-bb43-f449eca589d9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019162014055_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8485df5e-0f88-423c-a3e9-1b1872325d6f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019162182151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1ef256f3-d5de-4dcf-ba53-a9048470677e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019163190842_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/23d3cb68-0b26-4acb-9e63-e3352833d6ed/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019163190934_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e90dd5b0-7d0c-4a20-93bd-58e3fc787eeb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164013816_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1e037263-0f54-4d67-b166-18a585b93321/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164013908_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7cd758c6-a243-4eef-882a-7bfb3c34aa07/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164014000_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c0684bff-9671-4fe1-ba2d-d89ddf316547/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164181917_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4251ca7f-cf11-43c8-a004-0919fe35539a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019164182009_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/513a6d23-59f9-45c3-a4ec-85745cc2bf85/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019165005052_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7accb34a-1e43-461d-bb02-73e9e567f0b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019165172949_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/84bf6d2d-93df-4715-96e0-7a9da110192b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019165173041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/70b7bd82-de9a-4aff-8a1f-bf9c39cfa4d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019165235911_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/35cf2a30-24d7-41f0-9eee-a5d83aef3a34/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019166164031_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/77fae79b-2f0b-4db9-be4c-8c1fa632492f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019166164123_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d799a9bf-b97f-45e1-be58-2c2569d8f7a9/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019166181756_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bc3cefcc-92f4-4361-92a8-0b3c15f1ff7a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167172723_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/35e0733c-bea4-4a08-8b17-4aefa8b8da32/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167172815_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4e6777ac-9f7e-4b90-8174-e87fe5487978/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167235642_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0fad787f-0e4a-4b67-b935-ce55f44b60c2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167235734_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/dd33c38c-f08f-4548-9a37-1bb6e1982e65/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167235826_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/abeff002-2dc7-4a49-9f20-8d3ca3ab0b67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019167235918_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a3326beb-3666-4c2d-b5f9-0085c11d3f6d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019168163752_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/76281951-dba9-4697-a93e-b614e24b77c0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019168163844_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/497c86f8-8eaf-4fc3-ac96-4d3fc2bef884/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019169154827_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/57e2de32-340e-42ca-9cf3-5564191de4b4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019169154919_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2e9f6f3d-0054-4a94-b4fc-05388bac58ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019170145923_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/83cb2a72-d2fc-4be9-8b3c-f3ab9f2a1c16/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019170163541_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ce6e5bce-94af-4dba-b7de-e61ff40a9dab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019170163633_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/111f7103-cc32-4e6c-ac25-949a9595a8bc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019170230749_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8e951555-87f0-4bba-a2ef-572ccb6ec989/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171154606_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bf6f32f8-416d-4695-8bfe-3129d6fab07f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171154658_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3715dca6-ff1b-4479-b31c-2d4888d6493a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171221503_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/854b503d-13ce-466b-b10a-eec2dc659adc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171221555_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/66673ddf-4aa7-4e39-ac0b-749b92c8f8f4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171221647_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e1430058-65db-4a06-8920-fd93bbeb9e73/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171221739_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3d9e1103-95d8-43fb-b53a-ea6e9e7ecf61/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019171221831_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2eeed4b8-bc97-4b86-b2cd-0c11cd807909/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019172145635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/82774b20-44b9-46d8-ae34-fe4b3ac3a378/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019172145727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1a01236f-4d54-4c29-81f3-ba32c5cfac3d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019172212542_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/99034468-b3f8-41b3-9b85-f8f11e0eb7aa/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019172212634_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bd736178-da37-4365-8a29-d8009f5454f8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019173140712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c0599858-139f-40df-bce4-63fca5f6c0e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019173140804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/199f545d-a6f4-4106-9444-a5e145915254/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174145419_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9b0571fa-9754-4fa2-9df8-69705ff365a8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174145511_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ff736325-a749-4f41-851a-35cd33ad3ae8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174212350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/02969b6f-1902-4393-be25-51d1b3e03f52/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174212442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0b3afb1b-0715-43ff-9b9c-fccc1c6a5de1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174212534_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9768199c-8921-4b97-b2b1-d458e57956af/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019174212626_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e3fd5892-1ca3-4de3-ae90-fd183d66667a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019176194439_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d364db32-8abc-4937-9e6d-f1adf880ec43/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019177122642_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d92d354d-d8ce-417c-bc78-608a1b4c064b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019177140246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a2b10eaf-b3cf-4c60-8eea-5c22bd4cd477/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019178131247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4595e8f8-c54d-48c5-a726-2ce3b977ec16/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019178131339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6172389e-0851-45bd-b1d8-0ddb3f4012d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019181185158_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e4dc8c5f-ada7-4cde-b6e3-36524e5b7394/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019181185250_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1f9dbce4-a7f1-4af1-87dc-cc2449951e7f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019182180108_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6324f056-6f58-4581-b356-e3da3e0cab21/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019182180200_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/40927203-efc0-498f-b6ba-54ee89e31dd2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019182180252_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8bda5bb9-5cef-4b49-b387-be390d415c6c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019182180344_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d75a3b25-6096-46a4-a90d-65cc3becf126/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019183171119_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f94449a2-5158-49ab-b256-42f500574d6d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019186162007_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6e3072f9-8657-4a1d-a722-9da43b140d59/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019186162059_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e99e8ae0-b47f-4977-ba97-df7d9ffd35e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019186162151_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/fdcd6d95-3bc0-4950-be85-3b25da5147cc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019186162243_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/75385793-a740-40a3-8ff5-8acc19b4432e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019187153041_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/33c48c6b-b13f-4bb6-9752-e23202c83d8d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019188161921_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7ecb2199-c8ac-4c00-a710-bd701ff4f14e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019188162013_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b25ef0ef-d32e-4051-ad6e-ba5e05f7b05b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019190143956_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9633cfe9-453b-4184-97e6-2ed022d9fdc2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019190144140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ca9d9d93-40df-4aec-81d4-5c6712a2a974/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019191135024_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/53bfd5ab-1272-4701-9021-d3cecdaeedfb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019192143813_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/210f6dd0-6ff4-4adb-8c33-91f0148f17cd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019192143905_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f02e1e66-d25f-4a4d-87c1-34b817c8c4ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019194125902_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/90f7880c-cadf-414a-aac9-34cee950e542/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019194125954_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ee9a6fd1-2c74-47b1-99c9-0cca06fafe67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019196125950_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/118cc63e-4405-4993-bdf6-55786b991907/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019204030601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/fe662b90-1ce1-450e-b555-1b678c1cf728/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019204030653_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5ed74877-ced3-467f-b99a-38ae3bad6742/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019204030745_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d27bedfa-83e4-428d-ad07-8e5d96c3e2e2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019205021709_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e8c078b7-8f21-40ba-96b3-34b2d25a88ab/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019205021801_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bc75e5a4-b57e-4fd9-9052-07ddd24aa800/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019206012751_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/28d68bb1-2fac-4400-9cde-a1879a124a47/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019206012843_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ed27a7bb-3289-4f85-b41a-caba9a25e1d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019207003845_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d91c58be-6ef1-4110-b4ea-9f0c3d23ec14/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019207003937_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/976bf167-6206-4b37-b108-0d1743d9864f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019207021622_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/21b3c7d0-f63f-4c3a-a9ee-86105cd029a5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019208012553_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/52210de1-b2df-4079-95c8-83680ecec265/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019208012645_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/eb7c6304-d3ee-4df8-87f7-e919c5493f56/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019209003635_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2af9efc1-c394-4d1e-a008-17adfe6bbb8d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019209003727_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/00deabe4-d52f-4208-9867-ea9c67e2169d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019210225824_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/82e474ef-0aca-4c4f-8cca-d4e8f126b3b2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019211003448_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9190edcf-771a-4740-bd8d-7977ef829797/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019211003540_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2326f2f0-13f4-4397-b388-79e9bf99edac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019212225557_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/07889b37-3e5d-4ad2-a5f4-688f73c484b7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019212225649_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5ad18ab5-a0f8-4a3e-87db-39b894735dce/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019213220644_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ba482c17-7af6-4c8a-9c80-3f3c1dbe808b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019213220736_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/008f4e0e-d6ab-438b-a0a0-f69c908723f6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019214225401_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/37dd5ad2-874e-4ecd-9a16-3d269db5bd0a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019214225453_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/056a15c8-a4d7-4c04-b83b-2005bf4717e3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019215220442_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/50b8a313-eafe-486d-ba9d-bbbf54b82b2b/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019216211518_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/aeed1fc1-6141-4b18-a938-311a5a2cf5b1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019216211610_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1a543c43-8a1b-43d1-9c06-10eace037456/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019217202600_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/dbcd2d11-0a1e-4fea-9be3-cfb3623bfb01/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019217202652_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/606b62bc-8191-493f-a91c-571fe5c90206/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019218211316_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0cd1362d-b25d-405e-b74d-6496d4e2e0db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019218211408_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4a27b40b-36ca-4958-896e-880df3ffb690/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019220025350_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ca630192-74f5-4135-84a2-b8c07c1130ee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019220193441_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3f2e8ded-baf0-479b-8a8f-4366b48a82c6/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019220193533_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b55bd341-15eb-472c-8200-8e1f6e0aa48c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019221184542_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0f6a2247-d33d-4dcc-968c-b05c7c2e236d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019222193241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5f5d2af7-7f42-4a14-a007-00cb767a153d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019222193332_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/304b4fac-32b7-4673-8dd4-b7fedac7b5f7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019223020155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bb7ca0dc-134f-424a-a27a-87d81171e5ac/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019223020339_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e1c15eb6-4af4-4240-964a-f453a24f49d0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019223020431_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2e5430a6-1bd9-47af-b643-9937a5c9ede3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019223184311_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e80346c8-b592-4a5e-a6a5-231cd3a8aac8/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019223184403_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/50f9e043-e423-430f-bb1e-ba2fea30b234/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019224011253_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/76653584-8c50-4a60-8267-246ea91abbad/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019225170504_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6768b709-f1dd-4618-a333-12de68540600/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019225184208_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5ed71a6c-efb8-44d3-a9fb-b8986561af92/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019226175155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/8faaefb4-c4a8-4862-bb12-8c8125ef6c5a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019226175247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/40368120-b84c-472e-b0dd-8b373400bf08/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227002102_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b19bcdf9-3c6b-402a-b87d-4cdb49d2b460/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227002246_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2b4bd7d3-10c7-472c-bb26-e704c94f6e7c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227002338_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c7be9632-1431-4728-8e05-d5a7b13539c7/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227170241_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6424e113-8a66-4a14-8af3-59c20fe46cb4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227170333_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a667ee9d-64e6-4c22-b4e2-cdaf78876dcd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019227233214_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b8930b39-3953-4017-8423-a6cd2fb19295/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019228161411_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/04373365-a863-4917-a7c4-89e25a5ce660/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229002207_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/152fbd11-9cc7-4f17-a70a-a4e3ae6db8a4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229170203_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/7020b9b4-c23e-40ac-a154-ea495c3010de/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229170255_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a89fce59-4675-43ed-8e1f-ba43eafa9182/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229233140_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6c33ca13-eef7-4878-ac0f-0b106bbaef36/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229233232_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ee4cdcd0-9079-49fc-bf22-888b5c0538ff/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229233324_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e2b245a6-0150-4bd6-91dc-adf54cd2f985/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019229233416_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/17cdd4b5-d4e2-4103-8751-9d36b338fcc5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019231152436_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2f479da4-1ec6-441c-b169-f2876d1f3950/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019231152528_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f08d37e4-17a9-421f-8fb2-c5418d172771/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019232143601_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a5669bc8-b8bf-4caf-b2e7-3642f17b82bd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019232161300_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/9f194454-cca2-4684-b5cc-79ca15450cfc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019234143457_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/185ecb87-8df1-4f71-861f-c0b90a5e782c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019234210456_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/68c2c886-744b-46a5-b790-ff7a2109ebee/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019235134612_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/0684241f-5eaa-4587-a6fe-22899d06c35e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019235134704_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a3f8df88-67f3-441f-801a-1d96ff41e80a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019235201603_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/5e1893c1-67e9-41ee-b691-5d2e95f9a5f1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019236210451_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/47ae7c39-c3ba-405c-b67f-35033033371f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019236210543_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/edb2c375-99aa-4d0f-86d5-9b4278e0693e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237134529_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f989d086-a8ca-4026-a15d-c89a361e0d7d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237134621_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f8afecde-a812-4790-b060-693fa55654e5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237201435_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d28c017c-7af8-4747-b5f3-c28739ac6293/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237201527_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e8c5cb14-2178-4ef3-9ef2-c3a12dce38ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237201619_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e2bf3771-1ee3-49cf-a829-2cb99029bb43/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237201711_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/b9bf7975-ff4c-491b-b0d8-942a243a1d9f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019237201803_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/90171e73-6546-4516-958e-9f9574a21ae0/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019238192623_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/87f86417-5abb-4176-9817-4abfbec9aadc/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019238192715_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f8a2b3d4-0648-4a7c-9838-87f37d3d11db/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019241183712_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/bc4d671b-0239-400f-bfed-cbc2d24b841d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019241183804_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/204c8770-589b-4ce7-a674-183c794e266c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019241183856_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/df7ab370-7f97-46cc-ae9d-990d940552f2/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019241183948_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/55640c26-b3e2-443d-b87a-d13f15ee3b78/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019242174808_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4371fbc2-2111-4223-81bf-d082786d422a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019244174728_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/dc0f5996-2c4a-4b74-b7f6-89e6d18b31d3/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019244174820_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/60c6b6b5-e5d3-4f39-a8e7-64eb5e64735f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019244174912_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/625ac190-2b21-4157-b2e9-0d7af17d9057/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019244175004_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/df765bd3-90a4-4d69-8abf-1e9b23a239eb/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019245165803_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/6c66e752-5342-4a16-9e11-6d3979041ba5/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019245165855_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/accd2b5a-712a-46b7-9fd2-970d01102c35/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019245165947_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/3decc0aa-18d4-461a-a7e9-013ab8abd8cd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019245170039_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f0c8217f-9199-42c4-a5e4-6678b75ad771/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019246161006_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/d447722a-d6a0-45de-8086-1623f5eaa5ba/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019247165927_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c44a5bbd-0c25-48a0-ab33-0825ff98d081/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019249152011_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/62d61260-e0ff-4463-8c57-bd807424a32d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019249152103_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/18051acd-7c26-43c7-a9af-c3210797e517/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019249152155_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/f6c3c3f1-347b-4bc7-bc8b-9978dfc4c80e/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019249152247_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/119ca02a-5052-4750-8956-80a8f3b68801/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019250143120_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/20d1c7fa-2fdd-4c12-a280-4afb67a984d1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019251152025_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4b98ce0e-d477-4077-ac22-ac2d234280fd/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019251152117_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/ee5d1b1c-258a-4674-a2cc-4487a5ddf82f/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019253134205_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/a4cd201c-d90a-456c-b6c2-eddd827604e4/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019253134257_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/19f630f5-ccc1-45e2-8ec7-5d6e59fb9c67/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019253134349_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/2394eb9c-6d79-4cda-9268-f41d67714540/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019255134258_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/4e884162-e078-4b13-8e92-fad24dc0e97c/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019266013037_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/dd39a29b-1b6c-41a0-94fd-c6c51160639a/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019267004240_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c5161800-f90b-40ce-ab09-a3317389bfc1/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019269235333_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/e702265f-c30e-46a6-b560-8150a0d0dd4d/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019269235425_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/c4bbdee7-c1ec-45d5-8a20-378f6dbf60cf/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019271235301_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/cb03220c-9634-4a4e-b62a-4a2942451e30/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019272230444_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/316d00d0-7189-40f2-ae8d-aca466c9baae/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019272230536_aid0001.tif
https://lpdaacsvc.cr.usgs.gov/appeears/api/bundle/cebac0f6-be98-4b47-aca7-2e8ee9f11260/1a95b10d-84a3-47f5-af67-7e299c40d1df/ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinstUncertainty_doy2019273221628_aid0001.tif
EDSCEOF