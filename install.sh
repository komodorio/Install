#!/bin/bash

# This script installs Komodor's agent on your cluster, it uses helm and kubectl.
# You can find the repo at: https://github.com/komodorio/Install

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

    echo "Open https://app.komodor.com/ to start using Komodor"
}

sendClusterConnectivityErrorEvent() {
    # We collect error logs to learn about and improve the installation process.

    echo 'Running the following commands for troubleshooting and analytics:'
    echo "$ kubectl get ns default "
    echo "$ kubectl get ns "

    getNsDefault="$(kubectl get ns default 2>&1)"
    getAllNs="$(kubectl get ns 2>&1)"

    properties='{"getAllNs": "'"$getAllNs"'", "getNsDefault": "'"$getNsDefault"'", "email": "'"$USER_EMAIL"'", "origin": "self-serve-script", "scriptType": "bash"}'

    data='{"eventName": "USER_CLUSTER_CONNECTIVITY_SUCCESS_ERROR","userId": "'$USER_EMAIL'", "properties": '$properties'}'

    curl --location --request POST 'https://api.komodor.com/analytics/segment/track' \
        --header 'api-key: '$USER_EMAIL'' \
        --header 'Content-Type: application/json' \
        -d @<(
            cat <<EOF
$data
EOF
        )

}

sendAnalytics() {
    # We use analytics to keep track of what works and what doesn't work in our script, with the intention of creating the best installation experience possible.
    # argument 1 = Event type

    curl --location --request POST 'https://api.komodor.com/analytics/segment/track' \
        --header 'api-key: '$USER_EMAIL'' \
        --header 'Content-Type: application/json' \
        --data-raw '{
        "eventName": "'$1'",
        "userId": "'$USER_EMAIL'",
        "properties": {
            "email": "'$USER_EMAIL'",
            "origin": "self-serve-script",
            "scriptType": "bash"
        }
    }'
}

sendContextAnalytics() {
    # We use analytics to keep track of what works and what doesn't work in our script, with the intention of creating the best installation experience possible.
    # argument 1 = Event type
    eventName="USER_CONTEXT_OUTPUT_$1"
    properties='{"context": "'"$2"'", "email": "'"$USER_EMAIL"'", "origin": "self-serve-script", "scriptType": "bash"}'
    data='{"eventName": "'$eventName'","userId": "'$USER_EMAIL'", "properties": '$properties'}'

    curl --location --request POST 'https://api.komodor.com/analytics/segment/track' \
        --header 'api-key: '$USER_EMAIL'' \
        --header 'Content-Type: application/json' \
        -d @<(
            cat <<EOF
$data
EOF
        )
}

sendErrorAnalytics() {
    # We collect error logs to learn about and improve the installation process.
    # argument 1 = The event name
    # argument 2 = The error message

    properties='{"error": "'"$2"'", "email": "'"$USER_EMAIL"'", "origin": "self-serve-script", "scriptType": "bash"}'
    data='{"eventName": "'$1'","userId": "'$USER_EMAIL'","properties": '$properties'}'

    curl --location --request POST 'https://api.komodor.com/analytics/segment/track' \
        --header 'api-key: '$USER_EMAIL'' \
        --header 'Content-Type: application/json' \
        -d @<(
            cat <<EOF
$data
EOF
        )

}

STEPS_COUNT=6
DEFAULT_CLUSTER_NAME=default

printStep() {
    echo -e "-------------$1/$STEPS_COUNT----------------"
    echo -e "$2\n"
}

isValidClusterName() {
    # This validation follows the official K8s guide to valid object and resource names.
    # Learn more: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/
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
    # Get cluster name from kubectl current context, format and strip it of unnecessary characters and symbols, and validate it.
    # If the validation succeeds, use the real cluster name; otherwise, use the default name.
    local KUBECTL_CLUSTER_NAME=$1
    STRIP_CLUSTER_NAME=$(echo $KUBECTL_CLUSTER_NAME | cut -d "/" -f2)
    isValidClusterName $STRIP_CLUSTER_NAME
    if [ $? -eq 1 ]; then
        echo $STRIP_CLUSTER_NAME
    else
        echo $DEFAULT_CLUSTER_NAME
    fi
}

getUserCustomClusterName() {
    # Get cluster name from user
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
    # Get cluster name from user
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
        userChooseClusterName $USER_CLUSTER_NAME
    fi
}

validateUserParams() {
    if [[ -z "$HELM_API_KEY" ]]; then
        echo "ERROR: Komodor installation script needs HELM_API_KEY session variable in order to run."
        exit 1
    fi

    if [[ -z "$USER_EMAIL" ]]; then
        echo "ERROR: Komodor installation script needs USER_EMAIL session variable in order to run."
        exit 1
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
        echo "kubectl isn't installed on your machine please install kubectl and run again."
        echo "You can find the download links here: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    echo "Kubectl is already installed!"
    sendAnalytics USER_HAS_KUBECTL
}

checkConnectionToCluster() {
    printStep 4 "Checking Cluster Connection with command: kubectl get ns default"
    if ! kubectl get ns default >/dev/null 2>&2; then
        echo 'Kubernetes cluster connectivity test failed... please make sure your cluster is up and your context is correct.' >&2
        sendClusterConnectivityErrorEvent
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

chooseContext() {
    # Get all k8s contexts
    printStep 3 "Select the relevant kube context"
    contexts=$(kubectl config get-contexts -o name 2>&1)

    if [ $? -eq 0 ]; then
        sendContextAnalytics SUCCESS "$contexts"
        # Print contexts to user and ask them to select one
        echo "Please select a context:"
        select context in $contexts; do
            if [[ -n $context ]]; then
                sendAnalytics USER_CHOSE_CONTEXT_SUCCESS
                # Switch to selected context
                echo "Switching context to: "
                kubectl config use-context $context
                echo "Context successfully changed to: $context"
                break
            else
                echo "Invalid selection. Please try again."
            fi
        done
    else
        sendContextAnalytics ERROR "$contexts"
        echo "An error occured when trying to execute: $ kubectl config get-contexts -o name"
        exit 1
    fi

}

checkHelmRequirement() {
    # Check if Helm is installed
    printStep 6 "Checking Helm Installation"
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
    # Install Komodor's agent on your cluster!
    printStep 7 "Installing Komodor"
    echo "Running the following helm commands:"
    echo "- $ helm repo add komodorio https://helm-charts.komodor.io"
    echo "- $ helm repo update"
    echo "- $ helm upgrade --install k8s-watcher komodorio/k8s-watcher --set watcher.actions.basic=true --set watcher.actions.advanced=true --set apiKey=$HELM_API_KEY --set watcher.clusterName=$FINAL_CLUSTER_NAME --wait --timeout=90s"
    helm repo add komodorio https://helm-charts.komodor.io >/dev/null 2>&2
    if [ $? -eq 0 ]; then
        echo "Added komodor chart repository successfully!"
    else
        echo "Failed adding komodor chart repository..."
        exit 1
    fi
    echo "Installing Komodor, this might take a minute"
    helm repo update >/dev/null 2>&2
    INSTALL_OUTPUT=$(helm upgrade --install k8s-watcher komodorio/k8s-watcher --set watcher.actions.basic=true --set watcher.actions.advanced=true --set apiKey=$HELM_API_KEY --set watcher.clusterName=$FINAL_CLUSTER_NAME --wait --timeout=90s 2>&1)
    if [ $? -eq 0 ]; then
        echo "Komodor installed successfully!"
        sendAnalytics USER_INSTALL_KOMODOR_SCRIPT_SUCCESS
    else
        echo "Komodor install failed..."
        echo "$INSTALL_OUTPUT"
        sendErrorAnalytics "USER_INSTALL_KOMODOR_SCRIPT_SUCCESS_ERROR" "$INSTALL_OUTPUT"
        DIAGNOSTICS=$(helm history k8s-watcher -o json 2>&1)
        sendErrorAnalytics "LAST_STEP_ERROR_DIAGNOSTICS_V2" "$DIAGNOSTICS"
        exit 1
    fi
    printSuccess
}

startExecuting            # step 1
checkKubectlRequirements  # step 2
chooseContext             # step 3
checkConnectionToCluster  # step 4
setClusterName            # step 5
checkHelmRequirement      # step 6
installKomodorHelmPackage # step 7
