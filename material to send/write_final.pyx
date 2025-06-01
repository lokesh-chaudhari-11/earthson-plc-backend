import pyrebase
import time
from pycomm3 import SLCDriver  # pip3 install

# Configuration details for Firebase
config = {
    "apiKey": "AIzaSyDY8WQNFX8-UmN7a8PxD9fAn4NTAomEtlY",
    "authDomain": "trial-874f0.firebaseapp.com",
    "databaseURL": "https://trial-874f0-default-rtdb.firebaseio.com/",
    "projectId": "trial-874f0",
    "storageBucket": "trial-874f0.appspot.com",
    "messagingSenderId": "716761006375",
    "appId": "1:716761006375:web:3658bbcd618fab6b1ae902",
    "measurementId": "G-Z9DM98G4RQ"
}

# TODO: Modify the company name that present before the forward slash ("/") only.
Client = "com2/write"  

# Initialize Pyrebase
firebase = pyrebase.initialize_app(config)

# Create a reference to the Earthson node
db = firebase.database()

#TODO: Define PLC IPs for different strands
plc_ips = {
    "STRAND-I": "192.168.100.10",
    "STRAND-II": "192.168.100.11",
}


# TODO: Add a parameter list for address to read from PLC.
# - Key: Displayed on the app; must not contain "/" (forward slash).
# - Format: "PAGE NAME_ROW HEADER" (e.g., "RTC_READY TO CAST").
#   - "RTC" is the PAGE NAME.
#   - "READY TO CAST" is the ROW HEADER.
# - Key must have exactly one "_" and no more.
# - Tag address can contain "/".

plc_parameters_write = {
    "SETTINGS_MOSC AUTO FREQ K2": "N11:7",
    "SETTINGS_MOSC MINIMUM FREQ AT 0 M PER MIN": "N11:13",
    "SETTINGS_AWF AUTO CONSTANT K": "F8:31",
    "RESET": "B3:1/9"
}

initial_data_write = {
    key: 0 if "RESET" not in key else False
    for key in plc_parameters_write.keys()
}


for strand_name,ip in plc_ips.items():
    db.child(f"{Client}/{strand_name}").set(initial_data_write)


# Listener function to handle database events
def listen_for_changes():
    def stream_handler(message):
        try:
            # Split and check if the path contains enough parts
            path_parts = message['path'].split('/')
            if message['path'] == '/':
                print(f"run started!")
                return
            if message['event'] =='put':
                strand_name = path_parts[1]
                parameter_key = path_parts[2]
                val=message['data']
                node = f"/{Client}{message['path']}"
            else:
                strand_name = path_parts[1]
                dic = message['data']
                for key, value in dic.items():
                    parameter_key = key
                    val=value
                node = f"/{Client}{message['path']}/{parameter_key}"
                
            # Get IP and parameter from dictionaries
            ip = plc_ips.get(strand_name)
            if not ip:
                print(f"Error: IP not found for {strand_name}")
                return

            plc_param = plc_parameters_write.get(parameter_key)
            if not plc_param:
                print(f"Error: Parameter not found for {parameter_key}")
                return

            print(f"Writing to PLC {ip}: {plc_param} with data {message['data']}")

            # Connect to PLC and write data
            with SLCDriver(ip) as plc:
                plc.write((plc_param, val))
                if parameter_key == "RESET":
                    db.child(node).set(False)

        except Exception as e:
            print(f"Error in stream handler: {e}")

    # Start listening to changes in the Earthson node
    my_stream = db.child(Client).stream(stream_handler)

    # Keep the stream open
    try:
        print("Listening for changes in the Earthson node...")
        while True:
            time.sleep(1)
            
    except:
        print("Stopped listening.")
       

def main():
    while True:
        try :
            print("started write")
            listen_for_changes()
        except:
            pass

if __name__ == '__main__':
    main()