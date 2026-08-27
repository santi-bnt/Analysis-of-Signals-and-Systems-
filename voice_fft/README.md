# Captura de voz y análisis FFT

Este proyecto graba tres segundos de audio mono a 16 kHz, guarda la captura en
`grabacion.wav` y muestra la señal tanto en el dominio del tiempo como en el de
la frecuencia. El análisis termina en la FFT; no incluye reconocimiento ni
clasificación.

## 1. Instalar Python

Instala Python 3.10 o posterior desde [python.org](https://www.python.org/downloads/).
En el instalador de Windows activa **Add Python to PATH**. Comprueba la instalación:

```powershell
python --version
```

## 2. Crear un entorno virtual (opcional, recomendado)

Abre PowerShell en esta carpeta y ejecuta:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Si PowerShell impide activar el entorno, se puede usar directamente:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe main.py
```

## 3. Instalar dependencias

```powershell
python -m pip install -r requirements.txt
```

## 4. Grabar y analizar

```powershell
python main.py
```

Habla cuando aparezca el aviso. Al terminar se abrirán dos ventanas de Matplotlib
y se creará `grabacion.wav` en esta carpeta. Una ejecución posterior reemplaza
ese archivo.

## 5. Dispositivos de audio

Para listar los dispositivos que `sounddevice` puede detectar:

```powershell
python main.py --list-devices
```

Si el micrófono predeterminado falla, selecciona el índice que aparece en la
lista, por ejemplo:

```powershell
python main.py --device 2
```

También se acepta el nombre de un dispositivo entre comillas. En Windows conviene
comprobar además que la terminal tenga permiso para usar el micrófono en
**Configuración > Privacidad y seguridad > Micrófono**.

## Interpretación de las gráficas

La gráfica **Señal de voz en el dominio del tiempo** representa la amplitud de
cada muestra durante los tres segundos. Los tramos con voz suelen mostrar
oscilaciones mayores que el ruido de fondo o el silencio.

La gráfica **Espectro de frecuencias de la voz** muestra cuánto aporta cada
frecuencia a la grabación. Se visualizan de 0 a 4000 Hz, aunque la FFT se calcula
hasta 8000 Hz (la frecuencia de Nyquist para una captura a 16 kHz). El programa
elimina la media, aplica una ventana Hann y corrige su ganancia antes de calcular
el espectro de una cara. La frecuencia dominante impresa es el pico de mayor
magnitud distinto de 0 Hz.
