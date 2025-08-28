# Datadog Monitor Export

Bash script to export monitor information via the Datadog API

A simple Bash script to query the Datadog Monitors API with a command-line search query and save the output as either a JSON or CSV file.

The script uses curl to make the API request and jq for JSON processing, which is necessary for converting the output to CSV.

## Prerequisites

- Datadog API and Application Keys: These must be set as environment variables DD_API_KEY and DD_APP_KEY for authentication, or provided in a `.credentials` file (see setup instructions below).
- jq: A lightweight and flexible command-line JSON processor. It is required for converting the JSON output to CSV.

The script: query_monitors.sh

## How to use the script

1. Save the script to a file named query_monitors.sh.
1. Make it executable with chmod +x query_monitors.sh.
1. Set up your API and Application keys using **one of these methods**:

   **Option A: Environment Variables**
   ```sh
   export DD_API_KEY="<YOUR_API_KEY>"
   export DD_APP_KEY="<YOUR_APPLICATION_KEY>"
   ```

   **Option B: Credentials File**
   Create a `.credentials` file in the same directory as the script with the following format:
   ```sh
   DD_API_KEY="<YOUR_API_KEY>"
   DD_APP_KEY="<YOUR_APPLICATION_KEY>"
   ```

1. Run the script with your desired query and output format.

### Example 1: Export all "alert" status monitors as a JSON file

```sh
./query_monitors.sh --query "status:alert"
```

This will save the output to a file like monitors_output_2025-08-28_123456.json.

### Example 2: Export all monitors tagged with team:infra as a CSV file

```sh
./query_monitors.sh --query "monitor_tags:team:infra" --output-format csv --output-file team_infra_monitors.csv
```

This will save the output to team_infra_monitors.csv.

### Example 3: Export monitors by a specific name

```sh
./query_monitors.sh --query "name:\"cpu usage\""
```

