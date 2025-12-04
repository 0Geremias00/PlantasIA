import subprocess
import sys
import re

def run_tunnel():
    print("Iniciando túnel seguro (HTTPS)... Espere un momento.")
    # Force pseudo-tty allocation to prevent buffering issues if possible, though on Windows it's harder.
    # We just run standard ssh.
    cmd = ["ssh", "-o", "StrictHostKeyChecking=no", "-R", "80:localhost:5000", "nokey@localhost.run"]
    
    # Use shell=True for windows compatibility sometimes helps with path, but usually not needed for ssh if in path.
    # We'll try to catch stdout.
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    
    url_found = False
    
    print("\n" + "="*50)
    print("BUSCANDO URL PÚBLICA...")
    print("="*50 + "\n")

    try:
        for line in process.stdout:
            # Print line for debug
            # print(f"DEBUG: {line.strip()}")
            
            # Look for https url but ignore the docs link
            if "https://" in line and "docs/forever-free" not in line:
                url = re.search(r'(https://[^\s]+)', line).group(1)
                print("\n" + "⭐"*20)
                print("¡ÉXITO! TU URL SEGURA ES:")
                print(f"\n   {url}\n")
                print("⭐"*20 + "\n")
                print("👉 Copia esta URL y pégala en WebIntoApp (campo URL).")
                print("   Luego dale a 'Make App' de nuevo.")
                
                # Save to file
                with open("url.txt", "w") as f:
                    f.write(url)
                
                url_found = True
            
            if "tunneled with tls" in line and not url_found:
                 # Sometimes it says "tunneled with tls change http://... to https://..."
                 pass

    except KeyboardInterrupt:
        print("\nCerrando túnel...")
        process.terminate()

if __name__ == "__main__":
    run_tunnel()
