clear; clc; close all;

wind_inp_file="../../post_process_wind_field/effective_wind_speed/meanDiskWind.mat";
ocp_wind_out="wind_data.txt";

dt_wind=0.1;

%% import wind file
load(wind_inp_file);
effective_wind_speed=WF_mean_tms;


%% interpolate and filter the wind speed

time=[0:dt_wind:effective_wind_speed.Time(end)];

speed=pchip( effective_wind_speed.Time, effective_wind_speed.Data(:), time);

speed= smoothdata(speed,'gaussian',40);


%% write output file

time=time';
speed=speed';

system('rm ' + ocp_wind_out);
fid = fopen(ocp_wind_out,'wt');
fprintf(fid, 'time speed\n');
fclose(fid);
dlmwrite(ocp_wind_out,[time,speed],'precision','%.12g','Delimiter',' ','-append')


figure
plot(effective_wind_speed,'DisplayName','Effective wind speed')
hold on
plot(time,speed,'DisplayName','Effective wind speed smoothed')
legend
