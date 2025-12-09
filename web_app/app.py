import os
import numpy as np
from flask import Flask, render_template, request, jsonify
from tensorflow.keras.models import load_model
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.preprocessing.image import img_to_array
from PIL import Image
import io
import tensorflow as tf
import gc

app = Flask(__name__)

# Rutas a los archivos (ajustar según la estructura de carpetas)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, '..', 'keras_Model.h5')
LABELS_PATH = os.path.join(BASE_DIR, '..', 'labels.txt')

print(f"Cargando modelo desde: {MODEL_PATH}")
model = load_model(MODEL_PATH)
print("Modelo cargado exitosamente.")

# Cargar etiquetas
labels = {}
with open(LABELS_PATH, 'r') as f:
    for line in f:
        parts = line.strip().split(' ')
        if len(parts) >= 2:
            index = int(parts[0])
            label = ' '.join(parts[1:])
            labels[index] = label
print(f"Etiquetas cargadas: {labels}")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        # Leer la imagen
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        
        # Preprocesar la imagen
        image = image.resize((224, 224))
        img_array = img_to_array(image)
        
        # Expandir dimensiones
        img_array = np.expand_dims(img_array, axis=0)
        
        # Preprocesamiento específico de MobileNetV2
        img_array = preprocess_input(img_array)
        
        # Realizar predicción
        predictions = model.predict(img_array)
        
        predicted_class_index = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class_index])
        
        # Umbral de confianza (70%)
        if confidence < 0.70:
            predicted_label = "No identificado / Fondo (Baja confianza)"
        else:
            predicted_label = labels.get(predicted_class_index, "Desconocido")
            if predicted_label == "otros":
                predicted_label = "No es una planta / Error"
        
        # Limpiar memoria
        del img_array, image
        gc.collect()

        return jsonify({
            'label': predicted_label,
            'confidence': f"{confidence * 100:.2f}%",
            'all_predictions': {labels[i]: float(prob) for i, prob in enumerate(predictions[0])}
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    import socket
    def get_ip():
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            # doesn't even have to be reachable
            s.connect(('10.255.255.255', 1))
            IP = s.getsockname()[0]
        except Exception:
            IP = '127.0.0.1'
        finally:
            s.close()
        return IP

    host_ip = get_ip()
    print(f"\n\n --- ACCESO DESDE CELULAR ---")
    print(f" 1. Asegúrate de que tu celular y PC estén en el mismo WiFi.")
    print(f" 2. Desactiva temporalmente el Firewall de Windows si no carga.")
    print(f" 3. Abre esta dirección en tu celular:")
    print(f"    👉 http://{host_ip}:5000")
    print(f" ----------------------------\n\n")

    app.run(debug=True, host='0.0.0.0', port=5000)
