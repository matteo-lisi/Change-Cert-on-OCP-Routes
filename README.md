# Change Custom Certificate on Openshift Route
The Script scans the routes present in all the namaspaces, and selects interested routes through two variables `ROUTE_HOST_FILTER` and `CERT_CN_FILTER` appropriately set before execution.
The output of the script is two files, one of reports in CSV format and the other in sh format containing the `patch` commands for the certificate change.
> **N.B. The script does not change the certificates but only generates the file containing the commands for doing so**

## Predisposizione
> **N.B. Before running this script you must run the `oc login` command**

- Clone this git Project:
- Copy the new certificate and key into the folder containing the script.
  Modify the following variables at the beginning of the script:
  ```bash
  cd Change_Cert_on_OCP_Routes
  vi Change_Route_Cert.sh
    # -----------
    CRT_PATH="path-certificate" # New Certificate PATH
    KEY_PATH="path-key" # New Key PATH
    ROUTE_HOST_FILTER="route.example.com" # Filter on the HOST field of OCP routes
    CERT_CN_FILTER="*.route.example.com" # Filter on the CN field of certificates contained in the selected OCP routes
    # -----------
    ...
  ```

## Ricerca Rotte
- Run the script:
  ```bash
  ./Change_Route_Cert.sh

  # If you want limited to only ONE namespace:
  ./Change_Route_Cert.sh <NAMESPACE>
  ```

## Patch Routes
- (**Patch Selective**) Open the ***"Report_routes.csv"*** file and copy the last column of the file containing the *`oc patch`* command for each desired route, put them in a file and run it.

- (**Patch Massively**) Execute the ***"patch_routes.sh"*** file to perform the massively operation.
  ```bash
  chmod +x patch_routes.sh
  ./patch_routes.sh
  ```
