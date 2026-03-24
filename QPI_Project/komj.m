%% 0. Ścieżka do Detrend2D
addpath('C:\Users\julia\OneDrive\Pulpit\Studia\Studia sem.5\IOFPK\Projekt'); % dostosuj do swojego katalogu

%% 1. Wybór pliku DHM
if n==1
addpath(pwd);   

data_path = "E:\z1SMJN\timelapse-2025-12-02T15-38";
tmp = dir(fullfile(data_path,'phase_ref370_*.tiff'));
files = {tmp.name};
nFrames = numel(files);

fprintf('Znaleziono %d klatek.\n', nFrames);
end
%% 2. Parametry układu
M = 21.3;             % powiększenie rzeczywiste
cam_pix = 2.74;       % [µm] piksel kamery
pixel_size = cam_pix/M; % [µm]

lambda = 0.632;       % [µm] długość fali
alpha  = 0.18;        % współczynnik suchej masy [pg/µm^3]

%% 3. Wczytanie obrazu i filtracja
phase = double(imread(fullfile(data_path,files{n}),2));
phase(isnan(phase)) = 0;

phase_det  = Detrend2D(phase);
phase_filt = medfilt2(phase_det,[3 3]);

%% 4. Jedna figura – wybór tła i ROI komórki
if (n == 1)
figure;
imagesc(phase_filt); axis image; colormap gray; colorbar;
title({'Najpierw zaznacz obszar tła (bez komórki)', ...
       'Następnie zatwierdź i zaznacz komórkę (ROI)'});

% wybór tła
h_bg = drawpolygon('LineWidth',1.5);
bg_mask = createMask(h_bg);

% obliczenie poziomu tła
background_phase = median(phase_filt(bg_mask));

% wybór ROI komórki
h_roi = drawpolygon('LineWidth',1.5);
roi_mask = createMask(h_roi);

close;
end
% korekta fazy
phase_corrected = phase_filt - background_phase;

%% 5. Obliczenie OPD
OPD = (lambda/(2*pi)) .*phase_corrected;

% OPD tylko w ROI
OPD_roi = OPD;
OPD_roi(~roi_mask) = 0;

% Przesunięcie OPD do dodatnich wartości
OPD_roi = abs(OPD_roi);

%% 6. Maskowanie faktycznej komórki
threshold = 0.3 * max(OPD_roi(:)); % 10% max w ROI
cell_mask = OPD_roi > threshold;

if sum(cell_mask(:)) == 0
    warning('Maska komórki jest pusta! Spróbuj zmniejszyć próg lub ROI.');
end

%% 7. Obliczenia parametrów komórki
if sum(cell_mask(:)) > 0
    cell_area = sum(cell_mask(:)) * pixel_size^2;  % [µm^2]
    mean_OPD  = mean(OPD_roi(cell_mask));          % [µm], zawsze >= 0
    dry_mass  = cell_area * mean_OPD / alpha;     % [pg]
    density   = dry_mass / cell_area;             % [pg/µm^2]
else
    cell_area = 0; dry_mass = NaN; mean_OPD = NaN; density = NaN;
end

%% 8. Wyniki
%{
fprintf('\n=== WYNIKI DLA WYBRANEJ KOMÓRKI ===\n');
fprintf('Plik: %s\n\n', file);
fprintf('Pole powierzchni : %.2f µm^2\n', cell_area);
fprintf('Sucha masa       : %.4f pg\n', dry_mass);
fprintf('Średnia OPD      : %.4f µm\n', mean_OPD);
fprintf('Gęstość masy     : %.4f pg/µm^2\n', density);
%}
%% 9. Podgląd końcowy
if mod(n,5)==0 || n==1
k = k + 1;
figure;
imagesc(phase_corrected); axis image; colorbar; hold on; caxis([-8 0]);
contour(bg_mask,[0.5 0.5],'b','LineWidth',1.5);   % tło
contour(roi_mask,[0.5 0.5],'y','LineWidth',1.5);  % ROI ręczne
contour(cell_mask,[0.5 0.5],'r','LineWidth',2);   % faktyczna komórka
title('Niebieski = tło, Żółty = ROI, Czerwony = faktyczna komórka');
fig = gcf; % Get the current figure handle
filename = fullfile(folder, sprintf('Obraz_%02d.png', k));
exportgraphics(fig, filename, 'Resolution', 300);
end
%% 10. Zapis wyników
save('DHM_21.mat', ...
     'cell_area','dry_mass','mean_OPD','density','threshold');

%fprintf('\nWyniki zapisane do DHM_single_cell_manual_bg.mat\n');
