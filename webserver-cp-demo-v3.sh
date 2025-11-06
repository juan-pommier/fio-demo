#!/bin/bash

random_tag() {
  tags=("asterix" "obelix")
  echo "${tags[$RANDOM % ${#tags[@]}]}"
}
# Debug mode toggle (set to true or false)
DEBUG=false

# Function to print debug messages
debug_log() {
  if [ "$DEBUG" = true ]; then
    echo "DEBUG: $1"
  fi
}

# Colors for better readability
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Array of commands to demonstrate
commands=(
#Deploy the App::
"kubectl apply -f deployment-zone/nginx-pvc.yaml"
"kubectl apply -f deployment-zone/nginx-deployment.yaml"
"kubectl apply -f deployment-zone/nginx-service.yaml"
#Copy some HTML code to the webserver
"kubectl cp index.html \$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' || echo default)/\$(kubectl get pods -o jsonpath='{.items[0].metadata.name}' --selector=app=nginx || echo 'ERROR_NO_POD_FOUND'):/usr/share/nginx/html/index.html"
#SnapShot The PVC::
"kubectl apply -f snapshot/volumesnapshotclass.yaml"
"kubectl apply -f snapshot/volumesnapshot.yaml"
#Check the webserver::
# kubectl get nodes,pods,svc -o wide"
"kubectl get pods,svc -o wide | grep ngin*"
#Deploy App with Clone Data::
"kubectl apply -f clone/clone-pvc-from-snapshot.yaml"
"kubectl apply -f clone/nginx-deployment-clone.yaml"
"kubectl apply -f clone/nginx-service-clone.yaml"
#Check the Clone Site Details#
"kubectl get pods,svc -o wide | grep clone*"
)

# Function to display title with custom ASCII art
show_title() {
  clear
  echo -e "${RED} ********** **            **          **       **      ** ****     ****           **                          ${NC}"
  echo -e "${RED}/////**/// //            /**         //       /**     /**/**/**   **/**          /**                          ${NC}"
  echo -e "${RED}    /**     ** *******  ****** ****** **      /**     /**/**//** ** /**  ****** ******  ******  ******  ***** ${NC}"
  echo -e "${RED}    /**    /**//**///**///**/ //**//*/**      //**    ** /** //***  /** **//// ///**/  **////**//**//* **///**${NC}"
  echo -e "${WHITE}    /**    /** /**  /**  /**   /** / /**       //**  **  /**  //*   /**//*****   /**  /**   /** /** / /*******${NC}"
  echo -e "${WHITE}    /**    /** /**  /**  /**   /**   /**        //****   /**   /    /** /////**  /**  /**   /** /**   /////// ${NC}"
  echo -e "${WHITE}    /**    /** ***  /**  //** /***   /**         //**    /**        /** ******   //** //****** /***   //******${NC}"
  echo -e "${WHITE}    //     // ///   //    //  ///    //           //     //         // //////     //   //////  ///     ////// ${NC}"
  echo
  echo -e "${RED}=====================================${NC}"
  echo -e "${RED}          VMstore Demo              ${NC}"
  echo -e "${RED}=====================================${NC}"
  echo
  echo -e "${GREEN}Press ENTER after each command to execute${NC}"
  echo -e "${GREEN}Press Ctrl+C to exit the demo${NC}"
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



# Function to get service information
get_service_info() {
  local svc_name=$1
  local selector=$2

  # Log start of function
  debug_log "Function get_service_info started with svc_name=$svc_name and selector=$selector"

  # Log and execute the command to get NodePort
  local node_port_cmd="kubectl get svc \"$svc_name\" -o jsonpath='{.spec.ports[0].nodePort}'"
  debug_log "Executing command: $node_port_cmd"
  local node_port=$(eval "$node_port_cmd"  || echo "ERROR_NO_PORT_FOUND")
  debug_log "Result: node_port = $node_port"

  # Log and execute the command to get Pod Node

  if [ "$selector" = "clone" ]; then
    # Command to get the nodeName for pods with "clone" in their name
    local pod_node_cmd="kubectl get pods --selector=app=nginx -o jsonpath='{range .items[*]}{.metadata.name}{\"\t\"}{.spec.nodeName}{\"\n\"}{end}' | grep clone | awk '{print \$2}'"
  else
    # Default command to get the nodeName for the first pod with the given selector
    local pod_node_cmd="kubectl get pods --selector=app=$selector -o jsonpath='{.items[0].spec.nodeName}'"
  fi

  debug_log "Executing command: $pod_node_cmd"
  local pod_node=$(eval "$pod_node_cmd"  || echo "ERROR_NO_NODE_FOUND")
  debug_log "Result: pod_node = $pod_node"

  # Log and execute the command to get External IP
  local external_ip_cmd="kubectl get nodes \"$pod_node\" -o jsonpath='{.status.addresses[?(@.type==\"InternalIP\")].address}'"
  debug_log "Executing command: $external_ip_cmd"
  local external_ip=$(eval "$external_ip_cmd" || echo "ERROR_NO_IP_FOUND")
  debug_log "Result: external_ip = $external_ip"

  # Combine results and return
  debug_log "Returning: $external_ip:$node_port"
  echo "$external_ip:$node_port"
}


# Display access guide
display_access_guide() {
  local selector=$1
  local svc_name=$2

  debug_log "Function display_access_guide started with selector=$selector and svc_name=$svc_name"

  # Get service information (external IP and NodePort)
  service_info=$(get_service_info "$svc_name" "$selector")

  # Extract external IP and port from service info
  external_ip=$(echo "$service_info" | cut -d':' -f1)
  node_port=$(echo "$service_info" | cut -d':' -f2)

  # Display guide
  echo -e "${GREEN}Access Guide for Deployment (${selector}):${NC}"
  echo -e "\033]8;;http://${external_ip}:${node_port}\aVisit website via IP: http://${external_ip}:${node_port}\033]8;;\a"
}


# Main demo function
run_demo() {
  show_title

  # Generate a random tag
  selected_tag=$(random_tag)

  # Loop through each command
  for cmd in "${commands[@]}"; do

    # Replace .yaml with -<selected_tag>.yaml for the 3 kubectl apply commands
    if [[ "$cmd" == *"kubectl apply -f deployment-zone/nginx-pvc.yaml"* || "$cmd" == *"kubectl apply -f deployment-zone/nginx-deployment.yaml"* ]]; then
      # shellcheck disable=SC2001
      cmd=$(echo "$cmd" | sed "s/\.yaml/-${selected_tag}.yaml/")
    fi

    # Special handling for dynamic commands like kubectl cp
    if [[ "$cmd" == *"kubectl cp index.html"* ]]; then
      # Resolve dynamic values
      CURRENT_NS=$(get_current_namespace)
      NGINX_POD=$(get_pod_name)

      # Display resolved values before execution
      echo -e "${YELLOW}Resolved Namespace: ${CURRENT_NS}${NC}"
      echo -e "${YELLOW}Resolved Pod Name: ${NGINX_POD}${NC}"

      # Select a random HTML file from the webpages directory
      random_file=$(ls webpages/*.html | shuf -n 1)

      # Replace placeholders in the command dynamically
      cmd="kubectl cp \"$random_file\" ${CURRENT_NS}/${NGINX_POD}:/usr/share/nginx/html/index.html"
    fi


    # Display the command with prompt
    echo -e "${CYAN}$ ${cmd}${NC}"

    # Wait for user to press ENTER
    read -p ""

    # Execute the command
    eval "$cmd"

    # Evaluate if cmd would require website visit
    if [[ "$cmd" == *"kubectl get pods,svc"* ]]; then
      if [[ "$cmd" == *"grep ngin*"* ]]; then
        display_access_guide "nginx" "nginx-service"
      elif [[ "$cmd" == *"grep clone*"* ]]; then
        display_access_guide "clone" "nginx-clone-service"
      fi
    fi

    # Separator for readability
    echo
    echo -e "${YELLOW}-------------------------------------${NC}"
    echo
  done

  # Demo completed message
  echo -e "${RED}Demo completed!${NC}"
}

# Run the demo
run_demo

