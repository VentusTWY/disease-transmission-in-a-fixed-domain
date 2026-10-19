%Renders the disease transmission simulation to PNG frames (frames/)
%using the same three-panel dashboard as Main_DiseaseSim.m.
%Works in MATLAB and GNU Octave. Encode the frames afterwards, e.g.
%  ffmpeg -framerate 30 -i frames/f%04d.png -pix_fmt yuv420p demo.mp4
addpath('..');
n=100; seed=1; step=2; %one frame per 20 simulated minutes
[X,Y,P,T]=simulate_core(n,seed);

COrg=[1 11/17 0];
CGren=[0 0.85 0];
cols={CGren,COrg,[1 0 0],[0 0 1]};
names={'Healthy','Asymptomatic','Infected','Recovered'};
counts=zeros(4,size(P,2));
for c=0:3, counts(c+1,:)=sum(P==c,1); end
hrs=T/3600;

if ~exist('frames','dir'), mkdir('frames'); end
fig=figure('Visible','off','Position',[0 0 1280 720],'Color','w');

ax1=subplot(2,2,1); hold(ax1,'on');
for c=1:4
    hp(c)=plot(ax1,NaN,NaN,'o','Color',cols{c},'MarkerFaceColor',cols{c},'MarkerSize',4);
end
axis(ax1,[0 1000 0 1000]); grid(ax1,'on'); box(ax1,'on');
xlabel(ax1,'Width of the domain'); ylabel(ax1,'Height of the domain');
t1=title(ax1,'');

ax2=subplot(2,2,2); hold(ax2,'on');
for c=1:4
    hb(c)=patch(ax2,c+[-0.4;0.4;0.4;-0.4],[0;0;0;0],cols{c},'EdgeColor','none');
    ht(c)=text(ax2,c,0,'0','HorizontalAlignment','center','VerticalAlignment','bottom');
end
set(ax2,'XTick',1:4,'XTickLabel',names,'XLim',[0.4 4.6],'YLim',[0 n+8]); box(ax2,'on');
ylabel(ax2,'Individuals'); t2=title(ax2,'');

ax3=subplot(2,2,[3 4]); hold(ax3,'on');
for c=1:4
    hl(c)=plot(ax3,NaN,NaN,'Color',cols{c},'LineWidth',2);
end
legend(ax3,names,'Location','east');
axis(ax3,[0 240 0 n]); grid(ax3,'on'); box(ax3,'on');
xlabel(ax3,'Time elapsed in hours'); ylabel(ax3,'Population');
t3=title(ax3,'');

f=0;
for s=1:step:size(P,2)
    for c=1:4
        m=P(:,s)==c-1;
        set(hp(c),'XData',X(m,s),'YData',Y(m,s));
        set(hb(c),'YData',[0;0;1;1]*counts(c,s));
        set(ht(c),'Position',[c counts(c,s) 0],'String',num2str(counts(c,s)));
        set(hl(c),'XData',hrs(1:s),'YData',counts(c,1:s));
    end
    lbl=sprintf('Day %d, %02d:%02d  (n = %d)',floor(hrs(s)/24),floor(mod(hrs(s),24)),round(mod(T(s),3600)/60),n);
    set([t1 t2 t3],'String',lbl);
    f=f+1;
    print(fig,sprintf('frames/f%04d.png',f),'-dpng','-r100');
end
