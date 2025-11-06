#!/bin/bash

# Debug mode toggle
DEBUG=false

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Animation frames
TINTRI_ANIM=(
" _____ _____ _   _ ___________ _____ "
"|_   _|_   _| \ | |_   _| ___ \_   _|"
"  | |   | | |  \| | | | | |_/ / | |  "
"  | |   | | | . \` | | | |    /  | |  "
"  | |  _| |_| |\  | | | | |\ \ _| |_ "
"  \_/  \___/\_| \_/ \_/ \_| \_|\___/ "
)

STORAGE_ANIM=(
" [■□□□□□□□□□] 10%"
" [■■□□□□□□□□] 20%"
" [■■■□□□□□□□] 30%"
" [■■■■□□□□□□] 40%"
" [■■■■■□□□□□] 50%"
" [■■■■■■□□□□] 60%"
" [■■■■■■■□□□] 70%"
" [■■■■■■■■□□] 80%"
" [■■■■■■■■■□] 90%"
" [■■■■■■■■■■] 100%"
)

SNAPSHOT_ANIM=(
" Taking snapshot..."
" ░░░░░░░░░░░░░░░░░░░ 0%"
" █░░░░░░░░░░░░░░░░░░ 10%"
" ███░░░░░░░░░░░░░░░░ 30%"
" █████░░░░░░░░░░░░░░ 50%"
" ███████░░░░░░░░░░░░ 70%"
" ██████████░░░░░░░░░ 90%"
" ███████████████████ 100%"
" Snapshot complete!"
)

# Function to display animated frames
animate() {
  local anim=("${!1}")
  local delay=${2:-0.1}

  for frame in "${anim[@]}"; do
    echo -ne "${frame}\r"
    sleep $delay
  done
  echo
}

# Function to show Tintri logo animation
show_tintri_logo() {
  clear
  for i in {1..3}; do
    for frame in "${TINTRI_ANIM[@]}"; do
      echo -e "${PURPLE}${frame}${NC}"
    done
    sleep 0.3
    clear
  done

  for frame in "${TINTRI_ANIM[@]}"; do
    echo -e "${PURPLE}${frame}${NC}"
  done
  echo
}


# Function to get the current namespace
get_current_namespace() {
  kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || echo "default"
}

# Function to get the pod name matching a selector
get_pod_name() {
  kubectl get pods -o jsonpath='{.items[0].metadata.name}' --selector=app=nginx 2>/dev/null || echo "ERROR_NO_POD_FOUND"
}

# Function to get service URL
get_service_url() {
  local svc_name=$1

  if [ "$svc_name" = "nginx-clone-service" ]; then
    # Command to get the nodeName for pods with "clone" in their name
    local pod_node=$(kubectl get pods --selector=app=nginx -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}' | grep clone | awk '{print $2}')
  else
    # Default command to get the nodeName for the first pod with the given selector
    local pod_node=$(kubectl get pods --selector=app=nginx -o jsonpath='{.items[0].spec.nodeName}')
  fi

  local node_port=$(kubectl get svc $svc_name -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
  local node_ip=$(kubectl get nodes $pod_node -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)

  if [[ -z "$node_port" || -z "$node_ip" ]]; then
    echo "error"
  else
     echo "http://${node_ip}:${node_port}"
  fi
}

# Function to display clickable URL (when supported)
show_url() {
  local url=$1
  local description=$2

  echo -e "${YELLOW}${description}:${NC}"
  if [[ "$TERM" == *"xterm"* ]]; then
    # Support for clickable links in terminals that support it
    echo -e "\033]8;;${url}\a${BLUE}${url}\033]8;;\a${NC}"
  else
    echo -e "${BLUE}${url}${NC}"
  fi
  echo
}

# Function to simulate storage operation
storage_operation() {
  echo -e "${CYAN}$1${NC}"
  animate STORAGE_ANIM[@]
  echo -e "${GREEN}Done!${NC}"
  echo
}

# Function to simulate snapshot creation
snapshot_operation() {
  echo -e "${YELLOW}Creating Tintri Snapshot...${NC}"
  animate SNAPSHOT_ANIM[@]
  echo -e "${GREEN}Snapshot created successfully!${NC}"
  echo
}

# Main demo function
run_demo() {
  show_tintri_logo

  echo -e "${BLUE}=== Tintri VMstore CSI Demo ===${NC}"
  echo

  # Step 1: Storage Provisioning
  echo -e "${CYAN}Step 1: Provisioning Storage${NC}"
  storage_operation "Creating Persistent Volume Claim..."
  kubectl apply -f deployment/nginx-pvc.yaml > /dev/null

  # Step 2: Deploy Application
  echo -e "${CYAN}Step 2: Deploying Application${NC}"
  storage_operation "Creating Deployment..."
  kubectl apply -f deployment/nginx-deployment.yaml > /dev/null
  kubectl apply -f deployment/nginx-service.yaml > /dev/null

  # Wait for pods to be ready
  pvc_name=$(kubectl get pvc | grep "nginx"| awk '{print $1}')

  # Wait for the PVC to reach Bound status
  echo "Waiting for PVC '$pvc_name' to be bound..."

  kubectl wait --for=condition=ready pod --selector=app=nginx --timeout=120s > /dev/null


  #Step 3: Copy HTML file
  echo -e "${CYAN}Step 3: Copying HTML File${NC}"
  storage_operation "Copying HTML Deployment..."
  CURRENT_NS=$(get_current_namespace)
  NGINX_POD=$(get_pod_name)
  random_file=$(ls webpages/*.html | shuf -n 1)

  kubectl cp ${random_file} ${CURRENT_NS}/${NGINX_POD}:/usr/share/nginx/html/index.html


  # Show original service URL
  original_url=$(get_service_url "nginx-service")
  if [[ "$original_url" != "error" ]]; then
    show_url "$original_url" "Original Application URL"
  else
    echo -e "${RED}Failed to get original service URL${NC}"
  fi

  # Step 4: Create Snapshot
  echo -e "${CYAN}Step 4: Creating Storage Snapshot${NC}"
  snapshot_operation
  kubectl apply -f snapshot/volumesnapshotclass.yaml > /dev/null
  kubectl apply -f snapshot/volumesnapshot.yaml > /dev/null

  # Extract the name of the snapshot from the YAML file (adjust as needed)
  snapshot_name=$(kubectl get volumesnapshot -o jsonpath='{.items[0].metadata.name}')
  # Wait for the snapshot to become ready
  echo "Waiting for snapshot '$snapshot_name' to be ready..."
  kubectl wait volumesnapshot/$snapshot_name --for=jsonpath='{.status.readyToUse}'=true --timeout=300s

  # Step 5: Clone from Snapshot
  echo -e "${CYAN}Step 5: Cloning from Snapshot${NC}"
  storage_operation "Creating Clone PVC..."
  kubectl apply -f clone/clone-pvc-from-snapshot.yaml > /dev/null
  # Extract the name of the PVC from the YAML file (adjust if needed)
  pvc_name=$(kubectl get pvc | grep "clone"| awk '{print $1}')

  # Wait for the PVC to reach Bound status
  echo "Waiting for PVC '$pvc_name' to be bound..."
  kubectl wait pvc/$pvc_name --for=jsonpath='{.status.phase}'=Bound --timeout=300s

  storage_operation "Deploying Clone Application..."
  kubectl apply -f clone/nginx-deployment-clone.yaml > /dev/null
  kubectl apply -f clone/nginx-service-clone.yaml > /dev/null

  # Wait for clone pods to be ready
  kubectl wait --for=condition=ready pod --selector=app=nginx --timeout=120s | grep "clone" > /dev/null

  # Show clone service URL
  clone_url=$(get_service_url "nginx-clone-service")
  if [[ "$clone_url" != "error" ]]; then
    show_url "$clone_url" "Clone Application URL"
  else
    echo -e "${RED}Failed to get clone service URL${NC}"
  fi

  # Display results
  echo -e "${BLUE}=== Demo Results ===${NC}"
  echo -e "${GREEN}Original Deployment:${NC}"
  kubectl get pods --selector=app=nginx -o wide| grep -v clone
  kubectl get svc nginx-service -o wide

  echo -e "\n${GREEN}Clone Deployment:${NC}"
  kubectl get pods --selector=app=nginx -o wide | grep clone
  kubectl get svc nginx-clone-service -o wide

  echo -e "\n${BLUE}=== Tintri Storage Operations Completed ==="
  echo -e "${PURPLE}██████████████████████████████████████${NC}"
  echo -e "${PURPLE}██                                  ██${NC}"
  echo -e "${PURPLE}██   STORAGE DEMONSTRATION DONE     ██${NC}"
  echo -e "${PURPLE}██                                  ██${NC}"
  echo -e "${PURPLE}██████████████████████████████████████${NC}"

  # Final URLs reminder
  echo -e "\n${YELLOW}You can access your applications at:${NC}"
  [[ "$original_url" != "error" ]] && echo -e "Original: ${BLUE}${original_url}${NC}"
  [[ "$clone_url" != "error" ]] && echo -e "Clone:    ${BLUE}${clone_url}${NC}"
}

# Run the demo
run_demo








