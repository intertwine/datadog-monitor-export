#!/bin/bash

# A simple script to query Datadog monitors via the API with a search query.
# It can output results in JSON or CSV format.

# --- Configuration ---
# Your Datadog Site. Change to "datadoghq.eu" or other if needed.
DD_SITE="datadoghq.com"

# --- Functions ---

# Function to load credentials from a .credentials file if it exists.
# The file should be in key=value format (e.g., DD_API_KEY="<YOUR_KEY>")
load_credentials() {
  local script_dir="$(dirname -- "$0")"
  local credentials_file="${script_dir}/.credentials"

  if [[ -f "${credentials_file}" ]]; then
    echo "Found .credentials file. Loading keys..."
    # 'source' will execute the file in the current shell, setting the variables.
    source "${credentials_file}"
  fi
}

# Function to display usage information
usage() {
  echo "Usage: $0 --query \"<DD_QUERY>\" [--output-format json|csv] [--output-file <filename>]"
  echo ""
  echo "Arguments:"
  echo "  --query           The Datadog monitor search query (e.g., \"status:alert type:metric\")"
  echo "  --output-format   The output format: 'json' (default) or 'csv'."
  echo "  --output-file     The filename for the output (e.g., my_monitors.json). Overrides default."
  echo ""
  echo "Example:"
  echo "  ./query_monitors.sh --query \"env:production\" --output-format csv"
  echo "  ./query_monitors.sh --query \"env:production\" --output-file prod_monitors.csv"
  exit 1
}

# --- Main Script ---

# Load credentials from the local file first.
load_credentials

# Check for required environment variables (now with local file support)
if [ -z "$DD_API_KEY" ] || [ -z "$DD_APP_KEY" ]; then
  echo "Error: Datadog API keys (DD_API_KEY, DD_APP_KEY) are not set."
  echo "Please set them as environment variables or in a .credentials file."
  exit 1
fi

# Parse command-line arguments
DD_QUERY=""
OUTPUT_FORMAT="json"
OUTPUT_FILE=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --query)
      if [ -z "$2" ]; then usage; fi
      DD_QUERY="$2"
      shift
      ;;
    --output-format)
      if [ -z "$2" ]; then usage; fi
      OUTPUT_FORMAT="$2"
      shift
      ;;
    --output-file)
      if [ -z "$2" ]; then usage; fi
      OUTPUT_FILE="$2"
      shift
      ;;
    *)
      usage
      ;;
  esac
  shift
done

if [ -z "$DD_QUERY" ]; then
  usage
fi

# Set a default filename if not provided
if [ -z "$OUTPUT_FILE" ]; then
  OUTPUT_FILE="monitors_output.$(date +%Y-%m-%d_%H%M%S)"
  if [ "$OUTPUT_FORMAT" == "json" ]; then
    OUTPUT_FILE="${OUTPUT_FILE}.json"
  else
    OUTPUT_FILE="${OUTPUT_FILE}.csv"
  fi
fi

# Build the API request URL
API_URL="https://api.${DD_SITE}/api/v1/monitor/search?query=${DD_QUERY}"

# Make the API call and store the JSON output
echo "Querying Datadog for monitors matching: ${DD_QUERY}"
API_RESPONSE=$(curl -s -X GET "${API_URL}" \
-H "Accept: application/json" \
-H "DD-API-KEY: ${DD_API_KEY}" \
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}")

if [ "$OUTPUT_FORMAT" == "json" ]; then
  echo "${API_RESPONSE}" > "$OUTPUT_FILE"
  echo "Output saved to ${OUTPUT_FILE}"
elif [ "$OUTPUT_FORMAT" == "csv" ]; then
  if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install it to use CSV output."
    exit 1
  fi
  
  # Convert JSON to CSV using jq.
  echo "${API_RESPONSE}" | jq -r '
    if (.monitors | length) > 0 then
      ( .monitors[0] | keys_unsorted ) as $keys
      | ( $keys | @csv ),
      ( .monitors[] | [.[ $keys[] ]] | @csv )
    end
  ' > "$OUTPUT_FILE"
  echo "Output saved to ${OUTPUT_FILE}"
else
  echo "Error: Invalid output format specified. Use 'json' or 'csv'."
  exit 1
fi
