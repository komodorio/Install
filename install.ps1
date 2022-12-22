# This script installs Komodor's agent on your cluster, it uses helm and kubectl.
# You can find the repo at: https://github.com/komodorio/Install

$global:HELM_API_KEY = $args[0]
$global:USER_EMAIL = $args[1]


function PrintKomodorLogo {
    $komodorLogo = """
                                                           
,--. ,--.                           ,--.               
|  .'   / ,---. ,--,--,--. ,---.  ,-|  | ,---. ,--.--. 
|  .   ' | .-. ||        || .-. |' .-. || .-. ||  .--' 
|  |\   \' '-' '|  |  |  |' '-' '\ '-' |' '-' '|  |    
'--' '--' '---' '--'--'--' '---'  '---'  '---' '--'    
                                                       """
    Write-Host $komodorLogo
}

function printEnterClusterName {
    Write-Host "
                                                                                                                             
                 ,--.                          ,--.                ,--.                                                      
 ,---. ,--,--, ,-'  '-. ,---. ,--.--.     ,---.|  |,--.,--. ,---.,-'  '-. ,---. ,--.--.    ,--,--,  ,--,--.,--,--,--. ,---.  
| .-. :|      \'-.  .-'| .-. :|  .--'    | .--'|  ||  ||  |(  .-''-.  .-'| .-. :|  .--'    |      \' ,-.  ||        || .-. : 
\   --.|  ||  |  |  |  \   --.|  |       \ '--.|  |'  ''  '.-'  ') |  |  \   --.|  |       |  ||  |\ '-'  ||  |  |  |\   --. 
 '----''--''--'  '--'   '----''--'        '---''--' '----' '----'  '--'   '----''--'       '--''--' '--'--''--'--'--' '----' 
                                                                                                                             
"
}

function printSuccess {
    Write-Host "
                                                 ,---.,---. 
 ,---.                                           |   ||   | 
'   .-' ,--.,--. ,---. ,---. ,---.  ,---.  ,---. |  .'|  .' 
'.  '-. |  ||  || .--'| .--'| .-. :(  .-' (  .-' |  | |  |  
.-'    |'  ''  '\ '--.\ '--.\   --..-'  ').-'  ')'--' '--'  
'-----'  '----'  '---' '---' '----''----' '----' .--. .--.  
                                                 '--' '--'  
"

    Write-Host "Open https://app.komodor.com/ to start using Komodor"
}


function SendAnalytics($eventName) {
    # We use analytics to keep track of what works and what doesn't work in our script, with the intention of creating the best installation experience possible.
    # argument 1 = Event type
    $USER_API_KEY_VALUE = ""
    if ([string]::IsNullOrEmpty($USER_API_KEY)) {
        # SESSION_VARIABLE is not set or is empty
        # Use the alternate string
        $USER_API_KEY_VALUE = "temp_user_id"
    }
    else {
        # SESSION_VARIABLE is set and is not empty
        # Use the value of SESSION_VARIABLE
        $USER_API_KEY_VALUE = "$USER_API_KEY"
    }

    $apiKey = $USER_API_KEY_VALUE
    $userId = $USER_EMAIL
    $email = $USER_EMAIL
    $origin = "self-serve-script"
    $scriptType = "powershell"

    $body = @{
        eventName  = $eventName
        userId     = $userId
        properties = @{
            email  = $email
            origin = $origin
            scriptType = $scriptType
        }
    } | ConvertTo-Json

    Invoke-RestMethod -Method POST -Uri 'https://api.komodor.com/analytics/segment/track' `
        -Headers @{ "api-key" = $apiKey; "Content-Type" = "application/json" } `
        -Body $body > $null
}

$STEPS_COUNT = 6
$DEFAULT_CLUSTER_NAME = "default"

function PrintStep($stepNum, $stepName) {
    Write-Output "-------------$stepNum/$STEPS_COUNT----------------"
    Write-Output "$stepName`n"
}

function isValidClusterName($CLUSTER_NAME) {
    # This validation follows the official K8s guide to valid object and resource names.
    # Learn more: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/
    if ($CLUSTER_NAME -eq $null) {
        return 0
    }
    if ($CLUSTER_NAME -match '^[a-z]') {
        if ($CLUSTER_NAME -match '^[a-z0-9.-]+$') {
            if ($CLUSTER_NAME -match '^([a-z]([a-z0-9-]*[a-z0-9])?\.)*([a-z]([a-z0-9-]*[a-z0-9])?)$') {
                if ($CLUSTER_NAME -match '[a-z0-9]$') {
                    return 1
                }
            }
        }
    }
    return 0
}

function getValidClusterName($KUBECTL_CLUSTER_NAME) {
    # Get cluster name from kubectl current context, format and strip it of unnecessary characters and symbols, and validate it.
    # If the validation succeeds, use the real cluster name; otherwise, use the default name.
    $STRIP_CLUSTER_NAME = $KUBECTL_CLUSTER_NAME -replace '/', ''
    if (isValidClusterName $STRIP_CLUSTER_NAME) {
        return $STRIP_CLUSTER_NAME
    }
    else {
        return $DEFAULT_CLUSTER_NAME
    }
}

function getUserCustomClusterName() {
    # Get cluster name from user
    Write-Output "Enter cluster display name: "
    $global:FINAL_CLUSTER_NAME = Read-Host
    if (isValidClusterName $FINAL_CLUSTER_NAME) {
        return
    }
    else {
        Write-Output "This is an invalid cluster name. Using default cluster name."
        $global:FINAL_CLUSTER_NAME = $DEFAULT_CLUSTER_NAME
    }
}

function userChooseClusterName($USER_CLUSTER_NAME) {
    # Get cluster name from user
    printEnterClusterName
    Write-Output "Choose your cluster display name in Komodor"
    Write-Output "1. $USER_CLUSTER_NAME"
    Write-Output "2. Enter cluster name manually"

    Write-Output "Enter your choice [1/2]:"
    $choice = Read-Host

    if ($choice -eq "1") {
        Write-Output "You chose cluster name: $USER_CLUSTER_NAME"
        $global:FINAL_CLUSTER_NAME = $USER_CLUSTER_NAME
    }
    elseif ($choice -eq "2") {
        getUserCustomClusterName
    }
    else {
        Write-Output "Wrong input"
        userChooseClusterName $USER_CLUSTER_NAME
    }
}


function validateUserParams() {
    if ($HELM_API_KEY -eq $null) {
        Write-Output "ERROR: Komodor installation script needs helm api key argument. Pass this as the first argument."
        exit 0
    }

    if ($USER_EMAIL -eq $null) {
        Write-Output "ERROR: Komodor installation script needs user email argument. Pass this as the second argument."
        exit 0
    }
}

function startExecuting() {
    Write-Output "***** This might take about 3 minutes *****"
    printKomodorLogo
    printStep 1 "Starting installation"
    sendAnalytics USER_RAN_SCRIPT_INSTALATION
    validateUserParams
}

function checkKubectlRequirements() {
    printStep 2 "Checking for existing kubectl installation"
    if (!(Get-Command kubectl)) {
        Write-Output "kubectl isn't installed on your machinem please install kubectl and run again."
        Write-Output "You can find the download links here: https://kubernetes.io/docs/tasks/tools/"
        exit
    }
    Write-Output "Kubectl is already installed!"
    sendAnalytics USER_HAS_KUBECTL
}

function checkConnectionToCluster() {
    printStep 3 "Checking Cluster Connection"
    if (!(kubectl get ns default 2>$null)) {
        Write-Output 'Kubernetes cluster connectivity test failed...'
        exit 1
    }
    Write-Output 'Kubernetes cluster connectivity test success!'
    sendAnalytics USER_CLUSTER_CONNECTIVITY_SUCCESS
}

function setClusterName() {
    # This function set global var FINAL_CLUSTER_NAME, holds the cluster name the user will choose
    printStep 4 "Choosing cluster name"
    $CLUSTER_NAME = kubectl config current-context
    Write-Output "We're going to install komodor agent on cluster:`n$CLUSTER_NAME"

    $KUBECTL_VALID_CLUSTER_NAME = getValidClusterName $CLUSTER_NAME
    
    userChooseClusterName $KUBECTL_VALID_CLUSTER_NAME
    sendAnalytics USER_CHOSE_CLUSTER_NAME
}


function checkHelmRequirement() {
    # Check if Helm is installed
    printStep 5 "Checking Helm Installation"
    if (Get-Command helm) {
        Write-Output 'Helm is installed'
    }
    else {
        Write-Output 'Helm is not installed...'
        Write-Output "You can get it here: https://helm.sh/docs/intro/install/#from-chocolatey-windows"
        exit 1
    }
    sendAnalytics USER_HAS_HELM
}

function installKomodorHelmPackage() {
    # Install Komodor's agent on your cluster!
    printStep 6 "Installing Komodor"
    helm repo add komodorio https://helm-charts.komodor.io 2>$null | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Output "Added komodor chart repository successfully!"
    }
    else {
        Write-Output "Failed adding komodor chart repository..."
        exit 1
    }
    Write-Output "Installing Komodor, this might take a minute"
    helm repo update 2>$null | Out-Null

    helm upgrade --install k8s-watcher komodorio/k8s-watcher --set watcher.actions.basic=true --set watcher.actions.advanced=true --set apiKey=$HELM_API_KEY --set watcher.clusterName=$FINAL_CLUSTER_NAME --wait --timeout=90s 2>$null | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Komodor installed successfully!"
    }
    else {
        Write-Output "Komodor install failed..."
        exit 1
    }
    sendAnalytics USER_INSTALL_KOMODOR_SCRIPT_SUCCESS
    printSuccess
}

startExecuting            # step 1
checkKubectlRequirements  # step 2
checkConnectionToCluster  # step 3
setClusterName            # step 4
checkHelmRequirement      # step 5
installKomodorHelmPackage # step 6
