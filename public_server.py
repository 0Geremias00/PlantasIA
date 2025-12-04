import time
from pyngrok import ngrok
import sys

def start_public_server():
    # Kill any existing tunnels
    ngrok.kill()
    
    # Open a HTTP tunnel on the default port 5000
    # We use pyngrok to get a public HTTPS URL
    try:
        public_url = ngrok.connect(5000).public_url
        print("\n" + "="*60)
        print(f"🌍 TU SERVIDOR PÚBLICO ESTÁ LISTO")
        print("="*60)
        print(f"\n👉 COPIA ESTA URL PARA TU APP (WebIntoApp):")
        print(f"\n   {public_url}")
        print(f"\n" + "="*60)
        print("\n⚠️ IMPORTANTE:")
        print("1. Esta URL es HTTPS, así que Android NO la bloqueará.")
        print("2. Al abrir la App por primera vez, es posible que veas una pantalla de advertencia de Ngrok.")
        print("   Solo dale a 'Visit Site' y listo.")
        print("3. Mantén esta ventana abierta para que la App funcione.")
        print("\nPresiona Ctrl+C para salir.")
        
        # Keep the script running
        while True:
            time.sleep(1)
            
    except Exception as e:
        print(f"Error: {e}")
        print("Asegúrate de tener internet y que el puerto 5000 esté libre.")

if __name__ == "__main__":
    start_public_server()
