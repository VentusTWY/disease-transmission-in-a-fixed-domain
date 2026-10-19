function [snapX, snapY, snapPop, snapT] = simulate_core(n, seed)
%Vectorised, headless version of the simulation loop in Main_DiseaseSim.m.
%Same rules (domain, speeds, 2-unit infection radius, 50%/30% transmission,
%2-day incubation, recovery 5 days after infection, boundary bouncing as in
%boundarycheck.m), recording a snapshot every 10 simulated minutes.
%Used by RecordVideo.m to render the demo video in MATLAB or GNU Octave.
rand('twister', seed);

Pos=1000*rand(n,2);
xpos=Pos(:,1);
ypos=Pos(:,2);
angle=rand(n,1)*2*pi;
speed=0.1*rand(n,1)+0.1;
u=speed.*cos(angle);
v=speed.*sin(angle);

%0- healthy 1- asymptomatic 2- infected 3- recovered
pop=zeros(n,1);
nfirst=randi(n);
pop(nfirst)=2;
InfStep=inf(n,1); RecStep=inf(n,1);
RecStep(nfirst)=3*8640;

%boundarycheck.m angle ranges for left, right, bottom, top walls
lo=[-89 91 1 181]; hi=[89 269 179 359];

dt=10;
time_total=60*60*24*10/dt;
nsnap=floor(time_total/60)+1;
snapX=zeros(n,nsnap); snapY=snapX; snapPop=snapX; snapT=zeros(1,nsnap);
s=0;

for t=0:time_total
    normpop=find(pop==0);
    asympop=find(pop==1);
    infpop=find(pop==2);

    if mod(t,60)==0
        s=s+1;
        snapX(:,s)=xpos; snapY(:,s)=ypos; snapPop(:,s)=pop; snapT(s)=t*dt;
    end

    %Boundary check (vectorised boundarycheck.m)
    [mindist,idx]=min([xpos,1000-xpos,ypos,1000-ypos],[],2);
    b=find(mindist<=2);
    if ~isempty(b)
        theta=lo(idx(b))'+floor(rand(numel(b),1).*(hi(idx(b))-lo(idx(b))+1)');
        u(b)=speed(b).*cosd(theta);
        v(b)=speed(b).*sind(theta);
    end
    xpos=xpos+dt*u;
    ypos=ypos+dt*v;

    %Transmission: each sick contact 50%, each asymptomatic contact 30%
    srcs={infpop,0.5; asympop,0.3};
    for q=1:2
        S=srcs{q,1}; p=srcs{q,2};
        if isempty(S) || isempty(normpop), continue, end
        D=sqrt((xpos(normpop)-xpos(S)').^2+(ypos(normpop)-ypos(S)').^2);
        hits=sum(D<=2,2);
        for k=find(hits>0)'
            j=normpop(k);
            if pop(j)==0 && any(rand(hits(k),1)<=p)
                InfStep(j)=t+2*8640;
                RecStep(j)=t+5*8640;
                pop(j)=1;
            end
        end
    end

    pop(infpop(RecStep(infpop)==t))=3;
    pop(asympop(InfStep(asympop)==t))=2;
end
end
