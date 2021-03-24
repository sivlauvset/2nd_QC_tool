function sec_QC(fid,path,ref_path,ref_name,ref_PARAM,input,paramrng,folder,parameter,expocode,ratio,latlim,mindepth,Y,minlat,maxlat,minlon,maxlon)

% Function to perform cross-over analysis of hydrographic data 
% INPUT:      path      Pathway to the directory where the cruise file you
%                       want to perform 2QC on is located and where all results 
%                       and figures will be saved
%
%             ref_path  Pathway to the directory where the reference data
%                       file is saved
%
%             ref_name  Name of the reference data file (currently
%                       GLODAPv2_global.mat), defined in the initialization
%                       file
%
%             ref_PARAM Cell structure with the names of the parameters
%                       you want to use as reference data in the xover analysis.  
%                       NB! These names must match those in the data_PARAM and 
%                       be exactly (case sensitive) the same as the names for
%                       these parameters in the reference data file
%             
%             input    A matrix from the cruise that you want to preform
%                      secondaray QC on. 
%                      Needs to contain the following data, in this order:
%                      [stationno; latitude; longitude; pressure; sigma-4;
%                      paremeterdata] (i.e. the parameter you want to check)
%
%             folder   A string indicating which ocean region we are
%                      operating in
%
%             parameter  A number defining which of the possible parameters
%                        you are doing crossover analysis for
%
%             expocode	The expocode (i.e. name) of the cruise you are testing 
%                       (e.g. 06MS20081031).
%
%             paramrng Max and min of the parameter in question. For figure 
%
%             ratio    Two options: 0 means that bottle salinity should be
%                      used as the main salinity variable for this cruise, 1 means
%                      that ctd salinity should be used for the main salinity
%                      variable on this cruise (since there is bottle
%                      salinity measurements for less than 65% of the data
%
%             latlim   Maximum horizontal distance to do a 2nd QC, default
%                      2 degrees
%
%             mindepth Minimum depth on which to do a comparison, default
%                      1500 m
%             
%             Y        String determining which y-parameter you are using for the
%                      crossover analysis (used for naming folders).  Either density
%                      or pressure
%
%             minlat, maxlat, minlon, maxlon    
%                      Defines the region where your cruise is located, set by define_domain.  
%              
% A figure will be generated.
%
% Calls the following functions:
% - load_global_refdata
% - Xover_2ndQC
% - Xover_subplot
%
% In addition calls the m_map toolbox
%
% Toste Tanhua  2007.04026
% Last modified by Siv Lauvset 2021-03-24
%
%%%%%%

%% Define the variables of the input data, make them global

global stat1a press1a dens1a param1a flag1a stat2 lat2 lon2 press2 dens2 param2 flag2 expo1 expo2 XOVER STAT1 STAT2 param refyr refmnth refdy

param1=input(:,6);  press1=input(:,4); flag1=input(:,7);

%% USER DEFINED PATHWAYS - DEFINE WHERE TO SAVE RESULTS AND FIGURES
if strcmp(folder,expocode)==1
mkdir([path filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29)]);
else
mkdir([path filesep folder filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29)]);
end


if strcmp(folder,expocode)==1

ss=cat(2,[path filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter},'_Xresults',' RESULT');
SS=cat(2,[path filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter},'_XID',' ID');
ss_fig=cat(2,[path filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep,param{parameter}],filesep,expocode,'___',param{parameter},'___Xresults.png');

else

ss=cat(2,[path filesep folder filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter},'_Xresults',' RESULT');
SS=cat(2,[path filesep folder filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter},'_XID',' ID');
ss_fig=cat(2,[path filesep folder filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep,param{parameter}],filesep,expocode,'___',param{parameter},'___Xresults.png');
end


%% FIND ALL DATA DEEPER THAN THE MINIMUM DEPTH
F=find(~isnan(param1) & press1 > mindepth); 
param1=param1(F); press1=press1(F); flag1=flag1(F);
lat1=input(F,2); lon1=input(F,3); stat1=input(F,1);
dens1=input(F,5); expo1=expocode;

if isempty(F),
    disp('there are no data measured deeper than your minimum depth on your cruise');
    fprintf(fid,'there are no data measured deeper than your minimum depth on your cruise\n');
    return
end

%% LOAD THE REFERENCE DATA SET
lookup=cat(2,[ref_path,filesep,'ReferencePositions_LookupTable.mat']);
load(lookup)

if mean([min(lon1) max(lon1)],'omitnan')>100 | mean([min(lon1) max(lon1)],'omitnan')<-100
    lon1ind=find(rlon<0);if ~isempty(lon1ind);rlon(lon1ind)=rlon(lon1ind)+360;end;clear lon1ind
elseif min(lon1)<-100 & max(lon1)>100
    lon1ind=find(rlon<0);if ~isempty(lon1ind);rlon(lon1ind)=rlon(lon1ind)+360;end;clear lon1ind
end

clon=[minlon maxlon maxlon minlon minlon]; clat=[maxlat maxlat minlat minlat maxlat];

in=inpolygon(rlon,rlat,clon,clat);
cruisenos=rcruise(in);

refcruiseno=unique(cruisenos,'stable');
refdata='GLODAPv2.2019';

clear lookup clon clat in rlon rlat cruisenos rcruise

% Loop through the reference data and see if there are any stations that fits the distance criteria
RESULT=[]; ID=[];

% the first loop checks for Xovers within +/- 2deg latitude
for i=1:length(refcruiseno),
    load_global_refdata(ref_path,ref_name,ref_PARAM,refcruiseno(i),parameter,mindepth); 
    
    % loads the data set that has all the reference (i.e. already adjusted) cruises
    expo2
    
    fprintf(fid,'\n Reference cruise: %s\n',expo2);
%     if strmatch('06AQ20070728',expo2)==1
 
    % if no relevant cruises available, keep going
    K=find(lat2>min(lat1)-latlim & lat2<max(lat1)+latlim); 
    if isempty(K),
       disp('there are no crossovers for your cruise');
       fprintf(fid,'there are no crossovers for your cruise\n');
       continue
    end
    
    % make a figure with a map of the reference cruise track and the new cruise track
    posfig(1);

    % solve dateline issues
    if mean([min(lon1) max(lon1)],'omitnan')>100 | mean([min(lon1) max(lon1)],'omitnan')<-100
    lon1ind=find(lon1<0);if ~isempty(lon1ind);lon1(lon1ind)=lon1(lon1ind)+360;end;clear lon1ind
    lon2ind=find(lon2<0);if ~isempty(lon2ind);lon2(lon2ind)=lon2(lon2ind)+360;end;clear lon2ind
    elseif min(lon1)<-100 & max(lon1)>100
    lon1ind=find(lon1<0);if ~isempty(lon1ind);lon1(lon1ind)=lon1(lon1ind)+360;end;clear lon1ind
    lon2ind=find(lon2<0);if ~isempty(lon2ind);lon2(lon2ind)=lon2(lon2ind)+360;end;clear lon2ind
    end
    
    latslons1=[lat1 lon1]; latslons2=[lat2 lon2];
    latslons = [latslons1;latslons2];
	
    latcenter = mean([min(lat1) max(lat1)],'omitnan')+0.002;
    loncenter = mean([min(lon1) max(lon1)],'omitnan')+0.002;
 
    % Draw the first map in the figure. Requires m_map
	axes('position',[.1 .77 .2 .2]);
	m_proj('satellite','lat',latcenter,'lon',loncenter);hold on    
	m_coast('patch',[.4 .4 .4],'edgecolor',[0.2 0.2 0.2]);hold on;
	m_grid('linestyle',':','xticklabels',[],'yticklabels',[])
	hold on
	[sX,sY]=m_ll2xy(latslons1(:,2),latslons1(:,1)); plot(sX,sY,'b.'); % positions in figure for all stations in the new cruise
	[sX,sY]=m_ll2xy(latslons2(:,2),latslons2(:,1)); plot(sX,sY,'r.'); % positions for all stations in the reference cruise

	% Limit the number of reference stations to the ones within +/- 2deg latitude
    stat2=stat2(K); lat2=lat2(K); lon2=lon2(K); param2=param2(K); dens2=dens2(K); press2=press2(K); refyr=refyr(K); refmnth=refmnth(K); refdy=refdy(K); %index K are those stations that are within +/-
    [ustat2,I,J] = unique(stat2); ulon2=lon2(I); ulat2=lat2(I); %sort data for xover according to stations
    [ustat1,I,J] = unique(stat1); ulon1=lon1(I); ulat1=lat1(I);
     
    % THIS SECOND LOOP FINDS XOVERS WITHIN +/- 2DEG DISTANCE (ANY DIRECTION ON A CIRCLE)
    XOVER=[];
    for k=1:length(ustat1),
        for j=1:length(ustat2),
            earth_radius=6378137; % earth radius in meters
            dis_m=m_idist(ulon1(k),ulat1(k),ulon2(j),ulat2(j)); % distance in meters, uses the spheroid wgs84
            dis_rad=dis_m/earth_radius; % distance in radians
            dis=(dis_rad*180)/pi; % distance in degrees
            if dis < latlim,
                xover=[ustat1(k) ustat2(j)];
                XOVER=[XOVER;xover];
            end
        end
    end
    
    % XOVER is the stations that should be compared
    if isempty(XOVER),
       disp('there are no crossovers for your cruise');
       fprintf(fid,'there are no crossovers for your cruise\n');
       pause(1)
       continue
    end
    
    STAT1=unique(XOVER(:,1)); 
    
    % Sort out those stations in your cruise that are involved in crossovers - i.e. only those within +/- 2deg distance of each other
    W=[];
    for istat=1:length(STAT1),
      J=find(stat1==STAT1(istat));
      W=[W ; J(:)];
    end
    stat1a=stat1(W); param1a=param1(W); press1a=press1(W); dens1a=dens1(W); flag1a=flag1(W); lon1a=lon1(W); lat1a=lat1(W);
    
    STAT2=unique(XOVER(:,2)); 
    W=[];
    for istat=1:length(STAT2),
      J=find(stat2==STAT2(istat));
      W=[W ; J(:)];
    end
    stat2=stat2(W); param2=param2(W); press2=press2(W); dens2=dens2(W); refyr=refyr(W); refmnth=refmnth(W); refdy=refdy(W);
    
    
    % Draws the second map in the figure. Requires m_map
    latmin = min(lat1a-5);
	latmax = max(lat1a+5); if latmax>89.99; latmax=89.99; elseif latmin<-89.99; latmin=-89.99; end
	lonmin = min(lon1a-5);
	lonmax = max(lon1a+5);
    
    latdif = abs(latmin-latmax);
	londif = abs(lonmin-lonmax);

    latrng=[latmin-(latdif*0.2) latmax+(latdif*0.2)]; latrng(latrng>89)=89;
	lonrng=[lonmin-(londif*0.2) lonmax+(londif*0.2)];
    
    axes('position',[.35 .7 .27 .27]); 
	m_proj('Mercator','lat',latrng,'lon',lonrng);   
	caxis([-5000 0])
	colormap(bone);
	m_coast('patch',[.4 .4 .4],'edgecolor',[0.2 0.2 0.2]);
	m_grid('linestyle',':','fontsize',6); 
    hold on
    [sX,sY]=m_ll2xy(lon1a,lat1a); plot(sX,sY,'bo'); % plot the new cruise Xover positions 
	[sX,sY]=m_ll2xy(lon2(W),lat2(W)); plot(sX,sY,'ro'); % plot the reference cruise Xover positions
	
    
    
    %% RUN THE 2QC XOVER ANALYSIS
    [diff, stdw] = xover_2ndQC(fid,path,parameter,paramrng,folder,expocode,mindepth,latlim,Y); 
        
    if size(expo2,2)==12
        expo2=cat(2,[expo2,'  ']);
    elseif size(expo2,2)==11
        expo2=cat(2,[expo2,'   ']);
    elseif size(expo2,2)==10
        expo2=cat(2,[expo2,'    ']);
    elseif size(expo2,2)==9
        expo2=cat(2,[expo2,'     ']);
    elseif size(expo2,2)==8
        expo2=cat(2,[expo2,'      ']);
    elseif size(expo2,2)==7
        expo2=cat(2,[expo2,'       ']);
    elseif size(expo2,2)==6
        expo2=cat(2,[expo2,'        ']);
    elseif size(expo2,2)==5
        expo2=cat(2,[expo2,'         ']);
    end
    ID=[ID ; expo2];  
    
    ryr=round(mean(refyr,'omitnan')); refjd=datenum(ryr,min(refmnth),min(refdy))-datenum(ryr-1,12,31);
    rmn=[num2str(0) '.' num2str(refjd)];rmn=str2num(rmn);
    XYR=ryr+rmn; XYR(XYR<1970)=nan;
    RE=[diff stdw ratio XYR];
    RESULT=[RESULT ; RE];

end

%% Save the xovers in a mat file.
eval(['save  ' ss]);
eval(['save  ' SS]);


%% Make a plot of the average xover results.
if strcmp(folder,expocode)==1
ss=cat(2,[path filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter},'_Xresults.mat');
SS=cat(2,[path filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter},'_XID.mat');
ss_tit=cat(2,param{parameter},' Crossovers ',expo1,' vs. ',refdata);
else
ss=cat(2,[path filesep folder filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter},'_Xresults.mat');
SS=cat(2,[path filesep folder filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter},'_XID.mat');
ss_tit=cat(2,param{parameter},' Crossovers ',expo1,' vs. ',refdata);
end

if size(isfinite(RESULT),1)~=0 % cannot make a figure if there are no Xovers

posfig(2);set(gcf,'papertype','a4','paperorientation','landscape','paperunits','centimeters','paperposition',[0 0 21 15]);set(gcf,'Papertype','A4')
Xover_subplot(ss,SS,parameter,10,10)
title(ss_tit,'fontsize',16,'fontweight','bold');

% save the figure
eval(['print -dpng -r300 ' ss_fig]);


end
end
