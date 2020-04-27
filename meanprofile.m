 function [MPROF]=meanprofile(statnum,ypar,xpar,depth,interval)

% To calculate an average profile from several profiles in an area. The
% profiles are first interpolated  to standard depths (or densities), and
% then these are averaged and the standard deviation is calculated.
% 
% INPUT:  statnum = is the stations to average
%         ypar = is the ordinate (normally depth or density)
%         xpar = is the independent variable
%         depth = is always needed independent of ypar
%         interval = is the interpolation interval, i.e. [0:10:2000]
%         
% OUTPUT: MPROF = a 3*X matrix with [ypar mean standarddeviation]
% 
% Toste Tanhua 2007.04.25

% Interpolate the profiles
xint=[]; newy=[]; 
ustat=unique(statnum);
for i=1:length(ustat),
    F=find(statnum==ustat(i));
    P=intprofile(xpar(F),ypar(F),depth(F),interval);    % get one profile per station
    x=P(:,1); ne=P(:,2); 
    xint=[xint;x]; newy=[newy;ne];
end

F=find(~isnan(xint)); xint=xint(F); newy=newy(F);
% Average the interpolated profiles and
% calculate the standard deviation of the interpolated profiles
ude=unique(newy);
PARmean=[]; PARstd=[];
for i=1:length(ude),
    F=find(newy==ude(i));
    Pm=mean(xint(F));
    Ps=std(xint(F));
    % If less than 3 profiles (ie 3 stations), return NaN for standard deviation
    if length(F)<= 2
        Ps=NaN;
    end
    PARmean=[PARmean;Pm];
    PARstd=[PARstd;Ps];
end
   
MPROF=[ude PARmean PARstd];