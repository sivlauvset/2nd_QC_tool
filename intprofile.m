function out=intprofile(xparam,yparam,depth,yint);

% function to interpolate the value of a given parameter through the water column so that two profiles
% can be compared to each other without being sampled at the exact same depth
% Use this function only for one station at a time
% Interpolation with Piecewise Cubic Hermite Interpolating
% 
% For too large distances between data points, NaN will be returned.
% (change this manually in the end of the file.
%
% Use: [out]=intprofile_dens(xparam,yparam,depth,yint);
% INPUT:    xparam = independent parameter
%           yparam = density or depth
%           depth is always needed to make sure that the measurements are not too far apart
%           yint = the interval on where to interpolate
%
% OUTPUT    2*x matrix with the interpolated value (x) in the first column, 
%           and the yparam in the second.
%
% Toste Tanhua 2007.04.25


out=ones(1,2)*NaN;
% Remove missing data
F=find(~isnan(xparam) & ~isnan(yparam) & ~isnan(depth));
xparam=xparam(F); yparam=yparam(F); depth=depth(F);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If there is no data, return all NaN
if isempty(xparam);
   out=ones(1,2)*NaN;
   return
end

% If there are more than one value for a depth (+- 2 m), average the density and
% xvariable

xp1=[]; yp1=[]; de1=[];
udep=unique(depth);
if length(udep)<length(depth),
    for i=1:length(udep),
        F=find(depth==udep(i));
        xp=mean(xparam(F));  yp=mean(yparam(F)); de=udep(i);
        xp1=[xp1;xp]; yp1=[yp1;yp]; de1=[de1;de];
    end
    depth=de1;
    xparam=xp1;
    yparam=yp1;
end

% Sort the data
[yparam,I]=sort(yparam);
xparam=xparam(I); depth=depth(I);
 
% If there are only 2 or fewer datapoints, return all NaN
ll=length(depth);
if ll <= 2;
   out=ones(1,2)*NaN;
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the density interval of your data and make sure that you are not
% extrapolating any data
F=find(yint>=min(yparam) & yint<=max(yparam));
newy=yint(F);

% Make sure that the yparam are monotonic.
for i=1:length(yparam)
    yparam(i)=yparam(i)+(0.0000000001*i); 
end

%%%%%%%%%%
% Make the interpolation using Piecewise Cubic Hermite Interpolating
% Polynomial (PCHIP)
xint = pchip(yparam,xparam,newy);

% If the samples are too far apart, return NaN between the far apart
% samples
dis=[];
for i=1:length(depth)-1,
    d=depth(i+1)-depth(i);
    dis=[dis;d];
end
    
% for i=1:length(dis),
%     if depth(i)<500 & dis(i)>300
%         F=find(newy>yparam(i) & newy<yparam(i+1));
%         xint(F)=NaN;
%     elseif depth(i)>=500 & depth(i)<1500 & dis(i)>600
%         F=find(newy>yparam(i) & newy<yparam(i+1));
%         xint(F)=NaN;
%     elseif depth(i)>=1500 & dis(i)>1100
%         F=find(newy>yparam(i) & newy<yparam(i+1));
%         xint(F)=NaN;
%     end
% end

out=[xint' newy'];
return