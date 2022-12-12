#!/bin/bash
printKomodorLogo() {
    echo "
    
    
                      ▄██████████████████████████████████
                   ▄██████████████████████████████████████
                 ▄█████▀                              ▀█████
                ▐████▀                                  ████▌
                ▐████         ▄▄▄            ▄▄         ▐███▌
                ▐████       ▄█████▄        ██████       ▐███▌
                ▐████      ▐███████       ███████▌      ▐███▌
                ▐████      ▐███████       ███████▌      ▐███▌
                ▐████       ██████▌       ▐██████       ▐███▌
                ▐████         ▀▀▀           ▀▀▀▀        ▐███▌
                ▐████                                   ▐███▌
                ▐████                                   ▐███▌
                ▐████                                   ▓███▌
                ▐█████▄                               ▄█████▀
                  ▀███████████████████████████████████████▀
                    ▀███████████████████████████████████▀
 
 
 
 ▐█▌                                                       ▐█▌
 ▐█▌                                                       ▐█▌
 ▐█▌  ▄█▀   ███████▄  █████████████  ▄█████████████  ▄███████▌ ▄███████▄ ▓█▄███
 ▐█▄██▌    ▐█▌    ██  ██   ▐█▌   ▐█▌ ██          ▓█▌ ██    ▐█▌ ██    ▐█▌ ▓█▌
 ▐█▀ ▀██   ▐█▌    ██  ██   ▐█▌   ▐█▌ ██          ▓█▌ ██    ▐█▌ ██    ▐█▌ ▓█▌
 ▐█▌   ██▄  ███████▀  ██   ▐█▌   ▐█▌ ▀█████████████  ▀███████▌ ▀███████▀ ▓█▌
"
}

printEnterClusterName() {
    echo "
                                                                                                                             
                 ,--.                          ,--.                ,--.                                                      
 ,---. ,--,--, ,-'  '-. ,---. ,--.--.     ,---.|  |,--.,--. ,---.,-'  '-. ,---. ,--.--.    ,--,--,  ,--,--.,--,--,--. ,---.  
| .-. :|      \'-.  .-'| .-. :|  .--'    | .--'|  ||  ||  |(  .-''-.  .-'| .-. :|  .--'    |      \' ,-.  ||        || .-. : 
\   --.|  ||  |  |  |  \   --.|  |       \ '--.|  |'  ''  '.-'  ') |  |  \   --.|  |       |  ||  |\ '-'  ||  |  |  |\   --. 
 '----''--''--'  '--'   '----''--'        '---''--' '----' '----'  '--'   '----''--'       '--''--' '--'--''--'--'--' '----' 
                                                                                                                             
"
}

printSuccess() {
    echo "
                                                 ,---.,---. 
 ,---.                                           |   ||   | 
'   .-' ,--.,--. ,---. ,---. ,---.  ,---.  ,---. |  .'|  .' 
'.  '-. |  ||  || .--'| .--'| .-. :(  .-' (  .-' |  | |  |  
.-'    |'  ''  '\ '--.\ '--.\   --..-'  ').-'  ')'--' '--'  
'-----'  '----'  '---' '---' '----''----' '----' .--. .--.  
                                                 '--' '--'  
"

    echo "Open https://app.komodor.io/ to start using Komodor"
}

sendAnalytics() {
    echo ""
    # argument 1: event type
    curl --location --request POST 'https://api.amplitude.com/2/httpapi' \
        --header 'Content-Type: application/json' \
        --data-raw '{
    "api_key": "095eb9099b756ffd36a3258c77b6bca9",
    "events": [
        {
          "event_type": "'$1'",
                "device_id": 111111,        
                 "user_id": "'$USER_EMAIL'",
                "event_properties": {
                    "email": "'$USER_EMAIL'",
                    "origin": "self-serve-script"
                },
                "user_properties": {
                    "email": "'$USER_EMAIL'",
                    "accountOrigin": "self-serve",                    
                }
        }
    ]
}' >/dev/null 2>&1
}

STEPS_COUNT=6
DEFAULT_CLUSTER_NAME=default

printStep() {
    echo -e "-------------$1/$STEPS_COUNT----------------"
    echo -e "$2\n"
}

isValidClusterName() {
    # this validation is according to kubernetes valid resource names
    # You can learn more in here: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/
    local CLUSTER_NAME=$1

    if [[ -z "$CLUSTER_NAME" ]]; then
        return 0
    fi
    if [[ "$CLUSTER_NAME" =~ ^[a-z] ]] && [[ "$CLUSTER_NAME" =~ ^[a-z0-9.-]+$ ]] && [[ "$CLUSTER_NAME" =~ ^([a-z]([a-z0-9-]*[a-z0-9])?\.)*([a-z]([a-z0-9-]*[a-z0-9])?)$ ]] && [[ "$CLUSTER_NAME" =~ [a-z0-9]$ ]]; then
        return 1
    else
        return 0
    fi
}

getValidClusterName() {
    local KUBECTL_CLUSTER_NAME=$1
    # set stripped cluster name as global var
    STRIP_CLUSTER_NAME=$(echo $KUBECTL_CLUSTER_NAME | cut -d "/" -f2)
    isValidClusterName $STRIP_CLUSTER_NAME
    if [ $? -eq 1 ]; then
        echo $STRIP_CLUSTER_NAME
    else
        echo $DEFAULT_CLUSTER_NAME
    fi
}

getUserCustomClusterName() {
    echo -n "Enter cluster display name: "
    read -r FINAL_CLUSTER_NAME
    echo
    isValidClusterName $FINAL_CLUSTER_NAME
    if [ $? -eq 1 ]; then
        return
    else
        echo "This is an invalid cluster name. Using default cluster name."
        FINAL_CLUSTER_NAME=$DEFAULT_CLUSTER_NAME
    fi
}

userChooseClusterName() {
    local USER_CLUSTER_NAME=$1
    printEnterClusterName
    echo "Choose your cluster display name in Komodor"
    echo "1. $USER_CLUSTER_NAME"
    echo "2. Enter cluster name manually"

    echo "Enter your choice [1/2]:"
    read choice

    if [ "$choice" = "1" ]; then
        echo -e "You chose cluster name: $USER_CLUSTER_NAME\n"
        FINAL_CLUSTER_NAME=$USER_CLUSTER_NAME
    elif [ "$choice" = "2" ]; then
        getUserCustomClusterName
    else
        echo -e "\nWrong input\n"
        userChooseClusterName
    fi
}

validateUserParams() {
    if [[ -z "$HELM_API_KEY" ]]; then
        echo "ERROR: Komodor installation script needs HELM_API_KEY session variable in order to run."
        exit 0
    fi

    if [[ -z "$USER_EMAIL" ]]; then
        echo "ERROR: Komodor installation script needs USER_EMAIL session variable in order to run."
        exit 0
    fi
}

startExecuting() {
    echo "***** This might take about 3 minutes *****"
    printKomodorLogo
    printStep 1 "Starting installation"
    sendAnalytics USER_RAN_SCRIPT_INSTALATION
    validateUserParams
}

checkKubectlRequirements() {
    printStep 2 "Checking for existing kubectl installation"
    if ! command -v kubectl &>/dev/null; then
        echo "kubectl isn't installed on your machinem please install kubectl and run again."
        echo "You can find the download links here: https://kubernetes.io/docs/tasks/tools/"
        exit
    fi
    echo "Kubectl is already installed!"
    sendAnalytics USER_HAS_KUBECTL
}

checkConnectionToCluster() {
    printStep 3 "Checking Cluster Connection"
    if ! kubectl get ns default >/dev/null 2>&2; then
        echo 'Kubernetes cluster connectivity test failed...' >&2
        exit 1
    fi
    echo 'Kubernetes cluster connectivity test success!'
    sendAnalytics USER_CLUSTER_CONNECTIVITY_SUCCESS
}

setClusterName() {
    # This function set global var FINAL_CLUSTER_NAME, holds the cluster name the user will choose
    printStep 4 "Choosing cluster name"
    local CLUSTER_NAME=$(kubectl config current-context)
    echo -e "We're going to install komodor agent on cluster: \n${CLUSTER_NAME}"

    local KUBECTL_VALID_CLUSTER_NAME=$(getValidClusterName $CLUSTER_NAME)
    # we use dev tty in order to read from user input after overriding it to /dev/null
    userChooseClusterName $KUBECTL_VALID_CLUSTER_NAME </dev/tty
    sendAnalytics USER_CHOSE_CLUSTER_NAME
}

checkHelmRequirement() {
    printStep 5 "Checking Helm Installation"
    if which helm >/dev/null; then
        echo 'Helm is installed'
    else
        echo 'Helm is not installed...'
        echo "You can get it here: https://helm.sh/docs/intro/install/"
        exit 1
    fi
    sendAnalytics USER_HAS_HELM
}

installKomodorHelmPackage() {
    printStep 6 "Installing Komodor"
    helm repo add komodorio https://helm-charts.komodor.io >/dev/null 2>&2
    # todo: need to think if we want komodorio output
    if [ $? -eq 0 ]; then
        echo "Added komodor chart repository successfully!"
    else
        echo "Failed adding komodor chart repository..."
        exit 1
    fi
    helm repo update >/dev/null 2>&2
    helm upgrade --install k8s-watcher komodorio/k8s-watcher --set watcher.actions.basic=true --set watcher.actions.advanced=true --set apiKey=$HELM_API_KEY --set watcher.clusterName=$FINAL_CLUSTER_NAME --wait --timeout=90s >/dev/null 2>&2
    if [ $? -eq 0 ]; then
        echo "Komodor installed successfully!"
    else
        echo "Komodor install failed..."
        exit 1
    fi
    sendAnalytics USER_INSTALL_KOMODOR_SCRIPT_SUCCESS
    printSuccess
}

startExecuting            # step 1
checkKubectlRequirements  # step 2
checkConnectionToCluster  # step 3
setClusterName            # step 4
checkHelmRequirement      # step 5
installKomodorHelmPackage # step 6
