clc; clear; close all;

%%  ŚCIEŻKI 
addpath(pwd);   

data_path = "E:\z1SMJN\timelapse-2025-12-02T15-38";
tmp = dir(fullfile(data_path,'phase_ref370_*.tiff'));
files = {tmp.name};
nFrames = numel(files);

fprintf('Znaleziono %d klatek.\n', nFrames);

%%  PARAMETRY 
M = 21.3;
cam_pix = 2.74;          % [µm]
pixel_size = cam_pix/M; % [µm]
lambda = 0.632;          % [µm]
alpha  = 0.18;

%%  WEKTORY 
dry_mass_total  = zeros(nFrames,1);   % [pg]
cell_area_total = zeros(nFrames,1);   % [µm^2]
mean_phase      = zeros(nFrames,1);

clf;

%% 
for t = 1:nFrames
    %% Wczytanie mapy fazy
    phase = double(imread(fullfile(data_path,files{t}),2));
    phase(isnan(phase)) = 0;

    %% Usunięcie tła
    phase_det = Detrend2D(phase);

    %% Segmentacja – Image Segmenter (graph cut)
    [mask, ~] = segmentImage(phase_det);
    mask = logical(mask);
    mask = imfill(mask,'holes');
    mask = bwareaopen(mask,200);
    %% OPD
    OPD = abs((lambda/(2*pi)) .* phase_det);
    OPD(~mask) = 0;

    %% Parametry ilościowe
    cell_area_total(t) = sum(mask(:)) * pixel_size^2;
    dry_mass_total(t)  = sum(OPD(mask)) * pixel_size^2 / alpha;
    mean_phase(t)      = mean(phase_det(mask));

    %% Podgląd
    if mod(t,5)==0 || t==1
        figure;
        imagesc(phase_det); axis image; colorbar; caxis([-8 0]);
        hold on;
        contour(mask,[0.5 0.5],'r','LineWidth',1.5);
        title(['Klatka ' num2str(t) ' / ' num2str(nFrames)]);
        drawnow;
      
    end
end

%% ANALIZA CZASOWA 
dry_mass_diff = dry_mass_total - dry_mass_total(1);
dry_mass_rel  = 100 * dry_mass_total / dry_mass_total(1) - 100;
time_min      = (0:nFrames-1)';
dry_mass_density = dry_mass_total./cell_area_total;

%%  WYKRESY
figure;
plot(time_min,dry_mass_total,'-o','LineWidth',1.5);
xlabel('Czas [min]');
ylabel('Sucha masa [pg]');
grid on;
title('Całkowita sucha masa (segmentacja Image Segmenter)');

figure;
plot(time_min,dry_mass_density,'-o','LineWidth',1.5);
xlabel('Czas [min]');
ylabel('Gęstość suchej masy [pg/µm^2]');
grid on;
title('Zmiana gęstości suchej masy');

figure;
plot(time_min,dry_mass_rel,'-o','LineWidth',1.5);
xlabel('Czas [min]');
ylabel('\Delta sucha masa [%]');
grid on;
title('Zmiana suchej masy względem pierwszej klatki');

%%  ZAPIS 
save('DHM_ImageSegmenter_dry_mass.mat', ...
    'time_min', ...
    'dry_mass_total', ...
    'dry_mass_diff', ...
    'dry_mass_rel', ...
    'cell_area_total', ...
    'mean_phase');

fprintf('\n=== ANALIZA ZAKOŃCZONA POPRAWNIE ===\n');
