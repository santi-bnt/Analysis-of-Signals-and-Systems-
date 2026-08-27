"use client";
import { useRef,useState } from "react";
import SignalChart from "../components/SignalChart";
import { createWav } from "../lib/audio";
import { calculateSpectrum,Spectrum } from "../lib/fft";

type Recording={samples:Float32Array;sampleRate:number;duration:number;wavUrl:string};

export default function Home(){
  const [allowed,setAllowed]=useState(false),[duration,setDuration]=useState(3),[countdown,setCountdown]=useState(0),[level,setLevel]=useState(0);
  const [status,setStatus]=useState("Listo"),[error,setError]=useState(""),[recording,setRecording]=useState<Recording|null>(null),[spectrum,setSpectrum]=useState<Spectrum|null>(null),[range,setRange]=useState(4000);
  const streamRef=useRef<MediaStream|null>(null);

  async function allowMicrophone(){
    if(!navigator.mediaDevices?.getUserMedia||!window.AudioContext||!window.MediaRecorder){setError("Tu navegador no soporta las funciones de audio necesarias.");return;}
    try{streamRef.current=await navigator.mediaDevices.getUserMedia({audio:true});setAllowed(true);setError("");}
    catch(reason){const name=reason instanceof DOMException?reason.name:"";setError(name==="NotFoundError"?"No se encontró un dispositivo de entrada de audio.":"No se pudo acceder al micrófono. Revisa los permisos del navegador.");}
  }

  async function startRecording(){
    const stream=streamRef.current;if(!stream)return allowMicrophone();
    setError("");setRecording(null);setSpectrum(null);setStatus("Grabando...");setCountdown(duration);
    const context=new AudioContext(),analyser=context.createAnalyser();context.createMediaStreamSource(stream).connect(analyser);
    const levels=new Uint8Array(analyser.frequencyBinCount);let animation=0;
    const update=()=>{analyser.getByteTimeDomainData(levels);let sum=0;levels.forEach(v=>{const n=(v-128)/128;sum+=n*n;});setLevel(Math.min(1,Math.sqrt(sum/levels.length)*3));animation=requestAnimationFrame(update);};update();
    const recorder=new MediaRecorder(stream),chunks:Blob[]=[];recorder.ondataavailable=e=>chunks.push(e.data);recorder.start();
    const timer=setInterval(()=>setCountdown(v=>Math.max(0,v-1)),1000);await new Promise(r=>setTimeout(r,duration*1000));
    recorder.stop();await new Promise<void>(resolve=>{recorder.onstop=()=>resolve();});clearInterval(timer);cancelAnimationFrame(animation);setLevel(0);setCountdown(0);
    try{
      const encoded=new Blob(chunks,{type:recorder.mimeType}),decoded=await context.decodeAudioData(await encoded.arrayBuffer()),samples=decoded.getChannelData(0).slice();
      const wavUrl=URL.createObjectURL(createWav(samples,decoded.sampleRate)),result=calculateSpectrum(samples,decoded.sampleRate);
      setRecording({samples,sampleRate:decoded.sampleRate,duration:decoded.duration,wavUrl});setSpectrum(result);setStatus("Grabación terminada");
    }catch{setError("No se pudo procesar la grabación. Inténtalo nuevamente.");setStatus("Listo");}finally{await context.close();}
  }

  const timeX=recording?Array.from({length:recording.samples.length},(_,i)=>i/recording.sampleRate):[];
  const end=spectrum&&range!==Infinity?spectrum.frequencies.findIndex(f=>f>range):-1;
  const frequencyX=spectrum?spectrum.frequencies.slice(0,end<0?undefined:end):[],frequencyY=spectrum?spectrum.magnitudes.slice(0,end<0?undefined:end):[];
  return <main>
    <header><div className="brandMark">V</div><div><h1>Voice Signal Analyzer</h1><p>Analiza tu voz en el dominio del tiempo y frecuencia.</p></div><span className="tag">Laboratorio de señales</span></header>
    <section className="recorder card"><div className={`mic ${status==="Grabando..."?"active":""}`}>●</div>
      {!allowed?<button onClick={allowMicrophone}>Permitir micrófono</button>:<div className="controls"><label>Duración<select value={duration} onChange={e=>setDuration(Number(e.target.value))} disabled={status==="Grabando..."}>{[1,2,3,5].map(v=><option key={v} value={v}>{v} segundo{v>1?"s":""}</option>)}</select></label><button onClick={startRecording} disabled={status==="Grabando..."}>{recording?"Grabar nuevamente":"Iniciar grabación"}</button></div>}
      <p className="status"><span/> Estado: {status} {countdown>0&&<strong>{countdown}</strong>}</p>{status==="Grabando..."&&<div className="level"><i style={{width:`${level*100}%`}}/></div>}{error&&<p className="error">{error}</p>}
    </section>
    {recording&&spectrum?<>
      <section className="card chartCard"><div className="sectionTitle"><div><span>01 — DOMINIO TEMPORAL</span><h2>Señal de voz en el dominio del tiempo</h2></div></div><SignalChart x={timeX} y={recording.samples} xLabel="Tiempo [s]" yLabel="Amplitud" color="#137c8b"/><p className="explanation">La gráfica muestra cómo cambia la amplitud de la señal de voz con respecto al tiempo.</p></section>
      <section className="card chartCard"><div className="sectionTitle"><div><span>02 — DOMINIO FRECUENCIAL</span><h2>Espectro de frecuencias de la voz</h2></div><label>Rango de frecuencia<select value={range} onChange={e=>setRange(Number(e.target.value))}><option value={1000}>0 – 1000 Hz</option><option value={2000}>0 – 2000 Hz</option><option value={4000}>0 – 4000 Hz</option><option value={Infinity}>Completo</option></select></label></div><SignalChart x={frequencyX} y={frequencyY} xLabel="Frecuencia [Hz]" yLabel="Magnitud" color="#e36f47"/><p className="explanation">La FFT transforma la señal del dominio del tiempo al dominio de la frecuencia y permite observar qué componentes están presentes en la voz.</p></section>
      <section className="card info"><div><span>Frecuencia de muestreo</span><strong>{recording.sampleRate} Hz</strong></div><div><span>Duración</span><strong>{recording.duration.toFixed(2)} s</strong></div><div><span>Número de muestras</span><strong>{recording.samples.length.toLocaleString("es")}</strong></div><div><span>FFT utilizada</span><strong>{spectrum.fftSize} muestras</strong></div><div className="accent"><span>Frecuencia dominante</span><strong>{spectrum.dominantFrequency.toFixed(2)} Hz</strong></div><div><span>Magnitud dominante</span><strong>{spectrum.dominantMagnitude.toFixed(3)}</strong></div></section>
      <a className="download" href={recording.wavUrl} download="grabacion.wav">Descargar grabación WAV</a>
    </>:<section className="empty card"><div>∿</div><h2>Tu análisis aparecerá aquí</h2><p>Permite el micrófono y realiza una grabación para visualizar la señal.</p></section>}
  </main>;
}
