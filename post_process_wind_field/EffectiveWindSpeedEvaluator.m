clear; clc; close all;


PLOT=false;
MOVIE=false;

inp_fold='wind_data/';
filename='TS_wind';
out_folder='effective_wind_speed/';


% set the disc radius
disc_radius=63; %[m] NREL 5MW

[velocity, y, z, nz, ny, dz, dy, dt, zHub, z1, SummVars]=readBLgrid([inp_fold,filename]);


%%
WindFileStruct.WF=permute(velocity, [1, 4, 3, 2]);
WindFileStruct.WFtower=0;
WindFileStruct.Nz=ny;
WindFileStruct.Ny=ny;
WindFileStruct.N=size(velocity,1);
WindFileStruct.dz=dz;
WindFileStruct.dy=dy;
WindFileStruct.dt=dt;
WindFileStruct.U0=SummVars(3);
WindFileStruct.HubHt=zHub;
WindFileStruct.Zbottom=z1;
WindFileStruct.Y=meshgrid(y);
WindFileStruct.Z=meshgrid(z);
WindFileStruct.T=[0:WindFileStruct.dt:(WindFileStruct.N-1)*WindFileStruct.dt];



%% mean wind velocity
resampling_dT=0.1;


component=1;
u_wind_field=squeeze(WindFileStruct.WF(:,:,:,component));

for n=1:numel(WindFileStruct.T)

    %build a linear wind speed interpolator
    f_interp = @(yy,zz) interp2(y,z,squeeze(WindFileStruct.WF(n,:,:,component)),yy,zz,'linear');

    %integral on the rotor disc
    %polar_coordinates
    polarfun = @(theta,r) f_interp(r.*cos(theta), r.*sin(theta)+WindFileStruct.HubHt).*r;
    %Integrate over the region bounded by 0≤θ≤π/2 and 0≤r≤rmax
    WF_mean(n)=integral2(polarfun, 0,2*pi, 0,disc_radius,'AbsTol',1e-2,'RelTol',1e-2)/(pi*disc_radius^2); %integro sul disco e divido per la sua area

end




%% write output files


%write Xmean timeseries
tms=timeseries(WF_mean,WindFileStruct.T);
WF_mean_tms=resample(tms,[0:resampling_dT:WindFileStruct.T(end)]);
WF_mean_tms.Name='spatial average x-comp wind';

WindFileStruct.WF_mean=WF_mean;

% write .wnd file for FAST spatial average
fileID = fopen([out_folder,filename,'_Xmean.wnd'],'w');
fprintf(fileID,'! Wind file for sheared %f m/s wind with 0 degree direction.\n',mean(squeeze(WF_mean_tms.Data)));
fprintf(fileID,'! Time	Wind	Wind	Vert.	Horiz.	Vert.	LinV	Gust.\n');
fprintf(fileID,'!			Speed	Dir	Speed	Shear		Shear	Shear	Speed\n');
fprintf(fileID,'\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n',[WF_mean_tms.Time,squeeze(WF_mean_tms.Data),zeros(numel(WF_mean_tms.Time),6)]');
fclose(fileID);


save([out_folder,'meanDiskWind.mat'],'WF_mean_tms')


%% hub wind velocity

for n=1:numel(WindFileStruct.T)
    WF_hub(n)= interp2(y,z,squeeze(WindFileStruct.WF(n,:,:,component)),0,WindFileStruct.HubHt,'cubic');
end


tms=timeseries(WF_hub,WindFileStruct.T);
WF_hub_tms=resample(tms,[0:resampling_dT:WindFileStruct.T(end)]);
WF_hub_tms.Name='hub x-comp wind';

WindFileStruct.WF_hub=WF_hub;



% write .wnd file for FAST hub wind
% fileID = fopen([inp_bts_file,'my_hub.wnd'],'w');
% fprintf(fileID,'! Wind file for sheared %f m/s wind with 0 degree direction.\n',mean(squeeze(WF_hub_tms.Data)));
% fprintf(fileID,'! Time	Wind	Wind	Vert.	Horiz.	Vert.	LinV	Gust.\n');
% fprintf(fileID,'!			Speed	Dir	Speed	Shear		Shear	Shear	Speed\n');
% fprintf(fileID,'\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n',[WF_hub_tms.Time,squeeze(WF_hub_tms.Data),zeros(numel(WF_hub_tms.Time),6)]');
% fclose(fileID);


%% figure
if PLOT
    figure
    plot(WF_mean_tms)
    hold on;
    plot(WF_hub_tms)
    legend(WF_mean_tms.Name,WF_hub_tms.Name)
end


%% AVI MOVIE OF THE WIND FIELD

if MOVIE

    FIGURE=true;

    FastForward=1;
    for component=1:3 %x,y,z wind vel component
        max_v_w(component)=max(max(squeeze(max(squeeze(WindFileStruct.WF(:,:,:,component))))));
        min_v_w(component)=min(min(squeeze(min(squeeze(WindFileStruct.WF(:,:,:,component))))));
    end


    clabs={'u wind','v wind','w wind'};
    % %% Set up the AVI movie.
    writerObj = VideoWriter([out_folder,filename,'video.avi']); % Name it.
    writerObj.FrameRate = 1/WindFileStruct.dt; % How many frames per second.
    open(writerObj);

    if FIGURE
        figure(1111)
        set(gcf, 'Position',  [100, 100, 1024, 780])
    end

    for n=1:numel(WindFileStruct.T)
        disp(n)

        if FIGURE
            for component=1:3
                subplot(1,3,component)
                s=surf(squeeze(WindFileStruct.WF(n,:,:,component)),WindFileStruct.Y,WindFileStruct.Z',squeeze(WindFileStruct.WF(n,:,:,component)));
                s.EdgeColor = 'none';
                colormap(gca, 'jet');
                ylabel('Y')
                zlabel('Z')
                caxis([min_v_w(component) max_v_w(component)])
                hcb=colorbar;
                title(hcb,clabs{component});
                view(90,0)
            end
            drawnow;
        end

    %% AVI
        %if mod(i,4)==0, % Uncomment to take 1 screenshot of every 4 frames.
            frame = getframe(1111); % 'gcf' can handle if you zoom in to take a movie.
            writeVideo(writerObj, frame);
        %end


    end

    hold off;
    close(writerObj); % Saves the movie.

end
