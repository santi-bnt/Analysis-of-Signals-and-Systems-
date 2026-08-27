import numpy as np
import matplotlib.pyplot as plt


def serie_fourier(t, numero_terminos):
    """Calcula una aproximacion de la serie usando `numero_terminos`."""
    resultado = np.full_like(t, 0.504, dtype=float)

    for n in range(1, numero_terminos + 1):
        amplitud = (0.504 * 2) / np.sqrt(1 + 16 * n**2)
        fase = np.arctan(4 * n)
        resultado += amplitud * np.cos(2 * n * t - fase)

    return resultado


def main():
    numero_terminos = 100
    t = np.arange(-6 * np.pi, 6 * np.pi + 0.01, 0.01)
    f_t = serie_fourier(t, numero_terminos)

    plt.figure(figsize=(10, 5))
    plt.plot(t, f_t, label=f"Serie de Fourier ({numero_terminos} terminos)")
    plt.title("Aproximacion de la serie de Fourier")
    plt.xlabel("t")
    plt.ylabel("f(t)")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
