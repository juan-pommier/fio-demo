#!/bin/bash
set -euo pipefail

# Shared colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

show_title() {
  clear
  echo -e "${RED} ********** **  **  **  **  ****   ****  **   ** ${NC}"
  echo -e "${RED}/////**/// //  /**  //  /** /**/** /**/** /**  /** ${NC}"
  echo -e "${RED}   /**     **  /**   ** /** /**/** /**/** /**  /**  ******  ******  ******  ****** ${NC}"
  echo -e "${RED}   /**    /**  /**  /** /** /**/** /**/** /**  /** **////  **////  **////  **///**${NC}"
  echo -e "${WHITE}   /**    /**  /**  /** /** /**/** /**/** /**  /**//***** //***** //***** /*******${NC}"
  echo -e "${WHITE}   /**    /**  /**  /** /** /**/** /**/** /**  /** /////** /////** /////** /**//// ${NC}"
  echo -e "${WHITE}   /**    //******  //******/**/** /**/** //****** ******  ******  ****** //******${NC}"
  echo -e "${WHITE}   //      //////    ////// // //  // //   ////// //////  //////  //////  ////// ${NC}"
  echo
}

# Helper functions for logging and messaging
echo_header() {
  echo -e "${CYAN}=== $1 ===${NC}"
}

echo_info() {
  echo -e "${GREEN}→ $1${NC}"
}

echo_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

echo_error() {
  echo -e "${RED}✗ $1${NC}"
}
