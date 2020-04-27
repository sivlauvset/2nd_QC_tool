function [x1,x2,y]=matching(xpar1,xpar2,ypar1,ypar2)
%
% Function to match two data sets with respect to the y-parameter (depth or density). 
% For instance two profiles from the same station that has been interpolated to the same depth, 
% but where max and min depth might be different. 
% 
% INPUT:  xpar1 = the dependent variable of the first station
%         xpar2 = the dependent variable of the second station
%         ypar1 = the independent variable (depth/dens) of the first station
%         ypar2 = the independent variable (depth/dens) of the first station
%         
% OUTPUT: x1 = the dependent variable of the first station
%         x2 = the dependent variable of the second station
%         y = the independent variable (dens/depth)
%         
% Toste Tanhua 2007.04.25

%First make sure that x1 and yq is of the same length.
 profil1=[xpar1 ypar1];
 profil2=[xpar2 ypar2];
 
 y=[];
 for i=1:length(ypar1),
    F=find(ypar2 == ypar1(i));
    yy=ypar2(F);
    y=[y;yy];
 end
 
 x1=[];
 for i=1:length(y),
    F=find(ypar1 == y(i));
    x=xpar1(F);
    x1=[x1;x];
 end
 
 x2=[];
 for i=1:length(y),
    F=find(ypar2 == y(i));
    x=xpar2(F);
    x2=[x2;x];
 end
  match=[y x1 x2];


% [y, iYpar1, iYpar2] = intersect(ypar1, ypar2);
% x1=xpar1(iYpar1);
% x2=xpar2(iYpar2);
