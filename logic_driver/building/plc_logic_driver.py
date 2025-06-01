import time
from concurrent.futures import ThreadPoolExecutor
from pycomm3 import LogixDriver
from pyrebase import pyrebase
import os
import sys


# Firebase configuration
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
Client = "new_logixdriver"

plc_parameters = {
    'Casting Speed (Mtr per Min)_Strand-1': ("192.168.100.20", "ST1.Casting_Speed"),
    'Mould Oscillator (CPM)_Strand-1': ("192.168.100.50", "Machine_Actual_CPM"),
    'Primary Flow (LPM)_Strand-1': ("192.168.100.20", "ST1.Flot[3]"),
    'Potentiometer_Strand-1': ("192.168.100.20", "Program:Strand_1.Pot_Value_Scada"),
    'CCM Hydraulic Pump_Strand-1': ("192.168.100.20", "DI_FR_ST2.1"),
    'Spray Ring Flow (LPM)_Strand-1': ("192.168.100.81", "Program:MainProgram.AIO50"),
    'Zone1-Flow (LPM)_Strand-1': ("192.168.100.81", "Program:MainProgram.AI06O"),
    'Zone2-Flow (LPM)_Strand-1': ("192.168.100.81", "Program:MainProgram.AI070"),
    'Zone3-Flow (LPM)_Strand-1': ("192.168.100.81", "Program:MainProgram.AI080"),
    'Prim Inlet Temp_Strand-1': ("192.168.100.22", "Primary_Inlet_Temp_PV"),
    'Seco Inlet Temp_Strand-1': ("192.168.100.22", "Seco_Inlet_Temp_PV"),
    'Prim Outlet Temp_Strand-1': ("192.168.100.20", "St1_Prim_Out_mtr"),

    'Casting Speed (Mtr per Min)_Strand-2': ("192.168.100.21", "ST2.Casting_Speed"),
    'Mould Oscillator (CPM)_Strand-2': ("192.168.100.51", "Machine_Actual_CPM"),
    'Primary Flow (LPM)_Strand-2': ("192.168.100.21", "ST2.Flot[3]"),
    'Potentiometer_Strand-2': ("192.168.100.21", "Program:Strand_2.Pot_Value_Scada"),
    'CCM Hydraulic Pump_Strand-2': ("192.168.100.20", "DI_FR_ST2.2"),
    'Spray Ring Flow (LPM)_Strand-2': ("192.168.100.82", "Program:MainProgram.AIO50"),
    'Zone1-Flow (LPM)_Strand-2': ("192.168.100.82", "Program:MainProgram.AI06O"),
    'Zone2-Flow (LPM)_Strand-2': ("192.168.100.82", "Program:MainProgram.AI070"),
    'Zone3-Flow (LPM)_Strand-2': ("192.168.100.82", "Program:MainProgram.AI080"),
    'Prim Inlet Temp_Strand-2': ("192.168.100.22", "Primary_Inlet_Temp_PV"),
    'Seco Inlet Temp_Strand-2': ("192.168.100.22", "Seco_Inlet_Temp_PV"),
    'Prim Outlet Temp_Strand-2': ("192.168.100.21", "St2_Prim_out_pv"),

    'Casting Speed (Mtr per Min)_Strand-3': ("192.168.100.22", "ST3_casting_speed"),
    'Mould Oscillator (CPM)_Strand-3': ("192.168.100.22", "MO_speed_cal"),
    'Mould Oscillator_50 (CPM)_Strand-3': ("192.168.100.22", "MO_CAL_CPM"),
    'Primary Flow (LPM)_Strand-3': ("192.168.100.22", "P_FM_OUT"),
    'Potentiometer_Strand-3': ("192.168.100.22", "Cast_value_SCADA"),
    'CCM Hydraulic Pump_Strand-3': ("192.168.100.22", "HYD_P3_RFB_bit"),
    'CCM Hydraulic Pump_Strand-4': ("192.168.100.22", "HYD_P4_RFB_bit"),
    'Spray Ring Flow (LPM)_Strand-3': ("192.168.100.22", "SEC_SR_FM.Output"),
    'Zone1-Flow (LPM)_Strand-3': ("192.168.100.22", "Zone_1.PV"),
    'Zone2-Flow (LPM)_Strand-3': ("192.168.100.22", "SEC_Z2_FM.Output"),
    'Zone3-Flow (LPM)_Strand-3': ("192.168.100.22", "Zone_3.PV"),
    'Prim Inlet Temp_Strand-3': ("192.168.100.22", "Primary_Inlet_Temp_PV"),
    'Seco Inlet Temp_Strand-3': ("192.168.100.22", "Seco_Inlet_Temp_PV"),
    'Prim Outlet Temp_Strand-3': ("192.168.100.22", "Prim_Out_Temp_PV")
}

def read_plc_data(plc_ip, parameter):
    try:
        with LogixDriver(plc_ip) as plc:
            result = plc.read(parameter)
            return parameter, result[1]
    except Exception as e:
        return parameter, None

def main():
    last_update_time = time.time()  # Track the last successful Firebase update
    watchdog_timeout = 120  # Timeout in seconds for the watchdog
    firebase_delay = 0.5  # Initial delay after Firebase updates (to avoid throttling)
    firebase_throttling_delay = 5
    max_workers = len(plc_parameters)

    while True:
        try:
            print("Started reading!")
            start_time = time.time()

            all_read_results = {}
            exception_keys = []

            # Read PLC data with ThreadPoolExecutor
            with ThreadPoolExecutor(max_workers=max_workers) as executor:  # Limit parallelism to 10 threads
                futures = {executor.submit(read_plc_data, ip, tag): key for key, (ip, tag) in plc_parameters.items()}

                for future in futures:
                    key = futures[future]
                    try:
                        parameter, value = future.result()  # Add a timeout
                        all_read_results[key] = value
                        if value == None:
                            exception_keys.append(key)
                    except Exception as e:
                        pass
               
            # Prepare output dictionary for Firebase
            output_dict = {}
            for key, value in all_read_results.items():
                if "_Strand-" in key:
                    strand = key.split("_Strand-")[1]
                    new_key = key.split("_Strand-")[0]

                    if f"Strand-{strand}" not in output_dict:
                        output_dict[f"Strand-{strand}"] = {}

                    output_dict[f"Strand-{strand}"][new_key] = value

            # Update Firebase
            if output_dict:
                try:
                    db.child(Client).update(output_dict)
                    # print(output_dict)
                    last_update_time = time.time()  # Update watchdog timer
                except Exception as e:
                    if "429" in str(e):  # Detect throttling explicitly
                        time.sleep(firebase_throttling_delay)  # Add an extended delay if throttling occurs

            # Check for watchdog timeout
            if time.time() - last_update_time > watchdog_timeout:
                break  # Exit loop to restart the script

            # Add a short delay after Firebase update to avoid throttling
            # time.sleep(firebase_delay)
            print(f"Total time taken for iteration: {time.time() - start_time:.2f} seconds")


        except Exception as e:
            pass

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        pass
