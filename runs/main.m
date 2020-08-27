% Please run the script "pre_TL.jl" first. 

addpath('..\data')
addpath('..\src')

%% input
data_filename = 'Flt1003-train.h5';
output_line_number = 1003.10; % The line number of data to be filtered


%% run
tic
[tt, y_filtered, y_real] = func_predict(data_filename,output_line_number);
% y_filtered is the filtered output
% y_real is SGL Mag 1
toc
fprintf('ensemble rmse on %f = %f\n',output_line_number,sqrt(mean((y_filtered - y_real).^2)))

%% plot
figure()
plot(tt, y_real,'b')
hold on
plot(tt, y_filtered,'r')
legend('SGL Mag 1','predicted')
xlabel('Time [s]')
ylabel('Magnetic Field [nT]')
set(gcf,'color','white')
hold off

figure()
plot(tt, y_filtered - y_real,'r')
hold on
plot(tt, zeros(length(y_real),1),'b--')
xlabel('Time [s]')
ylabel('Absolute Error [nT]')
set(gcf,'color','white')
hold off



