
clear all
clc
close all

%% 1. System and Data Description & Upload
load('house.mat'); 
N = 1000; % Total number of samples

t = (0:N-1)' * 15; % Time in minutes

% Sample time Ts = 15 minutes
data = iddata(y, u, 15); 
data.InputName = 'Sun Light';
data.InputUnit = 'KLux';
data.OutputName = 'Room Temperature';
data.OutputUnit = 'C';

%% 2. Data Plotting
figure('Name', 'Raw Data: Input and Output');
subplot(2,1,1);
plot(t, y, 'b', 'LineWidth', 1.2);
title('Room Temperature over Time');
ylabel('Temperature [°C]');
grid on;

subplot(2,1,2);
plot(t, u, 'r', 'LineWidth', 1.2);
title('Sun Light over Time');
xlabel('Time [minutes]');
ylabel('Illuminance [KLux]');
grid on;

%% 3. Data Detrending
% Compute the means of the data and store them in mu.InputOffset and mu.OutputOffset
mu = getTrend(data,0);

% Perform the data detrend
data_d = detrend(data,mu);

%% 4. Model Structure Design

% M1: ARMAX (nA=1, nB=1, nC=1, nk=1)
M1 = armax(data_d, [1 1 1 1]);

% M2: ARMAX (nA=2, nB=2, nC=2, nk=1)
M2 = armax(data_d, [2 2 2 1]);

% M3: Output-Error (nB=2, nF=2, nk=1)
M3 = oe(data_d, [2 2 1]);

% M4: Box-Jenkins (nB=2, nC=2, nD=2, nF=2, nk=1)
M4 = bj(data_d, [2 2 2 2 1]);

%% 5. Validation Step: Residual Analysis

figure("Name","M1: ARMAX");
resid(M1,data_d,'corr');
figure("Name","M2: ARMAX");
resid(M2,data_d,'corr');
figure("Name","M3: OE");
resid(M3,data_d,'corr');
figure("Name","M4: BJ");
resid(M4,data_d,'corr');

%% 6. Zero-Pole Cancellation Analysis
figure('Name', 'Zero-Pole Map');
iopzmap(M1, M2, M3, M4);
legend

%% 7. Criteria with Complexity Terms
models = {M1, M2, M3, M4};

%Storing the indexes in an array
for i =1:1:4
    
    sure_index(i) = sure(models{i});
    aic_index(i) = aic(models{i});
    bic_index(i) = bic(models{i});

end

%% 8. Hold-Out Cross Validation
training_data = data_d(1:N/2);
validation_data = data_d(N/2+1:N);

M1_cv = armax(training_data,  [1 1 1 1]);
M2_cv = armax(training_data, [2 2 2 1]);
M3_cv = oe(training_data, [2 2 1]);
M4_cv = bj(training_data, [2 2 2 2 1]);

for h = 1:4
    
    figure("Name","Cross_Out Validation");
    opt = compareOptions('InitialCondition','z');
    compare(validation_data, M1_cv, M2_cv, M3_cv, M4_cv , h, opt);

end
