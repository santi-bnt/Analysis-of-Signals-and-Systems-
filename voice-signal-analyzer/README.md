# Voice Signal Analyzer

Aplicación local para capturar voz desde el navegador, mostrar la señal temporal
y calcular su espectro mediante FFT. No incluye reconocimiento ni aprendizaje automático.

## Ejecutar

Necesitas Node.js 20 o posterior. En esta carpeta ejecuta:

```bash
npm install
npm run dev
```

Abre [http://localhost:3000](http://localhost:3000), permite el micrófono y pulsa
**Iniciar grabación**. El acceso al micrófono funciona en `localhost` porque el
navegador lo considera un contexto seguro.

La señal temporal representa la amplitud de cada muestra. Para la FFT se toma un
segmento central de hasta 16384 muestras, se elimina su media, se aplica una
ventana Hann y se calcula un espectro de una cara correctamente normalizado.
