function voz_usuarios_comentado
% Reconoce usuarios comparando la frecuencia dominante de su voz.

%% 1. CONFIGURACION
clc;
fs = 16000;
duracion = 2;
archivo = fullfile(fileparts(mfilename('fullpath')), 'usuarios_frecuencia.mat');

%% 2. CARGAR DATOS GUARDADOS
usuarios = struct('nombre', {}, 'frecuencia', {}, 'muestras', {}, ...
    'f', {}, 'magnitud', {}, 'fase', {});
ultima = struct();

if isfile(archivo)
    datos = load(archivo);

    % Solo aceptar datos que tengan el formato de esta version.
    if isfield(datos, 'usuarios') && isfield(datos.usuarios, 'f')
        usuarios = datos.usuarios;

        if isfield(usuarios, 'fecha')
            usuarios = rmfield(usuarios, 'fecha');
        end
    end

    if isfield(datos, 'ultimaGrabacion') && ...
            (isempty(fieldnames(datos.ultimaGrabacion)) || ...
            isfield(datos.ultimaGrabacion, 'f'))
        ultima = datos.ultimaGrabacion;

        if isfield(ultima, 'fecha')
            ultima = rmfield(ultima, 'fecha');
        end
    end
end

%% 3. MENU PRINCIPAL
while true
    fprintf(['\nRECONOCIMIENTO POR FRECUENCIA\n' ...
        '1. Registrar usuario\n' ...
        '2. Detectar usuario\n' ...
        '3. Ver grafica de un usuario\n' ...
        '4. Ver ultima grabacion\n' ...
        '5. Borrar usuario\n' ...
        '6. Salir\n\n']);

    switch input('Selecciona una opcion: ')
        case 1
            [usuarios, ultima] = registrar(usuarios, fs, duracion);
        case 2
            ultima = detectar(usuarios, fs, duracion);
        case 3
            mostrar(usuarios);
        case 4
            ver_ultima(ultima);
        case 5
            [usuarios, ultima] = borrar_usuario(usuarios, ultima);
        case 6
            ultimaGrabacion = ultima;
            save(archivo, 'usuarios', 'ultimaGrabacion');
            fprintf('Informacion guardada.\n');
            break;
        otherwise
            fprintf('Opcion no valida.\n');
    end

    ultimaGrabacion = ultima;
    save(archivo, 'usuarios', 'ultimaGrabacion');
end
end


%% FUNCION: REGISTRAR USUARIO
function [usuarios, ultima] = registrar(usuarios, fs, duracion)
nombre = strtrim(input('Nombre del usuario: ', 's'));
frecuencias = zeros(1, 3);
espectros = cell(1, 3); %se va a guardar frec, magnitud y fase 

%se entra al ciclo de las 3 grabaciones 
for k = 1:3
    fprintf('\nGrabacion %d de 3. Habla durante %d segundos...\n', k, duracion);
    [frecuenciasFFT, magnitud, fase] = ...
        grabar(fs, duracion, ['Registro - ' nombre], true); % el true te indica que se quieren mostrar las gráficas 
    frecuencias(k) = dominante(frecuenciasFFT, magnitud); %encontrar frec dominante
    espectros{k} = {frecuenciasFFT, magnitud, fase};
    fprintf('Frecuencia: %.2f Hz\n', frecuencias(k));
end

% La mediana evita que una medicion aislada cambie mucho el resultado.
frecuencia = median(frecuencias); %usamos la mediana para obtener una frecuencia dominante en la voz -> outlier 
[~, indice] = min(abs(frecuencias - frecuencia)); %se elige el más cercano a la media| ~ no nos interesa guardar el valor minimo 
espectroElegido = espectros{indice};
posicion = find(strcmpi({usuarios.nombre}, nombre), 1); %compara el nombre del usuario y si existe indica en qué posición del arreglo está
%strcmpi ignorar espacios y mayus/min 

%si no encuentra al usuario crea uno nuevo 
if isempty(posicion)
    posicion = numel(usuarios) + 1;
    usuarios(posicion) = struct('nombre', nombre, 'frecuencia', frecuencia, ...
        'muestras', frecuencia, 'f', espectroElegido{1}, ...
        'magnitud', espectroElegido{2}, 'fase', espectroElegido{3});
else
    %si ya existe el usuario lo busca y actualiza la posición del arreglo
    %en la que está 
    usuarios(posicion).muestras(end + 1) = frecuencia;
    usuarios(posicion).frecuencia = median(usuarios(posicion).muestras);
    usuarios(posicion).f = espectroElegido{1};
    usuarios(posicion).magnitud = espectroElegido{2};
    usuarios(posicion).fase = espectroElegido{3};
end
%guarda la info en la grabación más reciente 
ultima = crear_grabacion('Registro', nombre, frecuencia, espectroElegido);
fprintf('\nUsuario guardado: %s (%.2f Hz)\n', nombre, frecuencia);
end


%% FUNCION: DETECTAR USUARIO
function ultima = detectar(usuarios, fs, duracion)
ultima = struct();
if isempty(usuarios)
    fprintf('Primero registra un usuario.\n');
    return;
end

fprintf('\nHabla durante %d segundos...\n', duracion);
[frecuenciasFFT, magnitud, fase] = ...
    grabar(fs, duracion, 'Deteccion', false); %false hace que no se muestre la graf en ese momento 
frecuencia = dominante(frecuenciasFFT, magnitud); %toma la frecuancia dominante 
[diferencia, posicion] = min(abs([usuarios.frecuencia] - frecuencia)); %compara cual es el más cercano 
%se usa abs porque queremos distancia de la frecuancia dominante y la
%grabada 

if diferencia <= 30 %si la frecuencia guardada está a 30hz de la guardada, es coincidencia 
    nombre = usuarios(posicion).nombre;
    usuarioDetectado = usuarios(posicion);

    fprintf('Frecuencia detectada: %.2f Hz\n', frecuencia);
    fprintf('Usuario detectado: %s (%.2f Hz guardados)\n', ...
        nombre, usuarioDetectado.frecuencia);
else
    nombre = 'Desconocido';
    usuarioDetectado = [];

    fprintf('Frecuencia detectada: %.2f Hz\n', frecuencia);
    fprintf('Usuario desconocido.\n');
end

graficar_deteccion(frecuenciasFFT, magnitud, fase, ...
    frecuencia, usuarioDetectado);

ultima = crear_grabacion('Deteccion', nombre, frecuencia, ...
    {frecuenciasFFT, magnitud, fase});
end


%% FUNCION: MOSTRAR USUARIOS
function mostrar(usuarios)
if isempty(usuarios)
    fprintf('No hay usuarios registrados.\n');
    return;
end

fprintf('\nUSUARIOS REGISTRADOS\n');

for k = 1:numel(usuarios)
    fprintf('%d. %s | %.2f Hz\n', ...
        k, usuarios(k).nombre, usuarios(k).frecuencia);
end

seleccion = input('\nSelecciona un usuario: ');

if seleccion >= 1 && seleccion <= numel(usuarios)
    usuario = usuarios(seleccion);
    graficar(usuario.f, usuario.magnitud, usuario.fase, ...
        usuario.frecuencia, ['Usuario - ' usuario.nombre]);
else
    fprintf('Usuario no valido.\n');
end
end


%% FUNCION: BORRAR USUARIO
function [usuarios, ultima] = borrar_usuario(usuarios, ultima)
if isempty(usuarios)
    fprintf('No hay usuarios registrados.\n');
    return;
end

fprintf('\nUSUARIOS REGISTRADOS\n');

for k = 1:numel(usuarios)
    fprintf('%d. %s\n', k, usuarios(k).nombre);
end

seleccion = input('\nSelecciona el usuario que quieres borrar: ');

if seleccion < 1 || seleccion > numel(usuarios)
    fprintf('Usuario no valido.\n');
    return;
end

nombre = usuarios(seleccion).nombre;
respuesta = input(['Borrar a ' nombre '? (s/n): '], 's');

if strcmpi(respuesta, 's')
    usuarios(seleccion) = [];

    if ~isempty(fieldnames(ultima)) && strcmpi(ultima.usuario, nombre)
        ultima = struct();
    end

    fprintf('Usuario borrado: %s\n', nombre);
else
    fprintf('No se borro el usuario.\n');
end
end


%% FUNCION: VER ULTIMA GRABACION
function ver_ultima(ultima)
if ~isempty(fieldnames(ultima))
    graficar(ultima.f, ultima.magnitud, ultima.fase, ...
        ultima.frecuencia, ['Ultima - ' ultima.usuario]);
else
    fprintf('No hay una grabacion reciente.\n');
end
end


%% FUNCION: GRABAR VOZ Y CALCULAR FFT
function [frecuenciasFFT, magnitud, fase] = ...
    grabar(fs, duracion, titulo, mostrarGrafica)
grabadora = audiorecorder(fs, 16, 1);
recordblocking(grabadora, duracion); %espera que termine la grabacion antes de continuar
audio = getaudiodata(grabadora, 'double');

% Quitar el promedio y aplicar una ventana antes de la FFT.
audio = audio(:) - mean(audio); %se convierte de fila a columna y centra la signal en 0 
numeroMuestras = length(audio);
ventana = 0.5 - 0.5*cos(2*pi*(0:numeroMuestras-1)'/(numeroMuestras-1)); %ventana de Hann 
nfft = 2^nextpow2(numeroMuestras);
fftAudio = fft(audio .* ventana, nfft); %transformacion fundamental, convierte el tiempo grabado en frecuencia 
fftAudio = fftAudio(1:nfft/2 + 1); %nos quedamos con la parte real 
frecuenciasFFT = (0:nfft/2)' * fs/nfft;
magnitud = abs(fftAudio); %calcula la magnitud

%la ventana de hamm filtra la
%signal y toma lo más importante de la grabación 
%.* multiplicació por elemento 

if max(magnitud) > 0
    magnitud = magnitud / max(magnitud);
end

fase = angle(fftAudio); %obtiene el angulo del num complejo 

if mostrarGrafica
    tiempo = (0:numeroMuestras-1)'/fs;
    figure('Name', titulo, 'NumberTitle', 'off', 'Color', 'white');

    subplot(3,1,1);
    plot(tiempo, audio);
    grid on;
    title('Voz');
    xlabel('Tiempo [s]');

    subplot(3,1,2);
    plot(frecuenciasFFT, magnitud);
    grid on;
    xlim([0 500]);
    title('Magnitud FFT');

    subplot(3,1,3);
    plot(frecuenciasFFT, fase);
    grid on;
    xlim([0 500]);
    title('Fase FFT');
    xlabel('Frecuencia [Hz]');
end
end


%% FUNCION: OBTENER FRECUENCIA DOMINANTE
function frecuencia = dominante(frecuenciasFFT, magnitud)
% Solo se revisa el rango aproximado de la voz humana.
zona = frecuenciasFFT >= 70 & frecuenciasFFT <= 400;
[~, indice] = max(magnitud(zona));
valores = frecuenciasFFT(zona);
frecuencia = valores(indice);
end


%% FUNCION: GUARDAR DATOS DE UNA GRABACION
function grabacion = crear_grabacion(tipo, usuario, frecuencia, espectro)
grabacion = struct('tipo', tipo, 'usuario', usuario, ...
    'frecuencia', frecuencia, 'f', espectro{1}, ...
    'magnitud', espectro{2}, 'fase', espectro{3});
end


%% FUNCION: MOSTRAR UN ESPECTRO GUARDADO
function graficar(frecuenciasFFT, magnitud, fase, frecuencia, titulo)
if isempty(frecuenciasFFT)
    fprintf('No hay datos de FFT guardados.\n');
    return;
end

figure('Name', titulo, 'NumberTitle', 'off', 'Color', 'white');

subplot(2,1,1);
plot(frecuenciasFFT, magnitud);
grid on;
xlim([0 500]);
xline(frecuencia, '--', sprintf('%.2f Hz', frecuencia));
title('Magnitud FFT');

subplot(2,1,2);
plot(frecuenciasFFT, fase);
grid on;
xlim([0 500]);
title('Fase FFT');
xlabel('Frecuencia [Hz]');
end


%% FUNCION: COMPARAR LA DETECCION
function graficar_deteccion(f, magnitud, fase, frecuencia, usuario)
% Si no hubo coincidencia, solamente se muestra la grabacion actual.
if isempty(usuario)
    titulo = 'Deteccion - Desconocido';
else
    titulo = ['Deteccion - ' usuario.nombre];
end

figure('Name', titulo, 'NumberTitle', 'off', 'Color', 'white');

subplot(2,1,1);
plot(f, magnitud, 'LineWidth', 1.2, 'DisplayName', 'Grabacion actual');
hold on;
xline(frecuencia, '--', sprintf('Detectada: %.2f Hz', frecuencia), ...
    'HandleVisibility', 'off');

if ~isempty(usuario)
    plot(usuario.f, usuario.magnitud, 'LineWidth', 1.2, ...
        'DisplayName', ['Guardada: ' usuario.nombre]);
    xline(usuario.frecuencia, '--', ...
        sprintf('Guardada: %.2f Hz', usuario.frecuencia), ...
        'HandleVisibility', 'off');
end

hold off;
grid on;
xlim([0 500]);
title('Comparacion de magnitud');
legend('show');

subplot(2,1,2);
plot(f, fase, 'LineWidth', 1, 'DisplayName', 'Grabacion actual');
hold on;

if ~isempty(usuario)
    plot(usuario.f, usuario.fase, 'LineWidth', 1, ...
        'DisplayName', ['Guardada: ' usuario.nombre]);
end

hold off;
grid on;
xlim([0 500]);
title('Comparacion de fase');
xlabel('Frecuencia [Hz]');
legend('show');
end