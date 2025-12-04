import subprocess
import sys

def run_tunnel():
    cmd = ["ssh", "-o", "StrictHostKeyChecking=no", "-R", "80:localhost:5000", "nokey@localhost.run"]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    
    print("Starting tunnel...")
    count = 0
    for line in process.stdout:
        count += 1
        if count < 10: continue
        if count > 40: break
        # Replace block characters often used in QR codes
        clean_line = line.replace('█', ' ').replace('▀', ' ').replace('▄', ' ')
        print(f"LINE {count}: {clean_line.strip()}")
        sys.stdout.flush()

if __name__ == "__main__":
    run_tunnel()
