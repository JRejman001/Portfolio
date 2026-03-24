clear;
close all;
clc;
k = 0;

folder = 'JendnaKomorka';
if ~exist(folder, 'dir')
    mkdir(folder);
end

for n = 1:25
    run komj.m;
    data = load('DHM_21.mat');
    area(n) = data.cell_area;
    masa(n) = data.dry_mass;
    gestosc(n) = data.density;
end

time = 1:1:25;
figure;
plot(time, area);
xlabel('Czas [min]');
ylabel('Powierzchnia komórki µm^2');
title('Wykres zmieny powierzchni od czasu');
grid on;
fig = gcf; % Get the current figure handle
exportgraphics(fig, fullfile(folder, 'Wykres_1.png'), 'Resolution', 300);

figure;
plot(time, masa);
xlabel('Czas [min]');
ylabel('Sucha masa komorki [pg]');
ylim([30 50]);
title('Wykres zmieny suchej masy od czasu');
grid on;
fig = gcf; % Get the current figure handle
exportgraphics(fig, fullfile(folder, 'Wykres_2.png'), 'Resolution', 300);

figure;
plot(time, gestosc);
xlabel('Czas [min]');
ylabel('Gęstość suchej masy [pg/µm^2]');
title('Wykres zmieny wszystkich parametrów od czasu');
grid on;

fig = gcf; % Get the current figure handle
exportgraphics(fig, fullfile(folder, 'Wykres_3.png'), 'Resolution', 300);
