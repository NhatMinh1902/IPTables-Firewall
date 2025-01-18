#!/bin/bash

function filter_tables {

  echo -e "What Chain of Filter Table Are You Implementing?\n
  1. INPUT: This chain is used to control the behavior for incoming connections.\n
  2. OUTPUT: This chain is used for outgoing connections.\n
  3. FORWARD: This chain is used for incoming connections that aren’t actually being delivered locally.\n"
  echo -n "Chain: "
  read opt_ch
  case $opt_ch in
    1) chain="INPUT";;
    2) chain="OUTPUT";;
    3) chain="FORWARD";;
    *) echo "Bad choice!"
       filter_tables  # Call the function recursively for invalid input
  esac
}

function get_ip_source(){
  echo -e " Specify the source of the packets to be filtered\n\n
  1. Firewall Single Source IP\n
  2. Firewall Source Subnet - A range of IPs\n
  3. Firewall All Source Networks\n"
  echo -n "Using: "

  read opt_ip
  case $opt_ip in
     1) echo -e "\n Enter the IP Address of the Source"
        read ip 
	ip_source=${ip};;
     2) echo -e "\nEnter the Source Subnet (e.g 192.168.10.0/24)"
        read ip
        ip_source=${ip};;
     3) ip_source="0/0" ;;
     *) echo -e "Bad choice"
       get_ip_source;;
  esac

}

function get_ip_destination(){
  echo -e " Specify the destination of the packets to be filtered\n\n
   1. Firewall using Single Destination IP\n
   2. Firewall using Destination Subnet\n
   3. Firewall using for All Destination Networks\n"
  echo -n "Using: "
  read opt_ip
  case $opt_ip in
     1) echo -e "\nPlease Enter the IP Address of the Destination"
        read ip
	ip_dest=${ip};;
     2) echo -e "\nPlease Enter the Destination Subnet (e.g 192.168.10.0/24)"
        read ip
	ip_dest=${ip};;
     3) ip_dest="0/0" ;;
     *) echo -e "Bad choice"
        get_ip_destination;;
    esac
}

function get_protocol(){
  echo -e " Specficy the protocol of the packets to be filtered\n\n
       1. Block All Traffic of TCP
       2. Block Specific TCP Service
       3. Block Specific Port
       4. Using no Protocol\n"
  echo -n "Option: "

   read proto_ch
   case $proto_ch in
      1) protocol=TCP ;;
      2) echo -e "Enter the TCP Service Name: (CAPITAL LETTERS!!!)"
      	 read proto 
	 protocol=${proto};;
      3) echo -e "Enter the Port Name: (CAPITAL LETTERS!!!)"
       	 read proto 
	 protocol=${proto};;
      4) protocol="NULL" ;;
      *) echo -e "Bad choice!"
         get_protocol;;
   esac
}

function select_rule(){
  echo -e "What should we do with these filtered packets?\n\n
       1. Accept Packet
       2. Reject Packet
       3. Drop Packet
       4. Create Log"
       read rule_ch
       case $rule_ch in
        1) rule="ACCEPT" ;;
        2) rule="REJECT" ;;
        3) rule="DROP" ;;
        4) rule="LOG" ;;
	*) echo "Bad choice!"
	select_rule;;
       esac
}

function services(){
echo "Status"
}

function build_the_firewall(){
# get "chain" value
  filter_tables
  local chain=$chain

# get "ip source" value
  get_ip_source
  local ip_source=$ip_source

# get "ip destination" value
  get_ip_destination
  local ip_dest=$ip_dest

# get "protocol" value
  get_protocol
  local protocol=$protocol
# 
read -p "Port (e.g., 80): " port_input

# get "rule"
  select_rule
  local rule=$rule

# Create rule
  echo -e "\nPress Enter to generate the IPTables Command: "
  read temp
  echo -e "The Generated Rule look like is \n"
  if [ $protocol == "NULL" ]; then
	echo -e "\niptables -A $chain -s $ip_source -d $ip_dest -j $rule\n"
	gen=1
  else
	echo -e "\niptables -A $chain -s $ip_source -d $ip_dest -p $protocol -j $rule\n"
	gen=2
  fi
# Add rule
  echo -e "\nAdd this rule to IPTABLES? 1)Yes , 2)No"
  read yesno
  if [ $yesno == 1 ] && [ $gen == 1 ]; then
	sudo  iptables -A $chain -s $ip_source -d $ip_dest -j $rule
  elif [ $yesno == 1 ] && [ $gen == 2 ]; then
	sudo  iptables -A $chain -s $ip_source -d $ip_dest -p $proto --dport $port_input -j $rule
  elif [ $yesno == 2 ]; then
	main
  fi 

# Save connection permissions
sudo iptables-save > rules.v4
sudo cp rules.v4 /etc/iptables/

# Restart iptables service
sudo systemctl restart iptables
}

function main(){

if [[ "${EUID}" -ne 0 ]]; then
  echo "The IPTables requires root privileges."
  exit 1
else
 clear
 opt_main=1
 while [ $opt_main != 4 ]; do
	echo -e "\n\tMENU:\n
 	1. Check if IPTables Installed\n
 	2. Install IPTables\n
 	3. Iptables Services\n
 	4. Build Your Firewall with Iptables\n
 	5. Exit\n"
	echo -n "Command: "
 	read opt_main
	case $opt_main in
		1) iptables --version;;
		2) sudo apt-get install iptables;;
		3) services;;
		4) build_the_firewall;;
		5) exit 0;;
		*) echo "Bad choice!";;
	esac
 done
	
fi
}

main
exit 0
