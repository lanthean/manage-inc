#!/bin/env python3
import time
import requests
import subprocess
import re
import yaml

# API Key and Team ID (uncomment and fill with actual values)
# api_key = "clickup-api-key"
# team_id = "team-id"

# API URL to fetch tasks
url = f"https://api.clickup.com/api/v2/team/{team_id}/task"

# Headers for API request
headers = {
    "Authorization": api_key,
    "Content-Type": "application/json"
}

# Track last checked time
last_checked = int(time.time() * 1000)

# Regex pattern to match the required formats
pattern = re.compile(r"(CRQ-\d{4,})|(\d{6,})")

# Load configuration from YAML file
def load_config(file_path="clickup-api-poll.yaml"):
    with open(file_path, "r") as file:
        config = yaml.safe_load(file)
    return config

# Function to translate ClickUp status
def get_status(clickup_status, config):
    status = clickup_status.upper()

    statuses = config.get("statuses", {})  # Get statuses dictionary
    return statuses.get(status, "UNKNOWN")  # Default to "UNKNOWN" if not found

# Function to filter tasks
def filter_tasks(task_list):
    return [task for task in task_list if pattern.search(task["name"])]

def get_case_id(task_name):
    match = pattern.search(task_name)
    return match.group(0) if match else None  # Return matched ID or None

while True:
    try:
        # Query params to get tasks updated since last_checked
        params = {
            "date_updated_gt": last_checked,
        }

        # Fetch tasks updated since the last check
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            filtered_tasks = filter_tasks(response.json().get("tasks", []))
            for task in filtered_tasks:
                task_name = get_case_id(task.get("name", "unknown task"))
                status = get_status(task.get("status", {}).get("status", "unknown status"), load_config())

                if status == "UNKNOWN":
                    print("ERROR: unknown status - {}".format(status))
                    continue

                # Call your bash script with task name and status
                print("INFO: running 'inc {} -s {}'".format(task_name, status))
                subprocess.run(["/home/lanthean/bin/inc", task_name, "-s", status], check=True)

            # Update last_checked to the current time
            last_checked = int(time.time() * 1000)

        else:
            print("Failed to fetch tasks:", response.status_code, response.text)

    except Exception as e:
        print("Error:", e)

    # Sleep for a while before polling again
    time.sleep(60)  # Check every 60 seconds
