#!/bin/env python3
import time
import requests
import subprocess

# API Key and Team ID
api_key = "clickup-api-key"
team_id = "team-id"

# API URL to fetch tasks
url = f"https://api.clickup.com/api/v2/team/{team_id}/task"

# Headers for API request
headers = {
    "Authorization": api_key,
    "Content-Type": "application/json"
}

# Track last checked time
last_checked = int( time.time() * 1000)

def get_status(status):
    JIRA_IP="ip"
    JIRA_WA="wa"
    JIRA_AA="aa"
    JIRA_AP="ap"
    JIRA_AR="ar"
    JIRA_ID="id"
    JIRA_DE="de"
    JIRA_OH="oh"
    JIRA_RJ="rj"
    JIRA_DO="do"
    status = status.upper()

    if status == "IN PROGRESS":
        ret = JIRA_IP
    elif status == "WAITING":
        ret = JIRA_WA
    elif status == "AWAITING ASSESSMENT":
        ret = JIRA_AA
    elif status == "AWAITING PO":
        ret = JIRA_AP
    elif status == "ACCEPTED TO ROADMAP":
        ret = JIRA_AR
    elif status == "IN DEVELOPMENT":
        ret = JIRA_ID
    elif status == "DEVELOPED":
        ret = JIRA_DE
    elif status == "ON HOLD":
        ret = JIRA_OH
    elif status == "REJECTED":
        ret = JIRA_RJ
    elif status == "DONE":
        ret = JIRA_DO
    elif status == "AWAITING PO":
        ret = JIRA_AP
    elif status == "AWAITING PO":
        ret = JIRA_AP
    elif status == "AWAITING PO":
        ret = JIRA_AP
    elif status == "AWAITING PO":
        ret = JIRA_AP
    elif status == "AWAITING PO":
        ret = JIRA_AP
    elif status == "AWAITING PO":
        ret = JIRA_AP
    else:
        print(status)
        ret = "UNKNOWN"

    return ret

def get_case_id(task_name):
    if "[" in task_name:
        start_position = task_name.find("[") + 1
        end_position = task_name.find("]")
        crq_portion = task_name[start_position:end_position]
    else:
        crq_portion = task_name.split(' ')[0]
    
    return crq_portion

while True:
    try:
        # Query params to get tasks updated since last_checked
        params = {
            "date_updated_gt": last_checked,
        }

        # Fetch tasks updated since the last check
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            tasks = response.json().get("tasks", [])
            
            crq_tasks = [task for task in tasks if "CRQ" in task.get("name", "").upper()]
            for task in crq_tasks:
                task_name = get_case_id(task.get("name", "unknown task"))
                status = get_status(task.get("status", {}).get("status", "unknown status"))
                
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
    time.sleep(5)  # Check every 60 seconds
