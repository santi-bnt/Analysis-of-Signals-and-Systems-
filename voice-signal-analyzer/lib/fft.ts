export type Spectrum = { frequencies:number[]; magnitudes:number[]; fftSize:number; dominantFrequency:number; dominantMagnitude:number };

function fft(real: number[], imaginary: number[]) {
  const n = real.length;
  for (let i=1,j=0;i<n;i++) {
    let bit=n>>1; for (;j&bit;bit>>=1) j^=bit; j^=bit;
    if(i<j){[real[i],real[j]]=[real[j],real[i]];[imaginary[i],imaginary[j]]=[imaginary[j],imaginary[i]];}
  }
  for(let length=2;length<=n;length<<=1){
    const angle=-2*Math.PI/length;
    for(let start=0;start<n;start+=length) for(let j=0;j<length/2;j++){
      const cos=Math.cos(angle*j),sin=Math.sin(angle*j),even=start+j,odd=even+length/2;
      const r=real[odd]*cos-imaginary[odd]*sin, im=real[odd]*sin+imaginary[odd]*cos;
      real[odd]=real[even]-r; imaginary[odd]=imaginary[even]-im; real[even]+=r; imaginary[even]+=im;
    }
  }
}

export function calculateSpectrum(samples: Float32Array, sampleRate: number): Spectrum {
  const fftSize=Math.min(16384,2**Math.floor(Math.log2(samples.length)));
  const start=Math.floor((samples.length-fftSize)/2);
  const selected=Array.from(samples.slice(start,start+fftSize));
  const mean=selected.reduce((sum,value)=>sum+value,0)/fftSize;
  const real=new Array<number>(fftSize),imaginary=new Array<number>(fftSize).fill(0);
  let windowSum=0;
  for(let i=0;i<fftSize;i++){
    // La ventana Hann reduce la fuga espectral (spectral leakage).
    const window=0.5*(1-Math.cos(2*Math.PI*i/(fftSize-1)));
    real[i]=(selected[i]-mean)*window; windowSum+=window;
  }
  fft(real,imaginary);
  const frequencies:number[]=[],magnitudes:number[]=[];
  let dominantFrequency=0,dominantMagnitude=0;
  for(let k=0;k<=fftSize/2;k++){
    const frequency=k*sampleRate/fftSize;
    const magnitude=Math.hypot(real[k],imaginary[k])/windowSum*(k===0||k===fftSize/2?1:2);
    frequencies.push(frequency); magnitudes.push(magnitude);
    if(frequency>=50&&magnitude>dominantMagnitude){dominantFrequency=frequency;dominantMagnitude=magnitude;}
  }
  return {frequencies,magnitudes,fftSize,dominantFrequency,dominantMagnitude};
}
