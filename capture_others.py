import cv2
import os
import time

def capture_images(output_dir='dataset/otros', num_images=50):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: No se pudo abrir la cámara.")
        return

    print(f"--- Captura de imágenes para la clase 'otros' ---")
    print(f"Presiona 's' para guardar una imagen.")
    print(f"Presiona 'q' para salir.")
    print(f"Guardando en: {output_dir}")

    count = len(os.listdir(output_dir))
    
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Error al leer el frame.")
            break

        cv2.imshow('Captura - Presiona "s" para guardar', frame)

        key = cv2.waitKey(1) & 0xFF
        if key == ord('s'):
            filename = os.path.join(output_dir, f"otros_{count}.jpg")
            cv2.imwrite(filename, frame)
            print(f"Imagen guardada: {filename}")
            count += 1
        elif key == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()
    print("Captura finalizada.")

if __name__ == "__main__":
    capture_images()
