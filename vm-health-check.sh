#!/bin/bash

#############################################################################
# VM Health Check Script
# Purpose: Check the health of a virtual machine
# Usage: ./vm-health-check.sh [explain]
# Example: ./vm-health-check.sh explain
#############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80

#############################################################################
# Function: Print header
#############################################################################
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Virtual Machine Health Check Report${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

#############################################################################
# Function: Get CPU usage
#############################################################################
get_cpu_usage() {
    # Get CPU usage as a percentage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'.' -f1)
    echo "$cpu_usage"
}

#############################################################################
# Function: Get memory usage
#############################################################################
get_memory_usage() {
    # Get memory usage as percentage
    memory_usage=$(free | grep Mem | awk '{printf("%.0f", ($3/$2) * 100)}')
    echo "$memory_usage"
}

#############################################################################
# Function: Get disk usage
#############################################################################
get_disk_usage() {
    # Get disk usage of root partition
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "$disk_usage"
}

#############################################################################
# Function: Get system uptime
#############################################################################
get_uptime() {
    uptime | awk -F'up' '{print $2}' | cut -d',' -f1 | xargs
}

#############################################################################
# Function: Get process count
#############################################################################
get_process_count() {
    ps aux | wc -l
}

#############################################################################
# Function: Get load average
#############################################################################
get_load_average() {
    cat /proc/loadavg | awk '{print $1, $2, $3}'
}

#############################################################################
# Function: Get network interfaces
#############################################################################
get_network_status() {
    echo "$(ip link show | grep "state UP" | awk '{print $2}' | sed 's/:$//' | tr '\n' ' ')"
}

#############################################################################
# Function: Check status and return color
#############################################################################
check_status() {
    local value=$1
    local threshold=$2
    
    if [ "$value" -gt "$threshold" ]; then
        echo -e "${RED}CRITICAL${NC}"
        return 2
    elif [ "$value" -gt $((threshold - 20)) ]; then
        echo -e "${YELLOW}WARNING${NC}"
        return 1
    else
        echo -e "${GREEN}HEALTHY${NC}"
        return 0
    fi
}

#############################################################################
# Function: Print brief health summary
#############################################################################
print_brief_summary() {
    local cpu=$1
    local memory=$2
    local disk=$3
    
    echo -e "${BLUE}Quick Health Summary:${NC}"
    echo ""
    
    echo -n "CPU Usage: $cpu% "
    check_status "$cpu" "$CPU_THRESHOLD"
    echo ""
    
    echo -n "Memory Usage: $memory% "
    check_status "$memory" "$MEMORY_THRESHOLD"
    echo ""
    
    echo -n "Disk Usage: $disk% "
    check_status "$disk" "$DISK_THRESHOLD"
    echo ""
}

#############################################################################
# Function: Print detailed health summary
#############################################################################
print_detailed_summary() {
    local cpu=$1
    local memory=$2
    local disk=$3
    local uptime=$4
    local processes=$5
    local load_avg=$6
    local network=$7
    
    echo -e "${BLUE}Detailed Health Analysis:${NC}"
    echo ""
    
    # CPU Analysis
    echo -e "${BLUE}CPU Information:${NC}"
    echo "  Current Usage: $cpu%"
    if [ "$cpu" -gt "$CPU_THRESHOLD" ]; then
        echo -e "  Status: ${RED}CRITICAL - CPU usage is very high${NC}"
        echo "  Recommendation: Check running processes with 'top' or 'ps aux'"
    elif [ "$cpu" -gt $((CPU_THRESHOLD - 20)) ]; then
        echo -e "  Status: ${YELLOW}WARNING - CPU usage is elevated${NC}"
        echo "  Recommendation: Monitor CPU-intensive processes"
    else
        echo -e "  Status: ${GREEN}HEALTHY - CPU usage is normal${NC}"
    fi
    echo ""
    
    # Memory Analysis
    echo -e "${BLUE}Memory Information:${NC}"
    echo "  Current Usage: $memory%"
    if [ "$memory" -gt "$MEMORY_THRESHOLD" ]; then
        echo -e "  Status: ${RED}CRITICAL - Memory usage is very high${NC}"
        echo "  Recommendation: Free up memory or increase RAM"
        echo "  Command: free -h (to see detailed breakdown)"
    elif [ "$memory" -gt $((MEMORY_THRESHOLD - 20)) ]; then
        echo -e "  Status: ${YELLOW}WARNING - Memory usage is elevated${NC}"
        echo "  Recommendation: Monitor memory-intensive applications"
    else
        echo -e "  Status: ${GREEN}HEALTHY - Memory usage is normal${NC}"
    fi
    echo ""
    
    # Disk Analysis
    echo -e "${BLUE}Disk Information:${NC}"
    echo "  Current Usage: $disk%"
    if [ "$disk" -gt "$DISK_THRESHOLD" ]; then
        echo -e "  Status: ${RED}CRITICAL - Disk space is critically low${NC}"
        echo "  Recommendation: Delete unnecessary files or expand disk"
        echo "  Command: du -sh /* (to find large directories)"
    elif [ "$disk" -gt $((DISK_THRESHOLD - 20)) ]; then
        echo -e "  Status: ${YELLOW}WARNING - Disk space is running low${NC}"
        echo "  Recommendation: Consider freeing up disk space"
    else
        echo -e "  Status: ${GREEN}HEALTHY - Disk space is adequate${NC}"
    fi
    echo ""
    
    # System Uptime
    echo -e "${BLUE}System Uptime:${NC}"
    echo "  $uptime"
    echo ""
    
    # Running Processes
    echo -e "${BLUE}Running Processes:${NC}"
    echo "  Total count: $processes"
    echo ""
    
    # Load Average
    echo -e "${BLUE}Load Average (1min, 5min, 15min):${NC}"
    echo "  $load_avg"
    echo ""
    
    # Network Status
    echo -e "${BLUE}Active Network Interfaces:${NC}"
    if [ -z "$network" ]; then
        echo "  ${RED}No active network interfaces found${NC}"
    else
        echo "  $network"
    fi
    echo ""
    
    # Overall Assessment
    echo -e "${BLUE}Overall Assessment:${NC}"
    local critical_count=0
    local warning_count=0
    
    [ "$cpu" -gt "$CPU_THRESHOLD" ] && ((critical_count++))
    [ "$memory" -gt "$MEMORY_THRESHOLD" ] && ((critical_count++))
    [ "$disk" -gt "$DISK_THRESHOLD" ] && ((critical_count++))
    
    [ "$cpu" -gt $((CPU_THRESHOLD - 20)) ] && [ "$cpu" -le "$CPU_THRESHOLD" ] && ((warning_count++))
    [ "$memory" -gt $((MEMORY_THRESHOLD - 20)) ] && [ "$memory" -le "$MEMORY_THRESHOLD" ] && ((warning_count++))
    [ "$disk" -gt $((DISK_THRESHOLD - 20)) ] && [ "$disk" -le "$DISK_THRESHOLD" ] && ((warning_count++))
    
    if [ "$critical_count" -gt 0 ]; then
        echo -e "  ${RED}CRITICAL ISSUES DETECTED${NC}"
        echo "  Action Required: $critical_count critical issue(s) found"
    elif [ "$warning_count" -gt 0 ]; then
        echo -e "  ${YELLOW}WARNING - MONITOR CLOSELY${NC}"
        echo "  Attention Required: $warning_count warning(s) detected"
    else
        echo -e "  ${GREEN}SYSTEM HEALTHY${NC}"
        echo "  All parameters are within normal ranges"
    fi
    echo ""
}

#############################################################################
# Main Script Execution
#############################################################################

print_header

# Collect system information
cpu=$(get_cpu_usage)
memory=$(get_memory_usage)
disk=$(get_disk_usage)
uptime=$(get_uptime)
processes=$(get_process_count)
load_avg=$(get_load_average)
network=$(get_network_status)

# Check if "explain" argument is provided
if [ "$1" == "explain" ]; then
    print_detailed_summary "$cpu" "$memory" "$disk" "$uptime" "$processes" "$load_avg" "$network"
else
    print_brief_summary "$cpu" "$memory" "$disk"
    echo ""
    echo -e "${BLUE}Additional Information:${NC}"
    echo "System Uptime: $uptime"
    echo "Running Processes: $processes"
    echo "Load Average: $load_avg"
    echo "Active Interfaces: $network"
    echo ""
    echo -e "${BLUE}For detailed analysis, run: $0 explain${NC}"
fi

echo -e "${BLUE}========================================${NC}"
echo "Report generated on: $(date)"
echo -e "${BLUE}========================================${NC}"
