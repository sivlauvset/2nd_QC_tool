function [diff, stdw] = xover_2ndQC(fid,path,parameter,paramrng,folder,expocode,mindepth,latlim,Y)
% 
% The profiles are interpolated using Piecewise Cubic Hermite Interpolating, 
% and then averaged to a average profile for each cruise. Note that for less than 3 data
% for a depth/density no further analysis will be performed
% You will thus need at least 3 stations per cruise to do a X-over analyis.
%
% This function calculates the difference of each pair of stations and the
% average of those differences is used to compute the Xover difference
% between the two cruises.  A figure is generated for each reference cruise with 
% a valid crossover result.
% 
% INPUT:      path      Pathway to the directory where the cruise file you
%                       want to perform 2QC on is located and where all results 
%                       and figures will be saved
%
%             parameter   A number defining which of the possible
%                         parameters you are running a crossover analysis on
%
%             paramrng   Max and min of the parameter in question. For figure 
%
%             folder   A string indicating which ocean region we are
%                      operating in
%
%             expocode	The expocode (i.e. name) of the cruise you are testing 
%                       (e.g. 06MS20081031).
%
%             paramrng  Max and min of parameter in question. For figure
%
%             mindepth Minimum depth on which to do a comparison, default
%                      1500 m
%
%             latlim   Maximum horizontal distance to do a 2nd QC, default
%                      2 degrees
%
%             Y        String determining which y-parameter you are using for the
%                      crossover analysis (used for naming folders).  Either density
%                      or pressure
%
% OUTPUT:     DIFF     The weighted diffeence between the cruises
%             STDW     The weighted standard deviation of the comparison
%             ratio    The same number that is defined in toolbox_2QC, used
%                      in making figures
%             XYR      The year (mean year of cruise with the year day as a
%                      decimal). Used in making figures
%            
%             A  figure will be generated 
%
% Toste Tanhua  2009.05.27
% Modified by Siv Lauvset 2015-03-12
%

%% DEFINE PARAMETERS AND MAKE THEM GLOBAL
global stat1a press1a dens1a param1a flag1a stat2 press2 dens2 param2 flag2 expo1 expo2 XOVER STAT1 STAT2 param ordin

diff=NaN;  stdw=NaN; xyr=NaN;

%%  =========== USER DEFINED SETTINGS ===========

% DEFINE WHERE YOU WANT TO SAVE THE XOVER PLOTS - there is the option to choose between an windows path and a linux path

if strcmp(folder,expocode)==1
mkdir([path filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter});
plotname=cat(2,[path filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep param{parameter}],filesep,expo1,'___',expo2,'___',param{parameter},'___Xover');

else
mkdir([path filesep folder filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep],param{parameter});
plotname=cat(2,[path filesep folder filesep expocode filesep Y filesep num2str(mindepth) 'm_' num2str(latlim) 'degrees' filesep datestr(now,29) filesep param{parameter}],filesep,expo1,'___',expo2,'___',param{parameter},'___Xover');
end

diffmin=[-12 -10 0.8 0.8 0.8 0.8 -0.015 -0.015 0.8 -0.015 -1 0.8 0.8 0.8]; % columns are the different parameters
diffmax=[12 10 1.2 1.2 1.2 1.2 0.015 0.015 1.2 0.015  1 1.2 1.2 1.2]; % columns are the different parameters
stdmin=[2 2 0.005 0.01 0.01 0.01 0.002 0.002 0.005 0.005 0.005 0.01 0.01 0.01]; % columns are the different parameters
addormul=[1 1 2 2 2 2 1 1 2 1 1 2 2 2]; % columns are the different parameters

% =============== END OF USER DEFINED SETTINGS ========================

%% Do the X-over vs. sigma4
    if ordin(parameter) == 1, % X-overs on density surface
        % Find the deepest station from your cruise and get the density profile
        % interpolated to standard press, and use this as "intdens"
        MD=find(press1a == max(press1a));   DS=find(stat1a == stat1a(MD(1)));
        imax=floor(max(press1a(DS)/10))*10;  imin=ceil(min(press1a(DS)/10))*10;  intd=[imin:20:imax];
        DDD=[min(dens1a) ; dens1a(DS)];   DEP=[mindepth ; press1a(DS)];
        % Make sure this profile is monotonous, i.e. no densities nor press should be there twice.
        if length(unique(DEP)) < length(DEP),
            DEP=unique(DEP); FF=find(unique(DEP));
            DDD=DDD(FF);
        end
        if length(unique(DDD)) < length(DDD),
            DDD=unique(DDD); FF=find(unique(DDD));
            DEP=DEP(FF);
        end
        
        out=intprofile(DDD,DEP,DEP,intd);
        intdens=sort(out(:,1)); 
        imax=(floor(max(intdens*1000))/1000)+0.002;
        imin=(ceil(min(intdens*1000))/1000)-0.02;
        % If the highest density is not in intdens, add it (i.e. if the deepest station is not the densest one).
        if max(intdens)+0.05 < max(dens1a),
            intdens=[intdens; (max(intdens+0.05):0.05:max(dens1a))'];
        end
        % If the lowest density is not in indense, add it
        if min(intdens)-0.05 > min(dens1a),
             intdens=[(min(dens1a):0.05:min(intdens-0.05))' ; intdens];
        end
        
        intdens=intdens';
        if isnan(intdens),
            imax=(floor(max(dens1a*1000))/1000)-0.002; imin=ceil(min(dens1a*1000))/1000;
            intdens=[44:0.01:45.7 45.705:0.0025:45.88 45.881:0.001:46];
            F=find(intdens>imin & intdens<imax); intdens=intdens(F);
        end
        if length(intdens)<2,
           disp('Not enough deep data from your cruise in the x-over area');
           fprintf(fid,'Not enough deep data from your cruise in the x-over area\n');
           diff=NaN; stdw=NaN;
           return
        end    
    end
  
%% Do the X-over vs. press (all parameters in the Nordic Seas, otherwise just salinity)
    if ordin(parameter) == 2
        imax=floor(max(press1a/10))*10;  imin=ceil(min(press1a/10))*10;
        intdens=[imin:20:imax];
        if length(intdens)<2,
           disp('Not enough deep data from your cruise in the x-over area');
           fprintf(fid,'Not enough deep data from your cruise in the x-over area\t');
           diff=NaN; stdw=NaN;
           return
        end    
        dens1a=press1a; dens2=press2;
        imax=imax+100;
    end
    
   %===========================================================
 
%% MAKE FIGURES
  % Plot the profiles vs. density or press
  % Positions [left, bottom, width, height]
  % Plot only those stations that have crossovers
   htop=axes('position',[.1 .07 .4 .55]);
   plot(param1a,dens1a,'.b','markersize',12);  hold on;  plot(param2,dens2,'xr'); hold on
   set(gca,'ydir','rev'); set(gca,'box','off'); set(gca,'xaxislocation','top');
   set(gca,'xlim',[paramrng(1) paramrng(2)]); set(gca,'ylim',[imin imax]);
   if ordin(parameter) == 1
       ylabel('Sigma-4','fontsize',14);
   elseif ordin(parameter) ==2
       ylabel('Pressure  [db]','fontsize',14);
   end
   title(param{parameter},'fontsize',18); 
   
   ustat=unique(stat1a);
   for i=1:length(ustat),
       F=find(stat1a==ustat(i));
       if ~isempty(F)
       P=intprofile(param1a(F),dens1a(F),press1a(F),intdens);    % get one profile per station 
       plot(P(:,1),P(:,2),'b-','linewidth',0.25);
       end
   end
   clear ustat i F P
   ustat=unique(stat2);
   for i=1:length(ustat),
       F=find(stat2==ustat(i));
       if ~isempty(F)
       P=intprofile(param2(F),dens2(F),press2(F),intdens);    % get one profile per station 
       plot(P(:,1),P(:,2),'r-','linewidth',0.25);
       end
   end
   clear ustat i F P
   
   % Add legend
   legend(expo1,expo2);
   set(legend,'box','off'); %set(legend,'position',[0.1 0.1 0.2 0.2]);
   set(legend,'location','best');
   set(legend,'visible','off'); set(legend,'fontsize',12);

      
%% Calculate the offset for each pair of stations within the influence radius
   RELOFF=[];
   for k=1:length(STAT1),
       F=find(stat1a == STAT1(k)); out1=intprofile(param1a(F),dens1a(F),press1a(F),intdens); %get one interpolated profile per station
       USTAT2=XOVER(find(XOVER(:,1) == STAT1(k)),2);  
       
       % calculate the difference between each pair of stations from STAT1(k)
       RO=[];
       for l=1:length(USTAT2),
           M=find(stat2 == USTAT2(l));
           out2=intprofile(param2(M),dens2(M),press2(M),intdens);
           [x1,x2,y]=matching(out1(:,1),out2(:,1),out1(:,2),out2(:,2));

           if addormul(parameter)==1,
              % Calculate the additative offset 
               reloff=[x1-x2 , y];
               RO=[RO;reloff];
           end
           
           if addormul(parameter)==2,
              % Calculate the multplicative offset 
              reloff=[(x1./x2) , y];
              RO=[RO;reloff];
           end
       end
       RELOFF=[RELOFF;RO];
   end
   
   if isempty(RELOFF)
       disp('Not enough data from the reference cruise to do Xover');
       disp('try increasing latlim, or check that there is data for the reference cruise');
       fprintf(fid,'Not enough data from the reference cruise to do Xover\n');
       fprintf(fid,'try increasing latlim, or check that there is data for the reference cruise\n');
       orient tall;  
       eval(['print -dpng -r300  ' plotname]);
       diff=NaN; stdw=NaN;
       return
   end
   Y=RELOFF(:,2);  X=RELOFF(:,1);
      
   % Do a mean difference profile and plot
   PARmean=[]; PARstd=[]; nnn=[];
   ude=unique(Y);
   for i=1:length(ude),
       F=find(Y==ude(i));
       Pm=mean(X(F)); 
       Ps=std(X(F));
       % If less than 5 profiles, return NaN for standard deviation
       if length(F)< 5
          Ps=NaN;
          fprintf(fid,'5 profiles are necessary to calculate standard deviation of the profile difference.  There are only %d\n',length(F));
       end
      PARmean=[PARmean;Pm];
      PARstd=[PARstd;Ps];
      nnn=[nnn;length(F)];
   end

  % Calculate the weighted difference 
  F=find(~isnan(PARstd)); PARmean=PARmean(F); PARstd=PARstd(F); ude=ude(F);
  F=find(PARstd<stdmin(parameter)); PARstd(F)=stdmin(parameter);
  diff=nansum(PARmean./PARstd.^2)/nansum(1./PARstd.^2);
  stdw=nansum(1./PARstd)/nansum(1./PARstd.^2); 
  
  if length(STAT1) < 3  | length(STAT2)<3 | length(PARmean)<1
     disp('Too few data to make a X-over');
     fprintf(fid,'Too few data to make a X-over. Need at least three stations; there are only %d in your cruise and %d in the reference cruise\n', length(STAT1), length(STAT2));
     orient tall;  
     eval(['print -dpng -r300  ' plotname '.png']);
     diff=NaN; stdw=NaN;
     return
  end

  
%% MAKE FIGURES
  % Plot the differences 
  % Positions   [left, bottom, width, height]
  htop=axes('position',[.55 .07 .4 .55]);
  plot(PARmean,ude,'k.'); hold on;
  plot(PARmean+PARstd,ude,'k:'); plot(PARmean-PARstd,ude,'k:');
  set(gca,'ydir','rev'); set(gca,'box','off'); set(gca,'xaxislocation','top');
  set(gca,'ylim',[imin imax]); 
  set(gca,'xlim',[diffmin(parameter) diffmax(parameter)]);
  if addormul(parameter)==1,
     plot([0 0],[0 10000],'k-'); 
  else
     plot([1 1],[0 10000],'k-');
  end
  plot([0 0],[0 10000],'k-');
  plot([diff diff],[min(intdens) max(dens1a)+0.01],'r-','linewidth',2);
  plot([diff-stdw diff-stdw],[min(intdens) max(dens1a)+0.01],'r:','linewidth',2);
  plot([diff+stdw diff+stdw],[min(intdens) max(dens1a)+0.01],'r:','linewidth',2);
  if addormul(parameter) == 1,
      mm=[expo1,' - ', expo2];
  else
      mm=[expo1,' / ', expo2];
  end
  title(mm,'fontsize',16); 
 
        
   % Write the results to the plot
   bla=(imax-imin)/100;  blu=diffmin(parameter)+((diffmax(parameter)-diffmin(parameter))/4);
   if addormul(parameter) == 1,
       text(blu,imin-60*bla,'Additative offset','fontweight','bold');
   else
       text(blu,imin-60*bla,'Multiplicative offset','fontweight','bold');
   end
   
   LL=find(~isnan(param1a)); nn1=length(LL);
   LL=find(~isnan(param2)); nn2=length(LL);
   dis=latlim*60*1.851;
   mm=sprintf('max distance [km] %2.0f',dis); text(blu,imin-55*bla,mm);
   mm=sprintf('weighted offset     %1.5f',diff); text(blu,imin-50*bla,mm);
   mm=sprintf('weighted stddev  %1.5f',stdw); text(blu,imin-45*bla,mm);
   mm=sprintf('# samples C1 (blue)     %2.0f',nn1); text(blu,imin-40*bla,mm);
   mm=sprintf('# samples C2 (red)       %2.0f',nn2); text(blu,imin-35*bla,mm);
   tt1=length(unique(stat1a)); mm=sprintf('# stations C1 (blue)     %2.0f',tt1); text(blu,imin-30*bla,mm);
   tt2=length(unique(stat2)); mm=sprintf('# stations C2 (red)      %2.0f',tt2); text(blu,imin-25*bla,mm);
 
   fprintf(fid,'%s has %2.0f samples while the reference cruise (%s) has %2.0f samples\n',expocode,nn1,expo2,nn2);
   fprintf(fid,'%s has %2.of stations while the reference cruise (%s) has %2.0f stations\n',expocode,tt1,expo2,tt2);
   
   % save figure
   orient tall
   eval(['print -dpng -r300  ' plotname '.png']);
%    eval(['print -dpdf ' plotname '.pdf']);
   