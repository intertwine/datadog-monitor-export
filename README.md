# Datadog Monitor Export

Bash script to export monitor information via the Datadog API

A simple Bash script to query the Datadog Monitors API with a command-line search query and save the output as either a JSON or CSV file.

The script uses curl to make the API request and jq for JSON processing, which is necessary for converting the output to CSV. The script automatically handles pagination to retrieve all results and properly URL-encodes complex queries with special characters.

## Features

- **Automatic pagination**: Retrieves all monitors across multiple pages
- **Complex query support**: Handles wildcards, boolean operators, and special characters with automatic URL encoding
- **Dual output formats**: JSON (preserves full data structure) and CSV (flattens arrays and objects)
- **Flexible authentication**: Environment variables or local credentials file

## Prerequisites

- Datadog API and Application Keys: These must be set as environment variables DD_API_KEY and DD_APP_KEY for authentication, or provided in a `.credentials` file (see setup instructions below).
- jq: A lightweight and flexible command-line JSON processor. It is required for converting the JSON output to CSV and handling pagination.

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

**Note**: The script automatically handles pagination and will fetch all results across multiple pages. Complex queries with parentheses, wildcards, and special characters are automatically URL-encoded.

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

### Query Syntax

In Datadog query syntax, the keywords for expressing logical operators are:

- **AND** for intersection
- **OR** for union
- **Space** also acts as an implicit AND operator
- **Parentheses `( )`** for grouping complex queries

#### AND operator

By default, placing two conditions next to each other implies an AND relationship. You can also explicitly use the AND keyword for clarity.

**Implicit AND (using a space):**
```
status:alert type:metric
```
This query returns all monitors that have a status of "alert" and are of type "metric".

**Explicit AND:**
```
status:alert AND type:metric
```
This is functionally identical to the previous example but more explicit.

#### OR operator

The OR operator is used to find results that match at least one of the specified conditions. It is particularly useful for combining multiple values within the same field.

```
status:(alert OR warn)
```
This query returns all monitors that have a status of either "alert" or "warn".

#### Combined AND and OR

You can combine both operators to build more complex and precise queries.

**Example: Monitors in "alert" or "warn" status tagged with env:production**
```
(status:alert OR status:warn) AND monitor_tags:env:production
```

- `(status:alert OR status:warn)`: Finds monitors with either an "alert" or "warn" status
- `AND monitor_tags:env:production`: Narrows the results to only include those that also have the tag `env:production`

#### Example for the Bash script

Using this syntax, you can now construct and test more complex queries with the `query_monitors.sh` script:

```sh
# Query for all "alert" or "warn" status monitors tagged with either "team:infra" OR "team:dev"
./query_monitors.sh --query "(status:alert OR status:warn) AND (monitor_tags:team:infra OR monitor_tags:team:dev)" --output-format csv

# Complex notification query with wildcards
./query_monitors.sh --query "notification:(pagerduty-Team-A-* OR pagerduty-Team-B-*)" --output-format json
```

## Pagination and Output Handling

The script automatically handles pagination and will fetch all results across multiple pages. When a query returns more than 30 monitors (the default page size), you'll see progress output like this:

```sh
./query_monitors.sh --query "status:alert" --output-format json
# Output: Fetching page 1...
# Output: Found 3 page(s) of results
# Output: Fetching page 2...
# Output: Fetching page 3...
# Result: All 75 monitors saved to monitors_output.json
```

### CSV Output Format

When using CSV output, the script automatically flattens complex data structures:
- **Arrays** (like tags, metrics) are joined with semicolons: `"tag1;tag2;tag3"`
- **Objects** (like creator info) are converted to JSON strings
- **All data** from all pages is included in a single CSV file

### Wildcard Queries

In Datadog monitor search queries, you can use two types of wildcards: the asterisk (`*`) for multiple characters and the question mark (`?`) for a single character.

#### Multi-character wildcard (`*`)

The asterisk (`*`) matches zero or more characters. It is most commonly used for prefix, suffix, or substring matches within a tag value or monitor name.

**Example scenarios:**

- **Prefix match for monitor names**: To find all monitors whose names start with "API", use:
  ```
  name:API*
  ```
  This would match monitors named "API Health Check," "API Latency," and "API Request Rate."

- **Suffix match for tags**: To find all monitors with a tag value ending in "production", use:
  ```
  monitor_tags:env:*production
  ```
  This would match `env:stg_production` and `env:eu-production`.

- **Substring match for tags**: To find monitors with a tag value that contains the word "db" somewhere in it, use:
  ```
  monitor_tags:*db*
  ```
  This would match tags like `service:postgres-db`, `tier:databasemaster`, or `host:prod-db-server`.

- **Excluding tag values**: To find all monitors except those with a device tag starting with `/dev/loop`, use a negative filter:
  ```
  !device:/dev/loop*
  ```
  This is useful for filtering out temporary or unwanted devices from a query.

#### Single-character wildcard (`?`)

The question mark (`?`) matches exactly one character. This is useful when you need to match a specific pattern with variations.

**Example scenarios:**

- **Tag value with a space or special character**: To find a tag value like "hello world" where the space is treated as a literal character, you can use:
  ```
  @my_attribute:hello?world
  ```
  This syntax matches a single character, including a space.

- **Matching version numbers**: To find all monitors referencing version 1.2.x, you could query:
  ```
  name:service-v1.2.?
  ```
  This would match `service-v1.2.1`, `service-v1.2.2`, etc.

#### Key syntax rules

- **No wildcards in quotes**: Wildcards (`*` or `?`) will be treated as literal characters if they are inside double quotes (`"`).
- **Wildcards outside of attribute/tag search**: In some Datadog explorers (like logs), wildcards can be used in a free-text search outside of a specific field filter, but for monitor queries, it's safest to use them with a specific field like `name` or `monitor_tags`.
- **Combining with boolean operators**: Wildcards work seamlessly with AND, OR, and parentheses to create more powerful and dynamic queries. 