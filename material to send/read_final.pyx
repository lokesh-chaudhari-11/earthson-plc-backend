from pycomm3 import SLCDriver # pip3 install
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pyrebase import pyrebase # pip install pyrebase4
import requests

# TODO: Modify the company name that appears before the forward slash ("/") only.
Client = "com2/read/" 


config = {
    "databaseURL": "https://trial-874f0-default-rtdb.firebaseio.com/",
    "apiKey": "AIzaSyDY8WQNFX8-UmN7a8PxD9fAn4NTAomEtlY",
    "authDomain": "trial-874f0.firebaseapp.com",
    "projectId": "trial-874f0",
    "storageBucket": "trial-874f0.appspot.com",
    "messagingSenderId": "716761006375",
    "appId": "1:716761006375:web:3658bbcd618fab6b1ae902",
    "measurementId": "G-Z9DM98G4RQ"
}

firebase = pyrebase.initialize_app(config)
db = firebase.database()

#TODO: Define PLC IPs for different strands
plc_ips = {              
    "STRAND-I": "192.168.100.10",
    "STRAND-II": "192.168.100.11",
}


# TODO: Add a parameter list for reading from PLC.
# - Key: Displayed on the app; must not contain "/" (forward slash).
# - Format: "PAGE NAME_ROW HEADER" (e.g., "RTC_READY TO CAST").
#   - "RTC" is the PAGE NAME.
#   - "READY TO CAST" is the ROW HEADER.
# - Key must have exactly one "_" and no more.
# - Tag address can contain "/".

plc_parameters_read = {
    "RTC_READY TO CAST": "B3:1/4",
    "RTC_PRIMARY COOLING WATER": "B3:2/5",
    "RTC_WITH HYD PUMP-I OR II": "B3:0/15",
    "RTC_MODE SELECTED": "N11:0",
    "RTC_MOULD OSCILLATOR MODE": "B3:0/6",
    "RTC_RBD EMG STOP PB": "B3:1/14",
    "RTC_MOULD OSCILLATION DRIVE": "N10:0/7",
    "RTC_ENTRY TOP DRIVE": "N10:5/7",
    "RTC_ENTRY BOTTOM DRIVE": "N10:10/7",
    "RTC_RBD DRIVE": "N10:15/7",
    "RTC_AWF DRIVE": "N10:20/7",
    "RTC_DB INSERT MODE ": "B3:2/11", 
    "RTC_DB CASTING SWITCH" : "B3:2/12",
    "RTC_POT ZERO CONDITION": "B3:1/6",
    
    "CAST PARAMETER_CASTING STATUS": "B3:1/2",
    "CAST PARAMETER_CASTING SPEED": "F8:9",
    "CAST PARAMETER_MOULD OSCL FREQUENCY": "N11:15",
    "CAST PARAMETER_MOULD OSCILLATION DRIVE_HZ": "F8:40",
    "CAST PARAMETER_MOULD OSCILLATION DRIVE_AMP": "F8:50",
    "CAST PARAMETER_ENTRY TOP DRIVE_HZ": "F8:41",
    "CAST PARAMETER_ENTRY TOP DRIVE_AMP": "F8:51",
    "CAST PARAMETER_ENTRY BOTTOM DRIVE_HZ": "F8:42",
    "CAST PARAMETER_ENTRY BOTTOM DRIVE_AMP": "F8:52",
    "CAST PARAMETER_RDB DRIVE_HZ": "F8:43",
    "CAST PARAMETER_RDB DRIVE_AMP": "F8:53",
    "CAST PARAMETER_AWF DRIVE_HZ": "F8:11",
    "CAST PARAMETER_AWF DRIVE_AMP": "F8:12",
    "CAST PARAMETER_AWF AUTO PER MAN SELECT": "B3:1/13",
    "CAST PARAMETER_SPRAY RING FLOW": "F21:0",
    "CAST PARAMETER_ZONE-1 FLOW": "F21:1",
    
	"SHEARING_PARAMETER BILLET TEMPERATURE": "N12:11",
	"SHEARING_PARAMETER BILLET COUNTER": "C5:1.ACC",
 
    "SETTINGS_MOSC AUTO FREQ K2": "N11:7",
    "SETTINGS_MOSC MINIMUM FREQ AT 0 M PER MIN": "N11:13",
    "SETTINGS_MOULD OSCI FREQUENCY": "N11:15",
    "SETTINGS_AWF AUTO CONSTANT K": "F8:31",
}

last_run_dict ={}


# TODO: Add the exact same parameter from the above dictionary to the set below 
# if you want to set the value to either "FAULT" or "READY" for any KEY.

ready_fault_key_set = {
    "RTC_MOULD OSCILLATION DRIVE",
    "RTC_ENTRY TOP DRIVE",
    "RTC_ENTRY BOTTOM DRIVE",
    "RTC_RBD DRIVE",
    "RTC_AWF DRIVE"
}

# TODO: Define the mode to be displayed on the app for values read from the PLC.
mode_selected = {0:"OFF", 1 :"CASTING MODE", 2 :"MOP",3:"IOP",4:"MCD"}

def modified_read(dic):
    for kd, vd in dic.items():
        if kd in ready_fault_key_set:
            dic[kd] = "FAULT" if vd==True else "READY"
        elif kd == "RTC_MODE SELECTED":
            dic[kd] = mode_selected.get(vd, "OFF") 
        elif kd == "RTC_READY TO CAST":
            dic[kd] = "OK" if vd==True else "OFF"
        elif kd in ["RTC_WITH HYD PUMP-I OR II", "CAST PARAMETER_CASTING STATUS"]:
            dic[kd] = "ON" if vd==True else "OFF"
        elif kd in ["RTC_PRIMARY COOLING WATER"]:
            dic[kd] = "READY" if vd==True else "NOT READY"
        elif kd in ["RTC_MOULD OSCILLATOR MODE","CAST PARAMETER_AWF AUTO PER MAN SELECT"]:
            dic[kd] = "MANUAL" if vd==True else "AUTO"
        elif kd in ["RTC_RBD EMG STOP PB"]:
            dic[kd] = "ACTIVE" if vd==True else "RELEASE"
        elif kd == "RTC_DB INSERT MODE OR CASTING SWITCH":
            dic[kd] = "CASTING MODE" if vd==True else "INSERT MODE"
        elif kd in ["RTC_POT ZERO CONDITION"]:
            dic[kd] = "ZERO" if vd==True else "NOT ZERO"
    
    return dic


# Function to read data from a single PLC
def read_plc_data(plc_ip,strand):
    read_results = {}
    try:
        with SLCDriver(plc_ip) as plc:
            # Prepare a list of addresses to read
            address_list = list(plc_parameters_read.values())
            results = plc.read(*address_list)  # Read all addresses at once

            for tag_name, value in zip(plc_parameters_read.keys(), results):
                read_results[tag_name] = value[1] 
    except Exception as e:
        try:
            read_results = {tag_name: last_run_dict[strand][tag_name] for tag_name in plc_parameters_read.keys()}
            print(f"Error reading from {plc_ip}: {e}")
        except:
            read_results = {tag_name: None for tag_name in plc_parameters_read.keys()}
            print(f"Error reading from {plc_ip}: {e}")
   
    return modified_read(read_results)


def main():
    global plc_ips,Client
    while True:
        try:
        # Track start time
            print("started read")
            start_time = time.time()

            # Dictionary to store all read results
            all_read_results = {}
            
            # Use ThreadPoolExecutor to read data from multiple PLCs concurrently
            max_workers = len(plc_ips)  # Set the maximum number of concurrent threads
            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                futures = {executor.submit(read_plc_data, plc_ip,strand): strand for strand, plc_ip in plc_ips.items()}
                
                for future in as_completed(futures):
                    strand = futures[future]  # Get the corresponding strand
                    result = future.result()
                    all_read_results[strand] = result
            
            # Print all the results for each strand
            try:
                db.child(Client).update(all_read_results)
                global last_run_dict 
                last_run_dict = all_read_results
            except Exception as e:
                print(e)
                
                

            # Print the total time taken
            print(f"\nTotal time taken: {time.time() - start_time:.2f} seconds")
                        
        except:
            pass
    
if __name__ == '__main__':
    main()


