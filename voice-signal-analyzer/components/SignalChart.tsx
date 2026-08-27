"use client";
import { useEffect, useRef } from "react";

export default function SignalChart({x,y,xLabel,yLabel,color}:{x:ArrayLike<number>;y:ArrayLike<number>;xLabel:string;yLabel:string;color:string}) {
  const ref=useRef<HTMLCanvasElement>(null);
  useEffect(()=>{
    const canvas=ref.current,ctx=canvas?.getContext("2d"); if(!canvas||!ctx||!x.length||!y.length)return;
    const ratio=window.devicePixelRatio||1,w=canvas.clientWidth,h=canvas.clientHeight;
    canvas.width=w*ratio;canvas.height=h*ratio;ctx.scale(ratio,ratio);ctx.clearRect(0,0,w,h);
    const left=58,right=18,top=18,bottom=42,pw=w-left-right,ph=h-top-bottom;
    let min=Infinity,max=-Infinity;for(let i=0;i<y.length;i++){min=Math.min(min,y[i]);max=Math.max(max,y[i]);}
    if(min===max){min-=1;max+=1;} ctx.font="12px system-ui";
    for(let i=0;i<=4;i++){const py=top+ph*i/4;ctx.strokeStyle="#dce4e8";ctx.beginPath();ctx.moveTo(left,py);ctx.lineTo(w-right,py);ctx.stroke();ctx.fillStyle="#64747d";ctx.fillText((max-(max-min)*i/4).toFixed(2),5,py+4);}
    ctx.strokeStyle=color;ctx.lineWidth=1.5;ctx.beginPath();const step=Math.max(1,Math.floor(y.length/pw));
    for(let i=0;i<y.length;i+=step){const px=left+i/(y.length-1)*pw,py=top+(max-y[i])/(max-min)*ph;i===0?ctx.moveTo(px,py):ctx.lineTo(px,py);}ctx.stroke();
    ctx.fillStyle="#43545c";ctx.textAlign="center";ctx.fillText(xLabel,left+pw/2,h-8);ctx.fillText(Number(x[0]).toFixed(0),left,h-25);ctx.fillText(Number(x[x.length-1]).toFixed(1),w-right,h-25);
    ctx.save();ctx.translate(13,top+ph/2);ctx.rotate(-Math.PI/2);ctx.fillText(yLabel,0,0);ctx.restore();
  },[x,y,xLabel,yLabel,color]);
  return <canvas ref={ref} className="chart" aria-label={`${yLabel} respecto a ${xLabel}`}/>;
}
