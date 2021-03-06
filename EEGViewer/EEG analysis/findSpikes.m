function [spikes] = findSpikes(data, Fs, threshold)

win_smooth = 20; %[ms]
win_spike = 200; %[ms]

% threshold for amplitude specified as number of SD
% threshold(1) = threshold(1)*std(data);

% if not upper limit to spike amplitude is specified
if length(threshold)==2
    threshold(3) = Inf;
end

win_spike_samples = round(win_spike*10^-3*Fs/2); % actually is a half window;
dVdt = movmean((diff(data))*Fs, round(win_smooth*10.^-3*Fs));
i_spike = 0;
spikes = [];
i=2*win_spike_samples+1;
while i<=length(data)-win_spike_samples-1
    if abs(data(i))>threshold(1)
        
        % find maximal point of spike (look half a window ahead) ant i to
        % it
        [~, i_max] = max(data(i:i+win_spike_samples));
        i = i+ i_max;
        
        bFound_beg = false;
        % find beginning of spike
        [pks, locs] = findpeaks_native(abs(dVdt(i-win_spike_samples:i)));
        if ~isempty(pks)
            for i_p=1:length(pks)
                if pks(i_p)>threshold(2) && abs(data(i-win_spike_samples+locs(i_p)))<threshold(1)/2
                    i_beg = i-win_spike_samples+locs(i_p);
                    bFound_beg = true;
                end
            end
        end

        bFound_end = false;
        % find end of spike
        [pks, locs] = findpeaks_native(abs(dVdt(i:i+win_spike_samples)));
        if ~isempty(pks)
            for i_p=1:length(pks)
                if pks(i_p)>threshold(2) && abs(data(i+locs(i_p)))<threshold(1)/2
                    i_end= i+locs(i_p);
                    bFound_end = true;
                end
            end
        end 

        % check if the shape is one of a spike (only one zero crossing of
        % the derivative)    
%         nZCross = 0;
%         if bFound_beg && bFound_end
%             for iz = i_beg+1:i_end-1
%                 if dVdt(iz)*dVdt(iz+1)<=0
%                     nZCross = nZCross+1;
%                 end
%             end
%         end

        if bFound_beg && bFound_end %&& nZCross==1
            duration = (i_end-i_beg)/Fs*1000; %[ms]
            if duration>25 && duration<150
               [amp, i_max] = max(abs(data(i_beg:i_end)));
               if amp < threshold(3)
                   i_spike = i_spike+1;
                   spikes(i_spike).amp = amp;
                   spikes(i_spike).data = data(i_beg+i_max-win_spike_samples:min(i_beg+i_max+win_spike_samples, length(data)));
                   spikes(i_spike).i_beg = i_beg;% i_beg+i_max-win_spike_samples;
                   spikes(i_spike).i_end = i_end;% i_beg+i_max+win_spike_samples;
               end
            end  
            % DEBUG
%             figure
%             subplot(2,1,1)
%             hold on;
%             plot(data(i_beg+i_max-win_spike_samples:min(i_beg+i_max+win_spike_samples, length(data))));
%             yl = ylim;
%             plot((win_spike_samples-i_max)*ones(2,1), [-100 100]);
%             plot((win_spike_samples-i_max+(i_end-i_beg))*ones(2,1), [-100 100]);
%             ylim(yl)
%             subplot(2,1,2)
%             plot(dVdt(i_beg+i_max-win_spike_samples:min(i_beg+i_max+win_spike_samples, length(dVdt))));
        i=i+win_spike_samples;
        end
    else
       i=i+1; 
    end
end


end