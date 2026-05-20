clc
clear
close all

%% PARAMETERS
fs = 44100;
dt = 0.05;
T  = 10;

t = 0:dt:T;

c = 343;          
baseFreq = 150;

speed = 0;
carX = -40;       
pedX = 0;

%% AUDIO
player = audioDeviceWriter('SampleRate',fs);

%% FIGURE
figure('Color','w')

subplot(2,1,1)
title('Vehicle Position')
xlabel('Time')
ylabel('Position')
hold on

subplot(2,1,2)
title('Observed Pitch (Doppler)')
xlabel('Time')
ylabel('Frequency (Hz)')
hold on

%% SIMULATION
for i = 1:length(t)

    acc = 2;
    speed = speed + acc*dt;

    carX = carX + speed*dt;

    direction = sign(pedX - carX);
    v_rel = direction * speed;

   
    freq = baseFreq * (c/(c - v_rel));

    
    samples = round(fs*dt);
    ts = (0:samples-1)/fs;

    tone = ...
        sin(2*pi*freq*ts) + ...
        0.5*sin(2*pi*2*freq*ts) + ...
        0.3*sin(2*pi*3*freq*ts);

    tone = tone';

    tone = tone/max(abs(tone)+0.001);

    player(tone)

    
    subplot(2,1,1)
    plot(t(i),carX,'b.')

    subplot(2,1,2)
    plot(t(i),freq,'r.')

    pause(dt)

end

release(player)
figure
spectrogram(tone,512,256,512,fs,'yaxis')
title('EV Sound Spectrogram Showing Doppler Shift')