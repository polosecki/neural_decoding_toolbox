function nspikes=get_evoked_spikes(spike_times,ts,te)
nspikes=nan(size(ts));
    for i=1:length(ts)
        nspikes(i)=sum(spike_times>ts(i) & spike_times<te(i));
    end
    