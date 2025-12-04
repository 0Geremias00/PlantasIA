import os
import sys
from pathlib import Path

def renombrar_fotos(directorio, nombre_base="imagen"):
    """
    Renombra todos los archivos en el directorio especificado 
    a un formato secuencial (e.g., nombre_base_001.ext).

    :param directorio: La ruta de la carpeta donde están las fotos.
    :param nombre_base: El nombre que se usará para el nuevo archivo 
                        (por defecto es 'imagen').
    """
    try:
        # Asegurarse de que el directorio existe
        if not os.path.isdir(directorio):
            print(f"❌ Error: El directorio '{directorio}' no fue encontrado. Por favor, verifica la ruta.")
            return

        print(f"📂 Iniciando el proceso de renombrado en: {directorio}")
        
        # --- Lógica de Renombrado (Mantenida de tu script original) ---
        
        # Obtener la lista de todos los archivos y ordenarlos
        archivos = [f for f in os.listdir(directorio) if os.path.isfile(os.path.join(directorio, f))]
        
        # Filtrar solo archivos de imagen comunes para evitar renombrar archivos .py, .txt, etc.
        # Puedes personalizar esta lista
        extensiones_validas = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp']
        archivos_a_renombrar = []
        for f in archivos:
            ext = os.path.splitext(f)[1].lower()
            if ext in extensiones_validas:
                archivos_a_renombrar.append(f)
                
        archivos_a_renombrar.sort() # Ordenar para una secuencia lógica
        
        if not archivos_a_renombrar:
            print("⚠️ Advertencia: No se encontraron archivos de imagen válidos para renombrar.")
            return

        # Contador y cálculo de dígitos
        contador = 1
        num_digitos = len(str(len(archivos_a_renombrar)))

        for nombre_antiguo in archivos_a_renombrar:
            nombre, extension = os.path.splitext(nombre_antiguo)
            
            # Crear el nuevo nombre: nombre_base + número secuencial + extensión
            nuevo_nombre = f"{nombre_base}_{contador:0{num_digitos}d}{extension}"
            
            ruta_antigua = Path(directorio) / nombre_antiguo
            ruta_nueva = Path(directorio) / nuevo_nombre

            # Renombrar el archivo
            os.rename(ruta_antigua, ruta_nueva)
            
            print(f"✅ Renombrado: '{nombre_antiguo}' -> '{nuevo_nombre}'")
            
            contador += 1
            
        print(f"\n🎉 ¡Proceso completado! Se renombraron {contador - 1} archivos.")

    except Exception as e:
        print(f"\n🛑 Ocurrió un error: {e}")
        print("Asegúrate de tener permisos de escritura en la carpeta.")


def main():
    """Función principal para manejar la entrada del usuario."""
    
    # --- 1. Leer argumentos de la línea de comandos (opcional) ---
    if len(sys.argv) > 1:
        # Si el usuario proporciona la ruta como primer argumento
        carpeta = sys.argv[1]
    else:
        # --- 2. Pedir la ruta usando input() si no se proporciona ---
        print("\n--- Herramienta de Renombrado Masivo de Fotos ---")
        carpeta = input("👉 Por favor, ingresa la ruta COMPLETA de la carpeta con las fotos: ").strip()

    # --- 3. Solicitar el nombre base ---
    nombre_base = input("👉 Ingresa el nuevo nombre base (ej: 'evento', deja vacío para 'imagen'): ").strip()
    
    # Usar 'imagen' si el usuario no ingresó nada
    if not nombre_base:
        nombre_base = "imagen"
        
    print("-" * 40)
    
    # Ejecutar la función de renombrado
    renombrar_fotos(carpeta, nombre_base)


# Esto asegura que la función main se ejecute al correr el script
if __name__ == "__main__":
    main()