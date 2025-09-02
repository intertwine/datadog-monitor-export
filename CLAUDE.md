# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Project

This is a Bash script project for exporting Datadog monitor information via the Datadog API. The main script (`query_monitors.sh`) supports complex query syntax with automatic pagination and can output results in both JSON and CSV formats.

## Development Commands

### Running the Script
```bash
# Basic usage with query
./query_monitors.sh --query "status:alert"

# With CSV output
./query_monitors.sh --query "monitor_tags:team:infra" --output-format csv

# With custom output file
./query_monitors.sh --query "name:\"cpu usage\"" --output-file cpu_monitors.json

# Complex query with boolean operators
./query_monitors.sh --query "(status:alert OR status:warn) AND monitor_tags:env:production"
```

### Testing
```bash
# Test script execution (requires valid Datadog credentials)
./query_monitors.sh --query "status:alert" --output-format json

# Validate JSON output
jq '.' monitors_output.*.json

# Check CSV conversion
./query_monitors.sh --query "status:alert" --output-format csv
head -5 monitors_output.*.csv
```

## Architecture & Key Components

### Authentication
- Supports two authentication methods:
  1. Environment variables: `DD_API_KEY` and `DD_APP_KEY`
  2. Local `.credentials` file (automatically loaded by the script)
- The `.credentials` file is gitignored for security

### Core Features
- **Pagination handling**: Automatically fetches all pages of results using the Datadog API's pagination metadata
- **URL encoding**: Uses `jq` to properly encode complex queries with special characters
- **CSV conversion**: Uses `jq` to flatten JSON structures (arrays joined with semicolons, objects converted to strings)

### Dependencies
- **Required**: `jq` for JSON processing and CSV conversion
- **Built-in tools**: `curl` for API requests, standard Bash utilities

### Query Syntax Support
The script supports full Datadog monitor query syntax including:
- Boolean operators: `AND`, `OR`, implicit AND with spaces
- Wildcards: `*` (multi-character), `?` (single character)
- Field searches: `status:`, `monitor_tags:`, `name:`, `notification:`
- Grouping with parentheses for complex queries