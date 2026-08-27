"""Graba voz, muestra sus muestras y calcula su FFT."""

import sys

import matplotlib.pyplot as plt
import numpy as np
import sounddevice as sd
from scipy.io.wavfile import write


FS = 16000
DURACION = 3


def grabar_audio():
    """Graba tres segundos y devuelve las muestras en un vector."""
    print("Preparando grabación...")
    print("Habla durante 3 segundos...")

    audio = sd.rec(FS * DURACION, samplerate=FS, channels=1, dtype="float32")
    sd.wait()

    # sounddevice entrega una columna; flatten() la convierte en un vector simple.
    return audio.flatten()


def analizar_audio(audio):
    """Interpreta las muestras en el tiempo y calcula su espectro."""
    numero_muestras = len(audio)
    tiempo = np.arange(numero_muestras) / FS

    # El original se usa en la gráfica temporal.
    audio_sin_dc = audio - np.mean(audio)

    # Hann suaviza los extremos y reduce la fuga espectral.
    ventana = np.hanning(numero_muestras)
    fft = np.fft.rfft(audio_sin_dc * ventana)
    frecuencias = np.fft.rfftfreq(numero_muestras, 1 / FS)

    # Corrección de la ventana y conversión a espectro de una sola cara.
    magnitud = np.abs(fft) / np.sum(ventana)
    magnitud[1:-1] *= 2

    # La posición 0 es la componente DC, así que no se toma como dominante.
    indice_dominante = np.argmax(magnitud[1:]) + 1

    print("\nGrabación terminada.\n")
    print(f"Frecuencia de muestreo: {FS} Hz")
    print(f"Duración: {numero_muestras / FS:.2f} s")
    print(f"Número de muestras: {numero_muestras}\n")
    print(f"Frecuencia dominante: {frecuencias[indice_dominante]:.2f} Hz")
    print(f"Magnitud dominante: {magnitud[indice_dominante]:.6f}")

    plt.figure()
    plt.plot(tiempo, audio)
    plt.title("Señal de voz en el dominio del tiempo")
    plt.xlabel("Tiempo [s]")
    plt.ylabel("Amplitud")
    plt.grid()

    plt.figure()
    plt.plot(frecuencias, magnitud)
    plt.xlim(0, 4000)
    plt.title("Espectro de frecuencias de la voz")
    plt.xlabel("Frecuencia [Hz]")
    plt.ylabel("Magnitud")
    plt.grid()

    plt.show()


def main():
    if "--list-devices" in sys.argv:
        print(sd.query_devices())
        return

    try:
        audio = grabar_audio()

        # Un WAV común guarda las muestras como enteros de 16 bits.
        audio_wav = np.int16(np.clip(audio, -1, 1) * 32767)
        write("grabacion.wav", FS, audio_wav)

        analizar_audio(audio)
    except (sd.PortAudioError, OSError) as error:
        print("Error: no se pudo acceder al micrófono.")
        print(error)
        print("Usa: python main.py --list-devices")


if __name__ == "__main__":
    main()
