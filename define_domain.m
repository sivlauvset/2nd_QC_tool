function [lats,lons]=define_domain(lon,lat)

% Function called by toolbox_2QC that makes a global map with the cruise
% track plotted
% The domain around the cruise track in which to look for crossover cruises
% can be defined by clicking on the map
%
% Input: lon - longitudes of your cruise track
%        lat - latitudes of your cruis track
%
% Outupt: minimum and maximum longitude and latitude defining the domain
% 
% Siv Lauvset
% last modified 2021-03-24


% solve dateline issues
if mean([min(lon) max(lon)],'omitnan')>100 | mean([min(lon) max(lon)],'omitnan')<-100
    lon1ind=find(lon<0);if ~isempty(lon1ind);lon(lon1ind)=lon(lon1ind)+360;end;clear lon1ind
elseif min(lon)<-100 & max(lon)>100
    lon1ind=find(lon<0);if ~isempty(lon1ind);lon(lon1ind)=lon(lon1ind)+360;end;clear lon1ind
end
    
latmin = min(lat);
latmax = max(lat);
lonmin = min(lon);
lonmax = max(lon);

latcenter = mean([latmin latmax],'omitnan');%+0.005; % For some reason, this keeps the m_grid function from crashing in rare cases
loncenter = mean([lonmin lonmax],'omitnan');%+0.005; % For some reason, this keeps the m_grid function from crashing in rare cases

figure
subplot('position',[0.05 0.05 0.9 0.65]);
m_proj('satellite','lat',latcenter,'lon',loncenter);hold on
m_coast('patch',[.4 .4 .4],'edgecolor',[0.2 0.2 0.2]);hold on
m_grid

[x,y]=m_ll2xy(lon,lat);

plot(x,y,'linestyle','none','marker','.','markersize',10,'color','b')

xpos=-1.9; ypos=1.75;

text(xpos,ypos,'Click on the map to define your domain: ','fontsize',14,'fontweight','bold')
text(xpos,ypos-0.15,'Click twice (2) to mark the top left','fontsize',14,'fontweight','bold')
text(xpos,ypos-0.3,'and bottom right corners of a bounding box.','fontsize',14,'fontweight','bold');
text(xpos,ypos-0.45,'Make sure you add 5\circ in all directions','fontsize',14,'fontweight','bold');
text(xpos,ypos-0.6,'around your cruise track.','fontsize',14,'fontweight','bold');

[X,Y]=ginput(2);
[lons,lats]=m_xy2ll(X,Y);

clear latmin latmax lonmin lonmax latcenter loncenter x y xpos ypos X Y

close
