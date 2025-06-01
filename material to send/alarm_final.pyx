from pycomm3 import SLCDriver # pip3 install
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pyrebase import pyrebase # pip install pyrebase4

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


# TODO: Modify the company name that appears before the forward slash ("/") only.
Client = "com2/alarm" 

firebase = pyrebase.initialize_app(config)
db = firebase.database()

#TODO: Define PLC IPs for different strands
plc_ips = {                 
    "STRAND-I": "192.168.100.10",
    "STRAND-II": "192.168.100.11",
}

#TODO : add parameter list of Alarm - the key written here will be displayed on App
#Note - the key should not have "/" (forward slash) in it. the tag address can contian '/'
plc_parameters_alarm = {   
   "ENTRY BOTTOM DRIVE FAULT":"N10:10/7",
   "ENTRY TOP DRIVE FAULT" : "N10:5/7",
   "AWF DRIVE FAULT" : "N10:20/7",
   "MCC PANEL PB FAULT" : "B3:2/5",
   "MOULD OSCILATION DRIVE FAULT" : "N10:0/7",
   "PRIMARY COLLING WATER FAIL" : "B3:0/15",
   "RIGGID DUMMY BAR DRIVE FAIL" : "N10:15/7",
   "RTC FAIL": "B3:1/5",
   "SECONDARY WATER FAIL" : "B3:2/10"
}

last_run_dict = {
    strand: {param: False for param in plc_parameters_alarm.keys()}
    for strand in plc_ips.keys()
}

def compare_dicts(dict1, dict2):
    diff = {}

    # Compare the dictionaries key by key
    for key in dict1:
        value1 = dict1[key]
        value2 = dict2[key]

        # If the values are dictionaries, recurse
        if isinstance(value1, dict) and isinstance(value2, dict):
            nested_diff = compare_dicts(value1, value2)
            if nested_diff:  # Only add to diff if there's a difference
                diff[key] = nested_diff
        elif value1 != value2:
            # If values differ, store the value from dict2
            diff[key] = value2

    return diff

# Function to read data from a single PLC
def read_plc_data(plc_ip,strand):
    read_results = {}
    try:
        with SLCDriver(plc_ip) as plc:
            # Prepare a list of addresses to read
            address_list = list(plc_parameters_alarm.values())
            results = plc.read(*address_list)  # Read all addresses at once

            for tag_name, value in zip(plc_parameters_alarm.keys(), results):
                read_results[tag_name] = value[1]
    except Exception as e:
        try:
            read_results = {tag_name: last_run_dict[strand][tag_name] for tag_name in plc_parameters_alarm.keys()}
            print(f"Error reading from {plc_ip}: {e}")
        except:
            read_results = {tag_name: None for tag_name in plc_parameters_alarm.keys()}
            print(f"Error reading from {plc_ip}: {e}")
    return read_results

def main():
    global last_run_dict
    while True:
        try:
            print("started alarm")
            
            # Track start time
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

            #check for modifications
            if all_read_results != last_run_dict:
                db.child(Client).update(all_read_results)
                last_run_dict = all_read_results 

            # not needed code for now 

                # print('start change')
                
                # write the modified value on plc

                # db_read = db.child(Client).get().val()
                # difference_dict = compare_dicts(all_read_results,db_read)
                
                # #write modification to plc
                # for strand,modification_dict in difference_dict.items():
                #     with SLCDriver(plc_ips[strand]) as plc:
                #         for tag_add,tag_val in modification_dict.items():
                #             plc.write((tag_add, tag_val))     


            # Print the total time taken
            print(f"\nTotal time taken: {time.time() - start_time:.2f} seconds")
        except:
            pass
        
if __name__ == '__main__':
    main()