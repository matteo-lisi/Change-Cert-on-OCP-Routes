#!/bin/bash
# -----------
CRT_PATH="path-certificate" # New Certificate PATH
KEY_PATH="path-key" # New Key PATH
ROUTE_HOST_FILTER="route.example.com" # Filter on the HOST field of OCP routes
CERT_CN_FILTER="*.route.example.com" # Filter on the CN field of certificates contained in the selected OCP routes
# -----------

# Output File name
CSV_FILE="Report_routes.csv" # Report with all routes found
PATCH_FILE="patch_routes.sh" # Script file with oc patch command
ROUTES_BACKUP_DIR="Routes_Backup/$(date +%Y%m%d-%H%M)" # Created Directory with backup to actual routes in yaml format
# ----------- STOP to Customizable Variables -----------

CERTIFICATE="$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "${CRT_PATH}")"
KEY="$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "${KEY_PATH}")"
PROCESSES_ROUTE_COUNTER=0
# ----------- END VARS -----------



function process_routes_for_namespace(){
  local namespace=$1
  echo -e "\n##### Namespace: ${namespace} #####"
  for route in $(oc -n "${namespace}" get route --no-headers -o custom-columns=NAME:metadata.name); do
    HOST=$(oc -n "${namespace}" get route "${route}" --no-headers -o custom-columns=HOST:spec.host)
    if [[ $HOST == *"$ROUTE_HOST_FILTER"* ]]; then
      route_ssl_cert=$(oc -n "${namespace}" get route "${route}" -ojsonpath='{.spec.tls.certificate}')
      cert_enddate=$(echo "$route_ssl_cert" | openssl x509 -enddate -noout 2> /dev/null)
      cert_subject=$(echo "$route_ssl_cert" | openssl x509 -subject -noout 2> /dev/null)
      if [[ $cert_subject == *"CN=$CERT_CN_FILTER"* ]]; then
        OC_PATH_COMMAND="oc -n ${namespace} patch route/${route} -p "\''{"spec":{"tls":{"certificate":"'"${CERTIFICATE}"'","key":"'"${KEY}"'"}}}'\'
        echo -e "\n  ================="
        echo -e "  Route: ${route}"
        echo -e "  # Namespace: ${namespace}"
        echo -e "  # Route: ${route}"
        echo -e "  # Host: ${HOST}"
        echo -e "  # Cert Enddate: ${cert_enddate}"
        echo -e "  # Cert Subject: ${cert_subject}"
        echo -e "  ================="

        # Update CSV
        echo "${namespace};${route};${HOST};${cert_enddate};${cert_subject};$OC_PATH_COMMAND" >> "$CSV_FILE"
        # Update Patch File
        echo "${OC_PATH_COMMAND}" >> "$PATCH_FILE"
        # Backup Route
        oc -n "${namespace}" get route "${route}" -o yaml --export > "${ROUTES_BACKUP_DIR}/${namespace}__${route}.yml"

        PROCESSES_ROUTE_COUNTER=$((PROCESSES_ROUTE_COUNTER+1))
      fi
    else
      echo "  Route: ${route}"
    fi
  done
}

function initializzed_file_and_dir(){
  # Initializzed File and DIR
  echo "Namespace;Route;Host;Cert_Enddate;Cert_Subject;OC_Patch_Command" > "$CSV_FILE"
  echo "#!/bin/bash" > "$PATCH_FILE"
  mkdir -p "$ROUTES_BACKUP_DIR"
}

# MAIN
if [ -n "$1" ]; then
  CSV_FILE="Report_routes_${1}.csv"
  PATCH_FILE="patch_routes_${1}.sh"
  initializzed_file_and_dir
  process_routes_for_namespace "$1"
else
  for namespace in $(oc get ns -o name --no-headers | cut -d "/" -f 2); do
    initializzed_file_and_dir
    process_routes_for_namespace "$namespace"
  done
fi

echo -e "\n\n######## Processed $PROCESSES_ROUTE_COUNTER Routes ########\n"
