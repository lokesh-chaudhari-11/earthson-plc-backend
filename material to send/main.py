import threading
import time
import read_final
import write_final
import alarm_final


def run_script(script, name):
    """
    Runs the 'main' function of the imported script,
    restarting it if an error occurs, and prints events to the console.
    """
    while True:
        try:
            print(f"Starting {name} script...")
            script.main()
        except Exception as e:
            print(f"Error in {name}: {e}")
            print(f"Restarting {name} script...")
            time.sleep(3)  # Short delay before restarting

def main():
    print("Master script started. Launching all scripts...")

    # Create threads to run each script in parallel
    threads = []
    threads.append(threading.Thread(target=run_script, args=(read_final, "read_final"), daemon=True))
    threads.append(threading.Thread(target=run_script, args=(write_final, "write_final"), daemon=True))
    threads.append(threading.Thread(target=run_script, args=(alarm_final, "alarm_final"), daemon=True))

    # Start each thread
    for thread in threads:
        thread.start()

    print("All scripts are running in the background.")

    # Keep the master script running indefinitely
    try:
        while True:
            time.sleep(1)  # Prevent busy waiting
    except KeyboardInterrupt:
        print("Master script interrupted. Stopping all scripts.")
    except Exception as e:
        print(f"Unexpected error in master script: {e}")

if __name__ == "__main__":
    main()
