function voz_usuarios
% Reconocimiento sencillo comparando la frecuencia dominante de la voz.

%% MENU PRINCIPAL
clc;
fs = 16000;
duracion = 2;
archivo = fullfile(fileparts(mfilename('fullpath')), 'usuarios_frecuencia.mat');

if isfile(archivo)
    datos = load(archivo, 'usuarios');
    usuarios = datos.usuarios;
    if isfield(usuarios, 'palabra')
        usuarios = rmfield(usuarios, 'palabra');
    end
else
    usuarios = struct('nombre', {}, 'frecuencia', {});
end

while true
    fprintf('\nRECONOCIMIENTO POR FRECUENCIA\n');
    fprintf('1. Registrar usuario\n');
    fprintf('2. Detectar usuario\n');
    fprintf('3. Mostrar usuarios\n');
    fprintf('4. Salir\n\n');
    opcion = input('Selecciona una opcion: ');

    switch opcion
        case 1
            usuarios = registrar_usuario(usuarios, fs, duracion);
            save(archivo, 'usuarios');

        case 2
            detectar_usuario(usuarios, fs, duracion);

        case 3
            if isempty(usuarios)
                fprintf('No hay usuarios registrados.\n');
            else
                for k = 1:numel(usuarios)
                    fprintf('%s | Frecuencia: %.2f Hz\n', ...
                        usuarios(k).nombre, usuarios(k).frecuencia);
                end
            end

        case 4
            fprintf('Programa terminado.\n');
            break;

        otherwise
            fprintf('Opcion no valida.\n');
    end
end
end


%% REGISTRAR USUARIO
function usuarios = registrar_usuario(usuarios, fs, duracion)
nombre = strtrim(input('Nombre del usuario: ', 's'));

frecuencias = zeros(1, 3);

for k = 1:3
    fprintf('\nGrabando frecuencia %d de 3...\n', k);
    audio = grabar_voz(fs, duracion);
    frecuencias(k) = calcular_frecuencia(audio, fs);
    fprintf('Frecuencia medida: %.2f Hz\n', frecuencias(k));
end

frecuenciaPromedio = mean(frecuencias);
nuevo = struct('nombre', nombre, 'frecuencia', frecuenciaPromedio);

posicion = find(strcmpi({usuarios.nombre}, nombre), 1);
if isempty(posicion)
    usuarios(end + 1) = nuevo;
else
    usuarios(posicion) = nuevo;
end

fprintf('\nFrecuencia guardada para %s: %.2f Hz\n', nombre, frecuenciaPromedio);
end


%% DETECTAR USUARIO
function detectar_usuario(usuarios, fs, duracion)
if isempty(usuarios)
    fprintf('Primero registra un usuario.\n');
    return;
end

fprintf('\nGrabando frecuencia de prueba...\n');
audio = grabar_voz(fs, duracion);
frecuenciaPrueba = calcular_frecuencia(audio, fs);
fprintf('Frecuencia de prueba: %.2f Hz\n', frecuenciaPrueba);

frecuenciasGuardadas = [usuarios.frecuencia];
diferencias = abs(frecuenciasGuardadas - frecuenciaPrueba);
[menorDiferencia, posicion] = min(diferencias);

% Una diferencia mayor de 25 Hz se considera una voz desconocida.
if menorDiferencia <= 25
    fprintf('\nUsuario detectado: %s\n', usuarios(posicion).nombre);
else
    fprintf('\nUsuario detectado: Desconocido\n');
end
fprintf('Diferencia: %.2f Hz\n', menorDiferencia);
end


%% GRABAR Y MOSTRAR LA SEÑAL
function audio = grabar_voz(fs, duracion)
grabadora = audiorecorder(fs, 16, 1);
figura = figure('Name', 'Señal de voz', ...
    'NumberTitle', 'off', 'Color', 'white');
ejes = axes(figura);
linea = plot(ejes, 0, 0, 'Color', [0.05 0.50 0.58]);
title(ejes, 'Señal de voz en tiempo real');
xlabel(ejes, 'Tiempo [s]');
ylabel(ejes, 'Amplitud');
xlim(ejes, [0 duracion]);
ylim(ejes, [-1 1]);
grid(ejes, 'on');

record(grabadora, duracion);
inicio = tic;

while toc(inicio) < duracion
    pause(0.05);
    parcial = getaudiodata(grabadora, 'double');
    if isgraphics(linea) && ~isempty(parcial)
        tiempo = (0:length(parcial) - 1) / fs;
        set(linea, 'XData', tiempo, 'YData', parcial);
        drawnow limitrate;
    end
end

stop(grabadora);
audio = getaudiodata(grabadora, 'double');
end


%% CALCULAR FRECUENCIA DOMINANTE CON FFT
function frecuenciaDominante = calcular_frecuencia(audio, fs)
audio = audio(:);
audio = audio - mean(audio);

% Conserva la parte donde realmente se hablo.
limite = 0.10 * max(abs(audio));
indicesVoz = find(abs(audio) >= limite);
if ~isempty(indicesVoz)
    audio = audio(indicesVoz(1):indicesVoz(end));
end

% Ventana Hann y FFT.
n = length(audio);
ventana = 0.5 - 0.5 * cos(2 * pi * (0:n - 1)' / (n - 1));
nfft = 2^nextpow2(n);
transformada = fft(audio .* ventana, nfft);
magnitud = abs(transformada(1:nfft / 2 + 1));
frecuencias = (0:nfft / 2)' * fs / nfft;

% Busca la frecuencia fundamental habitual de una voz humana.
zonaVoz = frecuencias >= 70 & frecuencias <= 400;
indices = find(zonaVoz);
[~, maximo] = max(magnitud(zonaVoz));
frecuenciaDominante = frecuencias(indices(maximo));
end
