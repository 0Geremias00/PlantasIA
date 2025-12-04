if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/static/sw.js')
            .then(registration => {
                console.log('ServiceWorker registration successful with scope: ', registration.scope);
            }, err => {
                console.log('ServiceWorker registration failed: ', err);
            });
    });
}

document.addEventListener('DOMContentLoaded', () => {
    // Splash Screen Logic
    const splashScreen = document.getElementById('splash-screen');
    if (splashScreen) {
        // Mínimo 2.5 segundos de splash para que se vea la animación completa
        setTimeout(() => {
            splashScreen.classList.add('hidden');
        }, 2500);
    }

    const video = document.getElementById('video');
    const canvas = document.getElementById('canvas');
    const startCameraBtn = document.getElementById('startCameraBtn');
    const stopCameraBtn = document.getElementById('stopCameraBtn');
    const captureBtn = document.getElementById('captureBtn');
    const resetBtn = document.getElementById('resetBtn');
    const fileInput = document.getElementById('fileInput');
    const videoContainer = document.getElementById('videoContainer');
    const placeholderIcon = document.getElementById('placeholder-icon');
    const resultsSection = document.getElementById('resultsSection');
    const loadingSpinner = document.getElementById('loadingSpinner');
    const resultContent = document.getElementById('resultContent');
    const labelResult = document.getElementById('labelResult');
    const confidenceResult = document.getElementById('confidenceResult');
    const confidenceBar = document.getElementById('confidenceBar');
    const predictionIcon = document.getElementById('predictionIcon');

    let stream = null;

    // Iniciar cámara
    // Helper para logs en pantalla
    function logDebug(msg) {
        const debugDiv = document.getElementById('debug-log');
        debugDiv.style.display = 'block';
        debugDiv.textContent += msg + '\n';
        console.log(msg);
    }

    // Iniciar cámara
    startCameraBtn.addEventListener('click', async () => {
        logDebug("Intentando iniciar cámara...");
        
        // Verificación básica de soporte
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
            logDebug("API de cámara no disponible. Activando modo compatibilidad.");
            
            // TRUCO: Si no hay acceso a la webcam (por falta de HTTPS),
            // abrimos automáticamente el selector de archivos (que en celular permite usar la cámara nativa).
            alert("⚠️ Modo Compatibilidad Activado\n\nComo no estamos usando HTTPS, el navegador bloquea la cámara web directa.\n\nSe abrirá la cámara de tu sistema en su lugar.");
            const camInput = document.getElementById('cameraInput');
            if (camInput) camInput.click();
            else fileInput.click();
            return;
        }

        try {
            // Intentar primero con la cámara trasera
            try {
                logDebug("Solicitando cámara trasera...");
                stream = await navigator.mediaDevices.getUserMedia({ 
                    video: { facingMode: 'environment' } 
                });
                logDebug("Cámara trasera obtenida.");
            } catch (err) {
                logDebug("Fallo cámara trasera: " + err.message);
                logDebug("Intentando cámara por defecto...");
                stream = await navigator.mediaDevices.getUserMedia({ 
                    video: true 
                });
                logDebug("Cámara por defecto obtenida.");
            }

            video.srcObject = stream;
            video.style.display = 'block';
            canvas.style.display = 'none';
            placeholderIcon.style.display = 'none';
            
            startCameraBtn.style.display = 'none';
            stopCameraBtn.style.display = 'flex';
            captureBtn.disabled = false;
            
            videoContainer.classList.remove('scanning');
            resultContent.style.display = 'none';
            logDebug("Cámara iniciada correctamente.");
            
        } catch (err) {
            logDebug("ERROR: " + err.name + ": " + err.message);
            console.error("Error al acceder a la cámara:", err);
            
            // Mensaje amigable para el usuario
            alert("⚠️ No se pudo acceder a la cámara.\n\nEsto es normal si no estás usando HTTPS.\n\n👉 SOLUCIÓN: Usa el botón 'Subir Imagen' para tomar una foto directamente.");
        }
    });

    // Detener cámara
    stopCameraBtn.addEventListener('click', () => {
        if (stream) {
            stream.getTracks().forEach(track => track.stop());
            stream = null;
            video.srcObject = null;
        }
        video.style.display = 'none';
        placeholderIcon.style.display = 'block';
        
        // Toggle buttons
        startCameraBtn.style.display = 'flex';
        stopCameraBtn.style.display = 'none';
        captureBtn.disabled = true;
    });

    // Resetear todo
    resetBtn.addEventListener('click', () => {
        resultContent.style.display = 'none';
        fileInput.value = ''; // Limpiar input file
        
        // Si la cámara estaba activa, la dejamos activa pero limpiamos el canvas
        if (stream) {
            video.style.display = 'block';
            canvas.style.display = 'none';
            captureBtn.disabled = false;
        } else {
            // Si no, volvemos al estado inicial completo
            canvas.style.display = 'none';
            video.style.display = 'none';
            placeholderIcon.style.display = 'flex'; // Changed to flex to match CSS
            
            // Reset buttons state
            startCameraBtn.style.display = 'flex';
            stopCameraBtn.style.display = 'none';
            captureBtn.disabled = true;
        }
    });

    // Capturar foto
    captureBtn.addEventListener('click', () => {
        if (!stream) return;

        const context = canvas.getContext('2d');
        
        // Limitar resolución para evitar problemas de memoria en móviles
        const MAX_WIDTH = 640;
        let width = video.videoWidth;
        let height = video.videoHeight;

        if (width > MAX_WIDTH) {
            height *= MAX_WIDTH / width;
            width = MAX_WIDTH;
        }

        canvas.width = width;
        canvas.height = height;
        context.drawImage(video, 0, 0, width, height);
        
        video.style.display = 'none';
        canvas.style.display = 'block';
        
        // Detener el stream para ahorrar recursos
        stream.getTracks().forEach(track => track.stop());
        stream = null;
        captureBtn.disabled = true;
        
        // Update buttons to show we are stopped
        startCameraBtn.style.display = 'flex';
        stopCameraBtn.style.display = 'none';

        // Enviar imagen al backend
        canvas.toBlob(blob => {
            sendImage(blob);
        }, 'image/jpeg');
    });

    // Detectar si estamos en móvil y sin HTTPS (para mejorar la UI)
    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    const isSecure = window.isSecureContext;
    const mobileScanBtn = document.getElementById('mobileScanBtn');
    const uploadBtn = document.getElementById('uploadBtn');

    // Si estamos en móvil y no es seguro (HTTP), mostrar botón directo de escaneo
    if (isMobile && !isSecure) {
        startCameraBtn.style.display = 'none';
        uploadBtn.parentElement.style.display = 'none'; // Ocultar botones de escritorio
        mobileScanBtn.style.display = 'flex';
        
        // Mensaje de ayuda
        const p = document.createElement('p');
        p.textContent = "Modo Móvil Activado";
        p.style.textAlign = "center";
        p.style.color = "var(--primary-color)";
        p.style.marginTop = "10px";
        mobileScanBtn.parentNode.insertBefore(p, mobileScanBtn);
    }

    mobileScanBtn.addEventListener('click', () => {
        const cameraInput = document.getElementById('cameraInput');
        cameraInput.click();
    });

    // Helper para procesar archivos (reutilizable)
    async function handleFileSelect(e) {
        if (e.target.files && e.target.files[0]) {
            const file = e.target.files[0];
            
            try {
                // Optimización EXTREMA: Usar createImageBitmap
                // Es asíncrono y mucho más eficiente para el navegador que crear un elemento <img>
                const bitmap = await createImageBitmap(file);
                
                // Reducir resolución drásticamente para evitar crash
                const MAX_WIDTH = 500; // Bajamos a 500px para asegurar estabilidad
                let width = bitmap.width;
                let height = bitmap.height;

                if (width > MAX_WIDTH) {
                    height *= MAX_WIDTH / width;
                    width = MAX_WIDTH;
                }

                canvas.width = width;
                canvas.height = height;
                const ctx = canvas.getContext('2d');
                
                // Limpiar y dibujar
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                ctx.drawImage(bitmap, 0, 0, width, height);
                
                // Cerrar bitmap para liberar memoria
                bitmap.close();
                
                // Actualizar UI
                video.style.display = 'none';
                canvas.style.display = 'block';
                placeholderIcon.style.display = 'none';
                
                if (stream) {
                    stream.getTracks().forEach(track => track.stop());
                    stream = null;
                }
                
                // Enviar al backend
                canvas.toBlob(blob => {
                    if (blob) {
                        sendImage(blob);
                    } else {
                        alert("Error de memoria al procesar la imagen.");
                    }
                }, 'image/jpeg', 0.7); // Calidad 0.7

            } catch (err) {
                console.error(err);
                alert("Tu celular tiene poca memoria libre. Intenta cerrar otras apps o tomar una foto con menos resolución.");
            }
        }
    }

    // Subir archivo (Galería/Selector)
    fileInput.addEventListener('change', handleFileSelect);

    // Input de Cámara (Solo para fallback móvil)
    const cameraInput = document.getElementById('cameraInput');
    if (cameraInput) {
        cameraInput.addEventListener('change', handleFileSelect);
    }

    async function sendImage(imageBlob) {
        // Mostrar loading
        loadingSpinner.style.display = 'flex';
        resultContent.style.display = 'none';
        videoContainer.classList.add('scanning');

        const formData = new FormData();
        formData.append('image', imageBlob, 'capture.jpg');

        try {
            const response = await fetch('/predict', {
                method: 'POST',
                body: formData
            });

            if (!response.ok) throw new Error('Error en la predicción');

            const data = await response.json();
            displayResult(data);

        } catch (error) {
            console.error('Error:', error);
            alert('Ocurrió un error al procesar la imagen.');
        } finally {
            loadingSpinner.style.display = 'none';
            videoContainer.classList.remove('scanning');
        }
    }

    function displayResult(data) {
        resultContent.style.display = 'block';
        
        // Actualizar textos
        labelResult.textContent = data.label.replace(/_/g, ' '); // Reemplazar guiones bajos por espacios
        confidenceResult.textContent = data.confidence;
        
        // Actualizar barra de progreso
        // Extraer el número del string "99.99%"
        const confidenceValue = parseFloat(data.confidence);
        setTimeout(() => {
            confidenceBar.style.width = `${confidenceValue}%`;
        }, 100);

        // Cambiar color/icono según el resultado
        // Asumiendo que "sano" es bueno y "enfermo" es malo
        const labelLower = data.label.toLowerCase();
        if (labelLower.includes('sano') || labelLower.includes('healthy') || labelLower.includes('verde')) {
            predictionIcon.style.color = 'var(--success-color)';
            predictionIcon.style.background = 'rgba(34, 197, 94, 0.2)';
            predictionIcon.innerHTML = '<i class="fa-solid fa-check-circle"></i>';
            confidenceBar.style.background = 'var(--success-color)';
        } else if (labelLower.includes('enfermo') || labelLower.includes('disease')) {
            predictionIcon.style.color = 'var(--danger-color)';
            predictionIcon.style.background = 'rgba(239, 68, 68, 0.2)';
            predictionIcon.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i>';
            confidenceBar.style.background = 'var(--danger-color)';
        } else {
            predictionIcon.style.color = 'var(--warning-color)';
            predictionIcon.style.background = 'rgba(234, 179, 8, 0.2)';
            predictionIcon.innerHTML = '<i class="fa-solid fa-question-circle"></i>';
            confidenceBar.style.background = 'var(--warning-color)';
        }

        // Scroll suave hacia los resultados en móviles
        if (window.innerWidth < 768) {
            resultsSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }
});
