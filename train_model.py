import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
import numpy as np
import pandas as pd
import os

# Configuración
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 20
LEARNING_RATE = 0.0001
DATASET_DIR = 'dataset'
MODEL_FILENAME = 'keras_Model.h5'
LABELS_FILENAME = 'labels.txt'

def train():
    # Verificar si existe el dataset0
    if not os.path.exists(DATASET_DIR):
        print(f"Error: No se encontró el directorio '{DATASET_DIR}'.")
        print("Por favor crea las carpetas 'hojas_sanas', 'hojas_enfermas', 'frutos_sanos' dentro de 'dataset' y agrega tus imágenes.")
        return

    # Preparar generadores de datos con aumento de datos (Data Augmentation)
    # La normalización en el código de inferencia es (image / 127.5) - 1, que es equivalente a preprocess_input de MobileNetV2
    train_datagen = ImageDataGenerator(
        preprocessing_function=tf.keras.applications.mobilenet_v2.preprocess_input,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        validation_split=0.2  # 20% para validación
    )

    print("Cargando imágenes de entrenamiento...")
    train_generator = train_datagen.flow_from_directory(
        DATASET_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training',
        shuffle=True
    )

    print("Cargando imágenes de validación...")
    validation_generator = train_datagen.flow_from_directory(
        DATASET_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation',
        shuffle=False
    )

    # Guardar las etiquetas (clases)
    labels = list(train_generator.class_indices.keys())
    # El código de inferencia espera un formato específico con índices, ej: "0 hojas_sanas"
    with open(LABELS_FILENAME, 'w') as f:
        for i, label in enumerate(labels):
            f.write(f"{i} {label}\n")
    print(f"Etiquetas guardadas en {LABELS_FILENAME}: {labels}")

    # Crear el modelo base (Transfer Learning)
    base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    
    # Congelar las capas base para no entrenarlas al principio
    base_model.trainable = False

    # Añadir capas personalizadas para nuestra clasificación
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(128, activation='relu')(x)
    x = Dropout(0.5)(x)  # Para evitar overfitting
    predictions = Dense(len(labels), activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=predictions)

    # Compilar el modelo
    model.compile(optimizer=Adam(learning_rate=LEARNING_RATE),
                  loss='categorical_crossentropy',
                  metrics=['accuracy'])

    model.summary()

    # Entrenar el modelo
    print("Iniciando entrenamiento...")
    history = model.fit(
        train_generator,
        steps_per_epoch=train_generator.samples // BATCH_SIZE,
        validation_data=validation_generator,
        validation_steps=validation_generator.samples // BATCH_SIZE,
        epochs=EPOCHS
    )

    # Guardar el modelo
    model.save(MODEL_FILENAME)
    print(f"Modelo guardado como {MODEL_FILENAME}")

    # Usar Pandas para guardar el historial de entrenamiento
    hist_df = pd.DataFrame(history.history)
    hist_csv_file = 'training_history.csv'
    with open(hist_csv_file, mode='w') as f:
        hist_df.to_csv(f)
    print(f"Historial de entrenamiento guardado en {hist_csv_file}")

    # Mostrar las últimas métricas
    print("\nMétricas finales:")
    print(hist_df.tail(1))

if __name__ == '__main__':
    train()
