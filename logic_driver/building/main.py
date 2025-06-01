import time
import plc_logic_driver  # Replace with the script you want to import

def main():
    print("Master script started. Running the single script...")

    while True:
        try:
            print("Starting the script...")
            plc_logic_driver.main()  # Replace with the imported script's main function
        except Exception as e:
            print(f"Error in script: {e}")
            print("Restarting the script...")
            time.sleep(3)  # Short delay before restarting
        except KeyboardInterrupt:
            print("Master script interrupted. Exiting.")
        except Exception as e:
            print(f"Unexpected error in master script: {e}")

if __name__ == "__main__":
    main()
