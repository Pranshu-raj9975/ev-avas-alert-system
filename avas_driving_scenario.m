clc
clear
close all

%% LOAD EXTERNAL AVAS SOUND
[soundData,fs_file] = audioread('ev_motor.wav');

soundData = mean(soundData,2);             
soundData = soundData / max(abs(soundData)); 

%% Simulation parameters
dt = 0.03;
T  = 18;
t  = 0:dt:T;

fs = 44100;
soundIndex = 1;

%% Environment
figure('Color','w')
axis equal
xlim([0 200])
ylim([-12 12])
hold on

%% ROAD
rectangle('Position',[0 -5 200 10],'FaceColor',[0.2 0.2 0.2])

plot([0 200],[0 0],'w--','LineWidth',2)
plot([0 200],[3 3],'y--')
plot([0 200],[-3 -3],'y--')

%% SIDEWALKS
rectangle('Position',[0 5 200 3],'FaceColor',[0.6 0.6 0.6])
rectangle('Position',[0 -8 200 3],'FaceColor',[0.6 0.6 0.6])

title('Smart City AVAS Simulation')

%% CROSSWALK
crosswalkX = 80;

for i = -4:1:4
    rectangle('Position',[crosswalkX+i -5 0.4 10],'FaceColor','w')
end

%% TRAFFIC LIGHT
lightX = crosswalkX - 5;
trafficLight = scatter(lightX,8,200,'g','filled');

%% STATIC PEDESTRIANS
pedStatic = [30 7;
             150 -7];

scatter(pedStatic(:,1),pedStatic(:,2),150,'r','filled')

%% CROWD
crowd = [110 7;
         112 7.5;
         114 6.8;
         116 7.3;
         118 6.7];

scatter(crowd(:,1),crowd(:,2),160,'k','filled')

%% CROSSING PEDESTRIAN
pedX = crosswalkX;
pedY = 8;
pedCross = scatter(pedX,pedY,200,'m','filled');

%% ONCOMING VEHICLE
car2X = 180;
car2 = rectangle('Position',[car2X 2 3 1.5],'FaceColor','y');

%% EGO EV
carX = 0;
carY = -1;

egoCar = rectangle('Position',[carX carY 3 1.5],'FaceColor','b');

%% VEHICLE STATE
speed = 0;

%% AUDIO OUTPUT
deviceWriter = audioDeviceWriter( ...
    'SampleRate',fs, ...
    'ChannelMappingSource','Property', ...
    'ChannelMapping',[1 2]);

%% SIMULATION LOOP
for i = 1:length(t)

    %% TRAFFIC LIGHT
    if t(i) > 6 && t(i) < 10
        set(trafficLight,'CData',[1 0 0])
        lightState = "RED";
    else
        set(trafficLight,'CData',[0 1 0])
        lightState = "GREEN";
    end

    %% CROSSING PEDESTRIAN
    if t(i) > 6 && t(i) < 10
        pedY = pedY - 0.08;
    end

    set(pedCross,'XData',pedX,'YData',pedY)

    %% DISTANCES
    pedAll = [pedStatic; crowd; pedX pedY];

    distPed = min(vecnorm(pedAll - [carX carY],2,2));
    distLight = abs(carX - crosswalkX);

    %% VEHICLE CONTROL
    if lightState == "RED" && distLight < 20
        throttle = 0.1;
    elseif distPed < 10
        throttle = 0.2;
    elseif t(i) < 5
        throttle = 0.4;
    elseif t(i) < 10
        throttle = 0.9;
    else
        throttle = 0.5;
    end

    acc = 3*throttle;

    speed = max(speed + acc*dt,0);
    carX = carX + speed*dt;

    set(egoCar,'Position',[carX carY 3 1.5])

    %% OTHER VEHICLE
    car2X = car2X - 0.6;
    set(car2,'Position',[car2X 2 3 1.5])

    distVeh = abs(carX - car2X);

    dist = min([distPed distVeh]);

    %% ADAPTIVE AVAS VOLUME
    if dist < 6
        volume = 1.6;
    elseif dist < 12
        volume = 1;
    else
        volume = 0.5;
    end

    %% AUDIO FRAME
    samples = round(fs*dt);
    frame = zeros(samples,2);

    for k = 1:samples

        soundIndex = soundIndex + 1;

        if soundIndex > length(soundData)
            soundIndex = 1;
        end

        baseSample = soundData(soundIndex);

        %% directional sound
        pedDir = pedAll(:,1) - carX;

        if mean(pedDir) > 0
            leftGain = 0.4;
            rightGain = 0.8;
        else
            leftGain = 0.8;
            rightGain = 0.4;
        end

        frame(k,1) = volume * baseSample * leftGain;
        frame(k,2) = volume * baseSample * rightGain;

    end

    deviceWriter(frame)

    drawnow
    pause(0.002)

end

release(deviceWriter)